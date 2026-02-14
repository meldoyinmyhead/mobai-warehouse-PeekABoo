from database import SessionLocal
import models
import json

def inspect_db():
    db = SessionLocal()
    
    # 1. Find User
    user = db.query(models.Utilisateur).filter(models.Utilisateur.email == "employee@mobai.com").first()
    if not user:
        print("User employee@mobai.com not found.")
    else:
        print(f"User found: {user.nom_complet} (ID: {user.id_utilisateur})")
        
        # 2. Check Picking Orders
        picking_orders = db.query(models.PickingOrder).filter(models.PickingOrder.assigned_to == user.id_utilisateur).all()
        print(f"Picking Orders: {len(picking_orders)}")
        for po in picking_orders:
            print(f" - {po.reference}: {po.statut}")
            
        # 3. Check Command Orders (Receipt?)
        # assigned_to is not in CommandOrder, but maybe in picking or others
        
        # 4. Check Transactions
        transactions = db.query(models.Transaction).filter(models.Transaction.created_by == user.id_utilisateur).all()
        print(f"Transactions: {len(transactions)}")
        
    db.close()

if __name__ == "__main__":
    inspect_db()
