import requests
import hashlib

email = "admin@mobai.com"
password = "password123"

try:
    r = requests.post("http://localhost:8000/auth/login", json={"email": email, "password": password})
    print(f"Status: {r.status_code}")
    print(r.json())
except Exception as e:
    print(f"Error: {e}")
