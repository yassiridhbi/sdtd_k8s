# coding: utf-8
import sys
from pyspark import SparkContext
from pyspark.streaming import StreamingContext
from pyspark.streaming.kafka import KafkaUtils
from pyspark.sql import SparkSession
from pyspark.ml.recommendation import ALS
from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.sql.functions import format_number

trained = False
model = None  # Global variable model will store the model after training
testing_data = None

def process(number_str):
	global model 
	global testing_data
	global trained 
	### Reading DATA from csv file
	if (not trained): 
		spark = SparkSession.builder.appName('recomenderSy').getOrCreate()
		data = spark.read.csv("/ratings.csv", inferSchema=True, header=True)  #data.count() -> 20000263    
		#ratings_df = spark.read.format("org.apache.spark.sql.cassandra").options(table="ratings", keyspace="gym").load()
		data = data.filter(data['userId']<=40).select(['userId', 'movieId', 'rating']) # <=10 just to test on a part of data
		(training_data, testing_data) = data.randomSplit([0.7, 0.3])
		### Training the model
		als = ALS(maxIter=10, regParam=0.01, userCol="userId", itemCol="movieId", ratingCol="rating")
		model = als.fit(training_data)

		predictions = model.transform(testing_data)

		evaluator = RegressionEvaluator(metricName="rmse", labelCol="rating", predictionCol="prediction")
		rmse = evaluator.evaluate(predictions)
		print("Root-mean-square error = " + str(rmse))
		print("**********************************\n**********************************\n**********************************")
		trained = True

	print(number_str)
	number = int(number_str)
	print("number=", number, "de type", type(number))
	user = testing_data.filter(testing_data['userId'] == number).select(['movieId', 'userId'])
	reccomendations = model.transform(user)
	print("**********************************\n************RESULTAT**************\n**********************************")
	reccomendations.orderBy('prediction', ascending=False).show()
	print("**********************************\n**********************************\n**********************************")
	spark.stop()	
	return number_str
	

if __name__ == "__main__":
	sc = SparkContext(appName="Recommendations_Stream")
	ssc = StreamingContext(sc, 1)
	brokers, topic = sys.argv[1:]
	kvs = KafkaUtils.createDirectStream(ssc, [topic],{"metadata.broker.list": brokers})
	lines = kvs.map(lambda x: x[1])
	mots = lines.flatMap(lambda line: line.split(" ")).map(lambda word: process(word)).reduce(lambda x: x)
	mots.pprint()
	ssc.start()
	ssc.awaitTermination()


#bin/zookeeper-server-start.sh config/zookeeper.properties
#bin/kafka-server-start.sh config/server.properties
#bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test
#sudo spark-submit --packages org.apache.spark:spark-streaming-kafka-0-8_2.11:2.1.0,org.apache.spark:spark-sql-kafka-0-10_2.11:2.1.0 kafka_spark_streaming.py localhost:9092 test


