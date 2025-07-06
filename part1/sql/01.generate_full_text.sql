MERGE INTO movies m
USING (
    WITH
      aggregated_tags AS (
        SELECT
          movieId,
          -- LISTAGG does the aggregation
          LISTAGG(DISTINCT tag, ', ') WITHIN GROUP (ORDER BY tag) AS tag_list
        FROM
          TAGS
        GROUP BY
          movieId
      )
    SELECT
      m.movieId,
      'Title: ' || m.title ||
      '. Genres: ' || REPLACE(m.genres, '|', ', ') ||
      '. Tags: ' || NVL(t.tag_list, '')
      AS final_text
    FROM
      MOVIES m
      LEFT JOIN aggregated_tags t ON m.movieId = t.movieId
) source_query
ON (m.movieId = source_query.movieId)
WHEN MATCHED THEN
  UPDATE SET m.text_for_embedding1 = source_query.final_text;