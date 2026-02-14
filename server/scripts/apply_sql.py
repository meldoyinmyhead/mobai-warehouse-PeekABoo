import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

def apply_sql(filename):
    if not DATABASE_URL:
        print("DATABASE_URL not found in .env")
        return

    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        with open(filename, 'r', encoding='utf-8') as f:
            sql = f.read()
            
        print(f"Applying {filename}...")
        cur.execute(sql)
        conn.commit()
        print("SQL applied successfully!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error applying SQL: {e}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        apply_sql(sys.argv[1])
    else:
        apply_sql("fix_supervisor_rls.sql")
