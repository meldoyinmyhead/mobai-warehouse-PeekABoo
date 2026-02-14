import os
import psycopg2
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_KEY") # Use the anon key available
db_url = os.environ.get("DATABASE_URL")

if not url or not key or not db_url:
    print("Error: SUPABASE_URL, SUPABASE_KEY, or DATABASE_URL not found in .env")
    exit(1)

supabase: Client = create_client(url, key)

email = "admin@mobai.com"
password = "password123"

def create_admin():
    print(f"Creating admin user: {email}...")
    
    user_id = None
    
    # 1. Sign up/Sign in to get User ID
    try:
        # Try signing in first
        res = supabase.auth.sign_in_with_password({"email": email, "password": password})
        if res.user:
            print("User already exists. Logging in...")
            user_id = res.user.id
            
    except Exception as e:
        # If login fails, try signing up
        print("User not found or login failed. Attempting sign up...")
        try:
            res = supabase.auth.sign_up({
                "email": email,
                "password": password,
            })
            if res.user:
                user_id = res.user.id
        except Exception as signup_error:
            print(f"Sign up failed: {signup_error}")
            return

    if not user_id:
        print("Failed to identify user ID.")
        return

    print(f"Target User ID: {user_id}")

    # 2. Force update role using direct DB connection (Bypassing RLS)
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        # Check if user row exists in public.utilisateurs (Trigger usually creates it, but upsert is safer)
        # We will use ON CONFLICT to ensure we update the role
        sql = """
        INSERT INTO public.utilisateurs (id_utilisateur, email, nom_complet, role, actif)
        VALUES (%s, %s, 'Admin User', 'ADMIN', TRUE)
        ON CONFLICT (id_utilisateur) 
        DO UPDATE SET role = 'ADMIN', actif = TRUE;
        """
        
        cur.execute(sql, (user_id, email))
        conn.commit()
        print(f"Successfully elevated {email} to ADMIN role via direct SQL.")
        
        cur.close()
        conn.close()
        
    except Exception as db_error:
        print(f"Database error: {db_error}")

if __name__ == "__main__":
    create_admin()
