import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

def fix_db():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        print("Adding password_hash column...")
        cur.execute("ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS password_hash VARCHAR")
        
        # Set default password for existing users (optional, but good for testing)
        print("Setting default password for existing users...")
        cur.execute("UPDATE utilisateurs SET password_hash = 'admin123' WHERE password_hash IS NULL")
        
        conn.commit()
        print("Database updated successfully.")
        
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    fix_db()
