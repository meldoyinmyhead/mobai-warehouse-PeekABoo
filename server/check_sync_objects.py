import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

def check_schema_objects():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        print("\n--- Checking 'tasks' table ---")
        cur.execute("SELECT to_regclass('public.tasks')")
        print(f"public.tasks: {cur.fetchone()[0]}")
        
        print("\n--- Checking 'sync_pull' function ---")
        cur.execute("SELECT proname FROM pg_proc WHERE proname = 'sync_pull'")
        res = cur.fetchone()
        print(f"Function 'sync_pull': {'Found' if res else 'Not Found'}")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    check_schema_objects()
