from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# Build connection string: postgresql://postgres.user:password@host:port/postgres
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY") # This is usually the API key, not DB password
DB_PASS = os.getenv("DB_PASS")

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

if not SQLALCHEMY_DATABASE_URL and SUPABASE_URL and DB_PASS:
     import urllib.parse
     project_ref = SUPABASE_URL.split("://")[1].split(".")[0]
     encoded_pass = urllib.parse.quote_plus(DB_PASS)
     SQLALCHEMY_DATABASE_URL = f"postgresql://postgres:{encoded_pass}@db.{project_ref}.supabase.co:5432/postgres"

if not SQLALCHEMY_DATABASE_URL:
    SQLALCHEMY_DATABASE_URL = "sqlite:///./sql_app.db"

if "sqlite" in SQLALCHEMY_DATABASE_URL:
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )
else:
    engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
