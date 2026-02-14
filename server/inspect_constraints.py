import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

def inspect_db():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        print("\n--- Checking 'utilisateurs' constraints ---")
        cur.execute("""
            SELECT conname, confrelid::regclass, a.attname
            FROM pg_constraint c
            JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
            WHERE c.conrelid = 'public.utilisateurs'::regclass;
        """)
        constraints = cur.fetchall()
        for c in constraints:
            print(f"Constraint: {c[0]} | References: {c[1]} | Column: {c[2]}")

        print("\n--- Checking 'users' table existence in public ---")
        cur.execute("SELECT to_regclass('public.users')")
        print(f"public.users: {cur.fetchone()[0]}")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    inspect_db()
