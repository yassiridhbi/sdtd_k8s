# coding: utf-8
import sys
from pyspark import SparkContext
from pyspark.streaming import StreamingContext
from pyspark.streaming.kafka import KafkaUtils
from pyspark.sql import SparkSession
from pyspark.ml.recommendation import ALS
from pyspark.ml.recommendation import ALSModel
from pyspark.sql.functions import isnan


def isnotnan(x):
	y= ~ isnan(x)
	return y

def recommend_movies(number_str):
	spark = SparkSession.builder.appName('recomenderSy').getOrCreate()
	#model_path = sys.argv[1]  # to give the path from where to load the model from the terminal 
	model_path = "/trained_model" # load the model from ./als_model
	model = ALSModel.load(model_path)
	number = int(number_str)
	user= spark.createDataFrame([(number,i) for i in range(0,100)], ["id_user", "id_movie"])
	recommendations = model.transform(user)
	df_result = recommendations.filter(isnotnan(recommendations['prediction'])).orderBy('prediction', ascending=False)
	print("**********************************\n************RESULTAT**************\n**********************************")
	df_result.show()
	print("**********************************\n**********************************\n**********************************")
	best_movies_list = [int(row.id_movie) for row in df_result.collect()]
	spark.stop()	
	return best_movies_list[:20]
	

if __name__ == "__main__":
	sc = SparkContext(appName="Recommendations_Stream")
	ssc = StreamingContext(sc, 1)
	brokers, topic = sys.argv[1:]
	kvs = KafkaUtils.createDirectStream(ssc, [topic],{"metadata.broker.list": brokers})
	lines = kvs.map(lambda x: x[1])
	mots = lines.flatMap(lambda line: line.split(" ")).map(lambda word: recommend_movies(word)).reduce(lambda x: x)
	mots.pprint()
	ssc.start()
	ssc.awaitTermination()
	


#bin/zookeeper-server-start.sh config/zookeeper.properties
#bin/kafka-server-start.sh config/server.properties
#bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test
#sudo spark/bin/spark-submit --packages datastax:spark-cassandra-connector:2.0.1-s_2.11,org.apache.spark:spark-streaming-kafka-0-8_2.11:2.1.0,org.apache.spark:spark-sql-kafka-0-10_2.11:2.1.0 code.py localhost:9092 test
#spark/bin/spark-submit --master local[2]   --conf spark.ui.port=4042 --executor-cores 5 --executor-memory 5g  --packages datastax:spark-cassandra-connector:2.0.1-s_2.11 sdtd.py
#sudo spark-submit --packages datastax:spark-cassandra-connector:2.4.0-s_2.11,org.apache.spark:spark-streaming-kafka-0-8_2.11:2.1.0,org.apache.spark:spark-sql-kafka-0-10_2.11:2.1.0 get_recommandations.py localhost:9092 test
	
