SELECT
  PREDICTION(CF_RECOMMENDER USING
    0 AS "USER_IDX", -- For User 1 in movielens 32M full dataset
    0 AS "MOVIE_IDX" -- For movie 17 (Sense and Sensibility (1995),Drama|Romance)
  ) as predicted_rating;

-- returns 3.9