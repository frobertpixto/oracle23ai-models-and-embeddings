DECLARE
    ONNX_MOD_FILE VARCHAR2(100) := 'cf_recommender.onnx';
    MODNAME       VARCHAR2(500);
    LOCATION_URI  VARCHAR2(500) := 'https://idsvv7k2bdum.objectstorage.us-ashburn-1.oci.customer-oci.com/p/<your PAR URL without the suffix>/b/ONNX-MODELS/o/';
    METADATA_JSON CLOB;
BEGIN
    -- Define a model name for the loaded model
    SELECT UPPER(REGEXP_SUBSTR(ONNX_MOD_FILE, '[^.]+')) INTO MODNAME;
    DBMS_OUTPUT.PUT_LINE('Model will be loaded and saved with name: ' || MODNAME);

    -- --- THIS IS THE CORRECT METADATA FOR YOUR CF MODEL ---
    METADATA_JSON := '
    {
      "function": "regression",
      "input": {
        "user_input": ["USER_IDX"],
        "movie_input": ["MOVIE_IDX"]
      }
    }';

    -- Drop the model if it already exists, to ensure a clean load
    BEGIN
        DBMS_DATA_MINING.DROP_MODEL(MODNAME);
        DBMS_OUTPUT.PUT_LINE('Dropped existing model with the same name.');
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Ignore error if model does not exist
    END;

    -- ALTERNATIVELY, TO LOAD FROM CLOUD STORAGE (like your original code)
    -- Ensure your database has the correct network ACLs and credentials set up.
    DBMS_VECTOR.LOAD_ONNX_MODEL_CLOUD(
        model_name     => MODNAME,
        credential     => NULL, 
        uri            => LOCATION_URI || ONNX_MOD_FILE,
        metadata       => JSON(METADATA_JSON)
    );

    DBMS_OUTPUT.PUT_LINE('New model successfully loaded with name: ' || MODNAME);
END;