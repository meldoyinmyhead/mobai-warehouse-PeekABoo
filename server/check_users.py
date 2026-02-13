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
        cur.execute("SELECT id_utilisateur, email, role FROM public.utilisateurs")
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
