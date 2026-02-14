
import models
from database import SessionLocal
import uuid
import datetime

db = SessionLocal()

# 1. Get Employee
user = db.query(models.Utilisateur).filter(models.Utilisateur.email == "employee@mobai.com").first()
if not user:
    print("User employee@mobai.com not found!")
    exit()

print(f"Employee Found: {user.nom_complet} ({user.id_utilisateur})")

# 2. Check Tasks
tasks = db.query(models.PickingOrder).filter(models.PickingOrder.assigned_to == user.id_utilisateur).all()
print(f"Found {len(tasks)} tasks assigned to employee.")

if len(tasks) == 0:
    print("Creating sample tasks...")
    # Create a sample task
    new_task = models.PickingOrder(
        id=uuid.uuid4(),
        reference="PICK-SEED-001",
        assigned_to=user.id_utilisateur,
        statut=models.OrderStatus.PENDING,
        generated_by_ai=True,
        route_distance_m=120.5
    )
    db.add(new_task)
    
    # Add stops
    # Need a product and location
    product = db.query(models.Produit).first()
    location = db.query(models.Emplacement).first()
    
    if product and location:
        stop = models.PickingOrderStop(
            id=uuid.uuid4(),
            id_picking_order=new_task.id,
            stop_sequence=1,
            id_produit=product.id_produit,
            id_emplacement_source=location.id_emplacement,
            id_emplacement_destination=location.id_emplacement,
            quantite=5,
            statut=models.TransactionStatus.PENDING
        )
        db.add(stop)
        print("Sample task created.")
    else:
        print("Error: No products or locations found to create task.")
        
    db.commit()
else:
    for t in tasks:
        print(f" - {t.reference}: {t.statut}")

db.close()
