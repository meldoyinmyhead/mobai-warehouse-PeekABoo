import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

def check_passwords():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        print("\n--- Checking Users & Passwords ---")
        cur.execute("SELECT email, password_hash, role FROM public.utilisateurs")
        rows = cur.fetchall()
        for row in rows:
            print(f"Email: {row[0]} | Hash: {row[1]} | Role: {row[2]}")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    check_passwords()
