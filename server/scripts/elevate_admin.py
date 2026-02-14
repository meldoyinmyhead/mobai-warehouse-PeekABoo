from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

load_dotenv()
db_url = os.getenv("DATABASE_URL")

engine = create_engine(db_url)
with engine.connect() as conn:
    # Update role to ADMIN for admin@mobai.com
    sql = text("UPDATE utilisateurs SET role = 'ADMIN' WHERE email = 'admin@mobai.com'")
    result = conn.execute(sql)
    conn.commit()
    print(f"Updated {result.rowcount} rows. admin@mobai.com is now an ADMIN.")
