WITH
  -- Step 1: Define the 5 movie titles we want to find recommendations for.
  source_movies AS (
    SELECT 'Apocalypse Now (1979)' AS title UNION ALL
    SELECT 'Inception (2010)' AS title UNION ALL
    SELECT 'Arrival (2016)' AS title UNION ALL
    SELECT 'My Life as a Dog (Mitt liv som hund) (1985)' AS title UNION ALL
    SELECT 'Other Guys, The (2010)' AS title
  ),
  
  -- Step 2: Calculate the cosine distance between our 5 source movies
  -- and every other movie in the main 'movies' table.
  similarity_scores AS (
    SELECT
      s.title AS source_title,
      c.title AS candidate_title,
      -- Use the VECTOR_DISTANCE function on our new in-database embeddings
      VECTOR_DISTANCE(s_emb.CF_EMBEDDING, c.CF_EMBEDDING, COSINE) AS distance
    FROM
      source_movies s
      -- Join to get the embedding for our source movies
      JOIN movies s_emb ON s.title = s_emb.title
      -- Cross join to compare with every candidate movie in the catalog
      CROSS JOIN movies c
    WHERE
      s.title != c.title -- Ensure we don't compare a movie to itself
  ),

  -- Step 3: Rank the results for each source movie independently.
  ranked_similarities AS (
    SELECT
      source_title,
      candidate_title,
      distance,
      -- The ROW_NUMBER() analytic function assigns a rank based on the distance.
      -- PARTITION BY source_title means the ranking (1, 2, 3...) restarts for each source movie.
      ROW_NUMBER() OVER (PARTITION BY source_title ORDER BY distance ASC) as rnk
    FROM
      similarity_scores
  )
-- Step 4: Select only the top 5 recommendations (where rank is 1 through 5) for each movie.
SELECT
  source_title,
  candidate_title,
  distance
FROM
  ranked_similarities
WHERE
  rnk <= 5
ORDER BY
  source_title,
  rnk;