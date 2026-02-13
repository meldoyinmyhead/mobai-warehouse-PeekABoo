import os
import psycopg2
from dotenv import load_dotenv
import urllib.parse

load_dotenv()

# Get DB connection info
DATABASE_URL = os.getenv("DATABASE_URL")

# Try to construct it if missing
if not DATABASE_URL:
    supabase_url = os.getenv("SUPABASE_URL")
    db_pass = os.getenv("DB_PASS")
    
    if supabase_url and db_pass:
        # Extract project ref from URL (https://xyz.supabase.co -> xyz)
        project_ref = supabase_url.split("://")[1].split(".")[0]
        
        # URL encode the password to handle special chars like # or ?
        encoded_pass = urllib.parse.quote_plus(db_pass)
        
        DATABASE_URL = f"postgresql://postgres:{encoded_pass}@db.{project_ref}.supabase.co:5432/postgres"
        print(f"Constructed DATABASE_URL for project: {project_ref}")
    else:
        print("Error: DATABASE_URL not found, and could not construct it from SUPABASE_URL/DB_PASS.")
        print("Please check your .env file.")
        exit(1)

# Read the SQL file
schema_path = os.path.join(os.path.dirname(__file__), "schema.sql")
if not os.path.exists(schema_path):
    # Try the artifact location if not found locally
    # But for now assume user put it here or we copied it.
    # Let's try to read it from the artifact path we know about if local fails
    schema_path = r"C:\Users\Admin\.gemini\antigravity\brain\918bf971-3dce-487d-aa5d-75d40e99b4f6\database_schema.sql"

print(f"Reading schema from: {schema_path}")

try:
    with open(schema_path, "r", encoding="utf-8") as f:
        sql_commands = f.read()
except FileNotFoundError:
    print("Error: database_schema.sql not found.")
    exit(1)

# Connect and Execute
try:
    print("Connecting to database...")
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    print("Executing SQL schema...")
    cur.execute(sql_commands)
    
    conn.commit()
    cur.close()
    conn.close()
    print("Success! Database tables created.")
    
except psycopg2.OperationalError as e:
    err_str = str(e)
    if "translate host name" in err_str or "server not known" in err_str:
        print("\n[CRITICAL ERROR] Default Database Connection Failed!")
        print("-----------------------------------------------------")
        print(f"The system tried to connect to: {DATABASE_URL.split('@')[1].split(':')[0]}")
        print("BUT this hostname does not exist. This likely means your project is in a specific region.")
        print("\n[ACTION REQUIRED]")
        print("1. Go to Supabase Dashboard -> Project Settings -> Database.")
        print("2. Scroll down to 'Connection String' -> 'URI'.")
        print("3. Copy the string starting with 'postgresql://'.")
        print("4. Paste it into your .env file as: DATABASE_URL=...")
        print("-----------------------------------------------------\n")
    else:
        print(f"Error executing SQL: {e}")
except Exception as e:
    print(f"Unexpected Error: {e}")
