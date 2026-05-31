import os
import hashlib
import psycopg2
from dotenv import load_dotenv

load_dotenv()

db_url = os.environ.get("DATABASE_URL")

def verify_users():
    if not db_url:
        print("DATABASE_URL not found")
        return

    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        cur.execute("SELECT email, role, password_hash, actif FROM utilisateurs")
        rows = cur.fetchall()
        
        print(f"\n--- Current Users in DB ({len(rows)}) ---")
        for row in rows:
            print(f"Email: {row[0]} | Role: {row[1]} | Hash Start: {row[2][:8]}... | Active: {row[3]}")
        
        input_pass = "password123"
        expected_hash = hashlib.sha256(input_pass.encode()).hexdigest()
        print(f"\nExpected Hash (SHA256): {expected_hash[:8]}...")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    verify_users()
