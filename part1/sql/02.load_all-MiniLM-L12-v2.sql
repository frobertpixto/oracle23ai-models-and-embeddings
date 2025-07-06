DECLARE
    ONNX_MOD_FILE VARCHAR2(100) := 'all_MiniLM_L12_v2.onnx';
    MODNAME VARCHAR2(500);
    LOCATION_URI VARCHAR2(200) := 'https://adwc4pm.objectstorage.us-ashburn-1.oci.customer-oci.com/p/eLddQappgBJ7jNi6Guz9m9LOtYe2u8LWY19GfgU8flFK4N9YgP4kTlrE9Px3pE12/n/adwc4pm/b/OML-Resources/o/';

BEGIN
    DBMS_OUTPUT.PUT_LINE('ONNX model file name in Object Storage is: '||ONNX_MOD_FILE);
--------------------------------------------
-- Define a model name for the loaded model
--------------------------------------------
    SELECT UPPER(REGEXP_SUBSTR(ONNX_MOD_FILE, '[^.]+')) INTO MODNAME from dual;
    DBMS_OUTPUT.PUT_LINE('Model will be loaded and saved with name: '||MODNAME);

-----------------------------------------
-- Load the ONNX model to the database
-----------------------------------------

    DBMS_VECTOR.LOAD_ONNX_MODEL_CLOUD(
        model_name => MODNAME,
        credential => NULL,
        uri => LOCATION_URI || ONNX_MOD_FILE,
        metadata => JSON('{"function" : "embedding", "embeddingOutput" : "embedding" , "input": {"input": ["DATA"]}}')
    );

    DBMS_OUTPUT.PUT_LINE('New model successfully loaded with name: '||MODNAME);
END;