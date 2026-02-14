import os
from supabase import create_client, Client
from dotenv import load_dotenv
import psycopg2

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")
db_url = os.getenv("DATABASE_URL")

def fix_all_users():
    if not all([url, key, db_url]):
        print("Missing credentials in .env")
        return

    # 1. Get users from Supabase Auth (using service key)
    supabase: Client = create_client(url, key)
    auth_users = supabase.auth.admin.list_users()

    # 2. Connect to Database to update roles
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    print("\n--- Syncing Auth Users to Public Profile Table ---")
    for user in auth_users:
        email = user.email
        uid = user.id
        
        # Check if user exists in public table by email
        cur.execute("SELECT id_utilisateur FROM public.utilisateurs WHERE email = %s", (email,))
        result = cur.fetchone()
        
        if result:
            if result[0] != uid:
                print(f"Updating UUID for {email}: {result[0]} -> {uid}")
                cur.execute("UPDATE public.utilisateurs SET id_utilisateur = %s WHERE email = %s", (uid, email))
            else:
                print(f"User {email} is already in sync.")
        else:
            # If you want to auto-create profiles for all auth users:
            print(f"No profile found for {email}. Use Supabase SQL to create one if needed.")

    conn.commit()
    cur.close()
    conn.close()
    print("\nDone! All profiles updated with correct UUIDs.")

if __name__ == "__main__":
    fix_all_users()
