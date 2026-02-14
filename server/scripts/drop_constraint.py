import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

def drop_constraint():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        print("Dropping foreign key constraint 'utilisateurs_id_utilisateur_fkey'...")
        cur.execute("ALTER TABLE utilisateurs DROP CONSTRAINT IF EXISTS utilisateurs_id_utilisateur_fkey")
        conn.commit()
        print("Constraint dropped successfully.")
        
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    drop_constraint()
