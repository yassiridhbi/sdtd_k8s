CONSISTENCY QUORUM;

CREATE KEYSPACE movie_lens WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy', 'eu-west-3' : 2 };

USE movie_lens;

CREATE TABLE movies (id_movie varint, title_movie text, category_movie text, PRIMARY KEY(id_movie));

COPY movies(id_movie, title_movie, category_movie) from '/scripts/movies.csv' with HEADER = TRUE;

CREATE TABLE ratings (id_user varint, id_movie varint, rating decimal, timestamp bigint, PRIMARY KEY(id_user, id_movie));

COPY ratings (id_user , id_movie , rating , timestamp) from '/scripts/ratings.csv' with HEADER = TRUE;
