import sqlite3
import uuid

db_path = "F:/summer/PeekABoo/server/sql_app.db"

def check_db():
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("--- Stock Summary ---")
    cursor.execute("SELECT id_emplacement, id_produit, quantite FROM stock_par_emplacement")
    stocks = cursor.fetchall()
    for s in stocks:
        print(f"Location: {s[0]}, Product: {s[1]}, Qty: {s[2]}")
        
    print("\n--- Users ---")
    cursor.execute("SELECT id_utilisateur, email, role FROM utilisateurs")
    users = cursor.fetchall()
    for u in users:
        print(f"User: {u[1]} (ID: {u[0]}), Role: {u[2]}")
        
    print("\n--- Pending Picking Orders ---")
    cursor.execute("SELECT id, reference, statut FROM picking_orders WHERE statut != 'COMPLETED'")
    orders = cursor.fetchall()
    for o in orders:
        print(f"Order: {o[1]} (ID: {o[0]}), Status: {o[2]}")
        
        # Check stops for this order
        cursor.execute("SELECT id_emplacement_source, id_produit, quantite, statut FROM picking_order_stops WHERE id_picking_order = ?", (o[0],))
        stops = cursor.fetchall()
        for s in stops:
            print(f"  Stop: Source {s[0]}, Product {s[1]}, Qty {s[2]}, Status {s[3]}")
    
    conn.close()

if __name__ == "__main__":
    check_db()
