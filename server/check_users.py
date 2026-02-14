import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

def check_db():
    if not DATABASE_URL:
        print("DATABASE_URL not found in .env")
        return

    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        print("\n--- Checking 'utilisateurs' table ---")
        print("\n--- Checking 'utilisateurs' table columns ---")
        cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'utilisateurs'")
        columns = cur.fetchall()
        for col in columns:
            print(f"Column: {col[0]} | Type: {col[1]}")

        print("\n--- Checking 'utilisateurs' data ---")
        cur.execute("SELECT * FROM public.utilisateurs LIMIT 1")
        rows = cur.fetchall()
        
        if not rows:
            print("Table 'utilisateurs' is EMPTY.")
        else:
            print(f"Found {len(rows)} users:")
            for row in rows:
                print(f"ID: {row[0]} | Email: {row[1]} | Role: {row[2]}")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_db()
