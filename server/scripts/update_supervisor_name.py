import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

db_url = os.environ.get("DATABASE_URL")

if not db_url:
    print("Error: DATABASE_URL not found in .env")
    exit(1)

def update_supervisor_name():
    print("Updating Supervisor name to 'Serine Designer'...")
    
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        # Update name for all supervisors
        sql = """
        UPDATE public.utilisateurs
        SET nom_complet = 'Serine Designer'
        WHERE role = 'SUPERVISOR';
        """
        
        cur.execute(sql)
        row_count = cur.rowcount
        conn.commit()
        
        if row_count > 0:
            print(f"Successfully updated {row_count} supervisor(s) to 'Serine Designer'.")
        else:
            print("No users with role 'SUPERVISOR' found.")
            
            # Fallback: check if we should insert one or update by email if role is missing
            print("Checking if we need to fix roles...")
            # This part is optional but helpful if role mapping is broken
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    update_supervisor_name()
