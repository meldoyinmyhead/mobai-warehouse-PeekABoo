from dotenv import load_dotenv
import os

load_dotenv()
print("Available keys in .env:")
for key in os.environ:
    if "SUPABASE" in key or "DB" in key or "URL" in key:
        print(f"- {key}")
