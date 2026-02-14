import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY") # service_role key

def debug_auth():
    if not url or not key:
        print("Missing credentials in .env")
        return

    supabase: Client = create_client(url, key)
    
    print("\n--- Listing ALL Users in Supabase Auth ---")
    try:
        # Use admin.list_users() which requires service_role key
        response = supabase.auth.admin.list_users()
        users = response
        if not users:
            print("No users found in Auth.")
        else:
            for user in users:
                print(f"Email: {user.email} | ID: {user.id} | Last Login: {user.last_sign_in_at}")
    except Exception as e:
        print(f"Error fetching auth users: {e}")

if __name__ == "__main__":
    debug_auth()
