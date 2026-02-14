from sqlalchemy import create_engine, text
engine = create_engine('postgresql://postgres:postgres@localhost:5432/postgres')
with engine.connect() as conn:
    res = conn.execute(text("SELECT email, role FROM utilisateurs"))
    rows = res.fetchall()
    for row in rows:
        print(f"Email: {row[0]}, Role: {row[1]}")
