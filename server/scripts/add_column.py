from sqlalchemy import text
from database import engine

def add_column():
    with engine.connect() as conn:
        print("Adding order_type to picking_orders...")
        try:
            # Check if column exists first (optional but safe)
            conn.execute(text("ALTER TABLE picking_orders ADD COLUMN IF NOT EXISTS order_type VARCHAR"))
            conn.commit()
            print("Column added or already exists.")
        except Exception as e:
            print(f"Error adding column: {e}")

if __name__ == "__main__":
    add_column()
