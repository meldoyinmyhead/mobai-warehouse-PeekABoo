import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

def apply_sql_file(filename):
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        print(f"Applying {filename}...")
        with open(filename, 'r', encoding='utf-8') as f:
            sql = f.read()
            cur.execute(sql)
            conn.commit()
            print(f"Successfully applied {filename}")
    except Exception as e:
        print(f"Error applying {filename}: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    # Pointing to the artifacts directory where these files are stored
    artifacts_dir = r"C:\Users\Admin\.gemini\antigravity\brain\918bf971-3dce-487d-aa5d-75d40e99b4f6"
    apply_sql_file(os.path.join(artifacts_dir, "database_schema.sql"))
    apply_sql_file(os.path.join(artifacts_dir, "sync_functions.sql"))
