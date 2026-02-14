from database import SessionLocal
import models
import uuid
import random
from datetime import datetime, date

def seed_tasks():
    db = SessionLocal()
    
    # 1. Find Employee
    user = db.query(models.Utilisateur).filter(models.Utilisateur.email == "employee@mobai.com").first()
    if not user:
        print("Employee not found! Create them first.")
        return

    print(f"Seeding tasks for {user.nom_complet} ({user.id_utilisateur})")

    # 2. Get some products
    products = db.query(models.Produit).limit(10).all()
    if not products:
        print("No products found to seed tasks.")
        return

    # 3. Get some locations
    locations = db.query(models.Emplacement).limit(20).all()
    if not locations:
        print("No locations found.")
        return

    task_types = [
        (models.TransactionType.PICKING, "PCK"),
        (models.TransactionType.TRANSFER, "STR"),
        (models.TransactionType.RECEIPT, "RCP"),
        (models.TransactionType.DELIVERY, "DLV")
    ]

    for t_type, prefix in task_types:
        # Create a PickingOrder (General Task Container)
        order_id = uuid.uuid4()
        ref = f"{prefix}-{random.randint(1000, 9999)}"
        
        new_order = models.PickingOrder(
            id=order_id,
            reference=ref,
            assigned_to=user.id_utilisateur,
            order_type=t_type,
            statut=models.OrderStatus.PENDING,
            generated_by_ai=True,
            route_distance_m=random.uniform(50.0, 500.0),
            created_at=datetime.now()
        )
        db.add(new_order)
        print(f"Created {t_type} Task: {ref}")

        # Add 2-4 stops per task
        num_stops = random.randint(2, 4)
        for i in range(num_stops):
            stop_loc = random.choice(locations)
            stop_prod = random.choice(products)
            
            stop = models.PickingOrderStop(
                id=uuid.uuid4(),
                id_picking_order=order_id,
                stop_sequence=i+1,
                id_produit=stop_prod.id_produit,
                id_emplacement_source=stop_loc.id_emplacement,
                id_emplacement_destination=stop_loc.id_emplacement,
                quantite=random.randint(1, 20),
                statut=models.TransactionStatus.PENDING
            )
            db.add(stop)

    db.commit()
    print("Seeding complete.")
    db.close()

if __name__ == "__main__":
    seed_tasks()
