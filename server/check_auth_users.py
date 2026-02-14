import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

def check_auth_users():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        print("\n--- Checking 'auth.users' ---")
        cur.execute("SELECT id, email, created_at FROM auth.users")
        rows = cur.fetchall()
        for row in rows:
            print(f"ID: {row[0]} | Email: {row[1]}")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    check_auth_users()
