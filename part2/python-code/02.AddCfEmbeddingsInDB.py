from dotenv import load_dotenv
load_dotenv() # This loads the variables from .env into the environment

import pandas as pd
import oracledb
import os

from platform import python_version
print(f'Python: {python_version()}')

from tf_keras.models import Model, load_model

import tensorflow as tf
print(f'TensorFlow: {tf.__version__}')

BASEDIR        = ".."
MODEL_DIR      = os.path.join(BASEDIR, "saved_models")
model_filename = os.path.join(MODEL_DIR, "collaboration_filter.01.keras")

movielens_dataset = "full" # "full" #"small"
# --- Part 1: Load the Saved Model and Extract Embeddings ---

print("Loading the trained Keras model...")
# Load the model saved by ModelCheckpoint
saved_model = load_model(model_filename)
print("Model loaded successfully.")

# Get the learned movie embedding matrix from the model
movie_embedding_matrix = saved_model.get_layer('movie_embedding').get_weights()[0]
print(f"Extracted embedding matrix with shape: {movie_embedding_matrix.shape}")

# --- Part 2: Prepare the Data for Database Update ---
# We need to map the original movieIds to their new embedding vectors.

# First, we must recreate the exact same movieId-to-index mapping used during training.
df_ratings = pd.read_csv(f'../../movielens_data/{movielens_dataset}/ratings.csv')  # Use the same ratings file (small or full)
unique_movie_ids = df_ratings['movieId'].unique()
movie_map = {id: i for i, id in enumerate(unique_movie_ids)}
# Create the reverse map we need: from index back to original movieId
idx_to_movieid_map = {i: id for id, i in movie_map.items()}

# Now, create a list of tuples: (embedding_vector, original_movieId)
# This is the data we will use for our bulk UPDATE statement.
data_to_insert = []
for idx, vector in enumerate(movie_embedding_matrix):
    original_movie_id = idx_to_movieid_map.get(idx)
    if original_movie_id is not None:
        # The vector must be a list of floats for the driver
        data_to_insert.append((vector.tolist(), int(original_movie_id)))

print(f"Prepared {len(data_to_insert)} movie embeddings for database Insert.")

# --- Part 3: Connect and Update the Oracle Database ---

# Database connection details from .env or environment
# Sets up database connection details using the wallet
db_user = os.environ.get("DB_USER", "BAD_DB_USER") # e.g., 'ADMIN'
db_password = os.environ.get("DB_PASSWORD", "BAD_DB_PASSWORD")

# --- Key parameters for wallet connection ---
# The path to the directory where you UNZIPPED the wallet
wallet_path = os.environ.get("WALLET_PATH", "BAD_WALLET_PATH")
wallet_pw = os.environ.get("WALLET_PASSWORD", "BAD_WALLET_PASSWORD")

# The service name from your tnsnames.ora file
db_dsn = os.environ.get("DB_DSN", "BAD_DB_DSN")

connection = None
try:
    print("Connecting to the Oracle Autonomous Database...")
    connection = oracledb.connect(
        user=db_user,
        password=db_password,
        dsn=db_dsn,
        config_dir=wallet_path,  # Tells oracledb where to find tnsnames.ora and other wallet files
        wallet_location=wallet_path,
        wallet_password=wallet_pw
    )
    print("Connection successful.")

    with connection.cursor() as cursor:
        # Define the UPDATE statement
        # sql_insert_statement = "INSERT INTO movies (movieid,  cf_embedding) VALUES (:1, :2)"
        sql_update_statement = "UPDATE MOVIES SET cf_embedding = :1 WHERE movieid = :2"

        # We must tell the driver the type of the first bind variable is VECTOR
        cursor.setinputsizes(oracledb.DB_TYPE_VECTOR, None)

        print("Executing bulk UPDATE with executemany()...")
        # This sends all the updates in an efficient batch
        cursor.executemany(sql_update_statement, data_to_insert, batcherrors=True)

        print(f"Update command sent for {cursor.rowcount} rows.")

        # Commit the transaction
        connection.commit()
        print("Database transaction committed successfully.")

except oracledb.Error as e:
    print(f"Database error occurred: {e}")
    # if batcherrors=True, you can check cursor.getbatcherrors()
    # for i, error in enumerate(cursor.getbatcherrors()):
    #     print("Error", i, "at row offset", error.offset, ":", error.message)
finally:
    if connection:
        connection.close()
        print("Database connection closed.")