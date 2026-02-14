import os
import uuid
import random
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import models

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("DATABASE_URL not found in .env")
    exit(1)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def seed_tasks():
    db = SessionLocal()
    try:
        # 1. Get or Create Employee
        email = "employee@mobai.com"
        employee = db.query(models.Utilisateur).filter(models.Utilisateur.email == email).first()
        if not employee:
            print(f"Creating employee: {email}")
            employee = models.Utilisateur(
                id_utilisateur=uuid.uuid4(),
                nom_complet="Employee One",
                email=email,
                role=models.UserRole.EMPLOYEE,
                password_hash="password123", # Weak hash for dev
                actif=True
            )
            db.add(employee)
            db.commit()
            db.refresh(employee)
        
        print(f"Assigning tasks to: {employee.email} ({employee.id_utilisateur})")

        # 2. Create a Preparation Order (needed for Picking)
        prep_order = models.PreparationOrder(
            id=uuid.uuid4(),
            reference=f"PREP-{uuid.uuid4().hex[:8].upper()}",
            date_prevue=datetime.now(),
            statut=models.OrderStatus.APPROVED,
            generated_by_ai=True
        )
        db.add(prep_order)
        db.flush()

        # 3. Create Picking Order
        picking_order = models.PickingOrder(
            id=uuid.uuid4(),
            reference=f"PCK-{uuid.uuid4().hex[:8].upper()}",
            id_preparation_order=prep_order.id,
            assigned_to=employee.id_utilisateur,
            statut=models.OrderStatus.PENDING,
            generated_by_ai=True,
            route_distance_m=150.5
        )
        db.add(picking_order)
        db.flush()

        # 4. Create Stops (need products and locations)
        # Fetch some existing products and locations
        products = db.query(models.Produit).limit(3).all()
        locations = db.query(models.Emplacement).filter(models.Emplacement.zone == 'STORAGE').limit(3).all()
        
        if not products or not locations:
            print("Not enough products or locations to seed tasks. Run seed_from_excel.py first.")
            return

        for i in range(min(len(products), len(locations))):
            stop = models.PickingOrderStop(
                id=uuid.uuid4(),
                id_picking_order=picking_order.id,
                stop_sequence=i + 1,
                id_produit=products[i].id_produit,
                id_emplacement_source=locations[i].id_emplacement,
                id_emplacement_destination=locations[i].id_emplacement, # Mock dest
                quantite=random.randint(1, 10),
                statut=models.TransactionStatus.PENDING
            )
            db.add(stop)
        
        db.commit()
        print(f"Successfully created Picking Order {picking_order.reference} with {min(len(products), len(locations))} stops.")

    except Exception as e:
        print(f"Error seeding tasks: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_tasks()
