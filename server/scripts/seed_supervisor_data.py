import os
import uuid
import random
from datetime import datetime, timedelta
from sqlalchemy import create_engine, text
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

SUPERVISOR_ID = "db6f22b1-8a3c-498b-a9c3-caa6d045bb95"

def seed_supervisor_data():
    db = SessionLocal()
    try:
        # Get some real data for references
        products = db.query(models.Produit).limit(10).all()
        locations = db.query(models.Emplacement).limit(10).all()
        
        if not products or not locations:
            print("No products or locations found to seed flags/orders.")
            return

        print("Seeding Flags (Signalements)...")
        flag_samples = [
            {"desc": "Palette d'eau minérale écrasée.", "type": "DAMAGED", "pri": "HIGH"},
            {"desc": "Incohérence de stock: attendu 10, trouvé 8.", "type": "QUANTITY", "pri": "MEDIUM"},
            {"desc": "Emplacement B7-S1-R1 bloqué par des débris.", "type": "LOCATION", "pri": "LOW"},
            {"desc": "Carton ouvert sans étiquette.", "type": "OTHER", "pri": "MEDIUM"},
            {"desc": "Plusieurs SKU mélangés sur l'emplacement.", "type": "LOCATION", "pri": "HIGH"}
        ]
        
        for sample in flag_samples:
            loc = random.choice(locations)
            db.execute(
                text("INSERT INTO signalements (id, id_emplacement, description, type_signalement, priorite, id_utilisateur_rapporteur, statut, created_at) VALUES (:id, :loc_id, :desc, :type, :pri, :user_id, :status, :created)"),
                {
                    "id": str(uuid.uuid4()),
                    "loc_id": loc.id_emplacement,
                    "desc": sample["desc"],
                    "type": sample["type"],
                    "pri": sample["pri"],
                    "user_id": SUPERVISOR_ID,
                    "status": "PENDING",
                    "created": datetime.now()
                }
            )
        
        print("Seeding Preparation Orders (PENDING_REVIEW)...")
        for i in range(3):
            prep_ref = f"PREP-AI-{random.randint(1000, 9999)}"
            prep_order = models.PreparationOrder(
                id=uuid.uuid4(),
                reference=prep_ref,
                date_prevue=datetime.now().date() + timedelta(days=1),
                generated_by_ai=True,
                ai_model_version="MobAI-v2.1",
                statut=models.OrderStatus.PENDING_REVIEW
            )
            db.add(prep_order)
            db.flush()
            
            # Add some lines
            for j in range(random.randint(2, 4)):
                prod = random.choice(products)
                line = models.PreparationOrderLine(
                    id=uuid.uuid4(),
                    id_preparation_order=prep_order.id,
                    id_produit=prod.id_produit,
                    quantite_ai=random.randint(50, 200),
                    quantite_finale=0 # To be set by supervisor
                )
                db.add(line)

        print("Seeding Picking Orders (PENDING_REVIEW)...")
        for i in range(3):
            pick_ref = f"PICK-AI-{random.randint(1000, 9999)}"
            picking_order = models.PickingOrder(
                id=uuid.uuid4(),
                reference=pick_ref,
                assigned_to=SUPERVISOR_ID, # Assigning to supervisor for testing
                generated_by_ai=True,
                statut=models.OrderStatus.PENDING_REVIEW,
                route_distance_m=float(random.randint(100, 500))
            )
            db.add(picking_order)
            db.flush()
            
            # Add some stops
            for j in range(random.randint(2, 4)):
                prod = random.choice(products)
                loc_src = random.choice(locations)
                loc_dst = random.choice(locations)
                stop = models.PickingOrderStop(
                    id=uuid.uuid4(),
                    id_picking_order=picking_order.id,
                    stop_sequence=j+1,
                    id_produit=prod.id_produit,
                    id_emplacement_source=loc_src.id_emplacement,
                    id_emplacement_destination=loc_dst.id_emplacement,
                    quantite=random.randint(10, 50),
                    statut=models.TransactionStatus.PENDING
                )
                db.add(stop)

        db.commit()
        print("Supervisor sample data seeded successfully!")

    except Exception as e:
        print(f"Error during seeding: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_supervisor_data()
