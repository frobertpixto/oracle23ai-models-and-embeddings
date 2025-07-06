DECLARE
    -- Define the size of each batch
    CHUNK_SIZE NUMBER := 1000;

    -- Define a collection type to hold a batch of movie IDs
    TYPE movie_id_list IS TABLE OF movies.movieId%TYPE;

    -- Declare a variable of our collection type
    l_movie_ids movie_id_list;

    -- Define a cursor to select all movies that still need an embedding
    CURSOR c_movies_to_process IS
        SELECT movieId
        FROM movies
        WHERE movie_embedding1 IS NULL;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting batch embedding generation...');
    OPEN c_movies_to_process;
    LOOP
        -- Fetch a "chunk" of movie IDs into our collection variable
        FETCH c_movies_to_process
        BULK COLLECT INTO l_movie_ids
        LIMIT CHUNK_SIZE;

        -- Exit the loop if there are no more rows to process
        EXIT WHEN l_movie_ids.COUNT = 0;

        DBMS_OUTPUT.PUT_LINE('Processing ' || l_movie_ids.COUNT || ' movies...');

        -- FORALL is faster than a standard loop.
        FORALL i IN 1 .. l_movie_ids.COUNT
            UPDATE movies
            SET movie_embedding1 = VECTOR_EMBEDDING(
                                     ALL_MINILM_L12_V2 -- Use the name you gave the ONNX model
                                     USING text_for_embedding1 AS data
                                   )
            WHERE movieId = l_movie_ids(i);

        -- Commit the changes for this chunk to the database
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('   ... Chunk committed.');

    END LOOP;
    CLOSE c_movies_to_process;
    DBMS_OUTPUT.PUT_LINE('Batch embedding generation complete.');

EXCEPTION
    WHEN OTHERS THEN
        -- Close the cursor if an error occurs
        IF c_movies_to_process%ISOPEN THEN
            CLOSE c_movies_to_process;
        END IF;
        -- Re-raise the exception so you can see the error message
        RAISE;
END;