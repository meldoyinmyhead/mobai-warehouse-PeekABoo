from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
import uuid
from datetime import datetime

# Ensure tables exist
models.Base.metadata.create_all(bind=engine)

def get_or_create_product(db: Session, name: str, sku: str):
    p = db.query(models.Produit).filter(models.Produit.sku == sku).first()
    if not p:
        p = models.Produit(
            id_produit=uuid.uuid4(),
            nom_produit=name,
            sku=sku,
            unite_mesure="Unit",
            categorie="Electronics",
            poids_kg=0.5,
            is_gerbable=True,
            colisage_fardeau=1,
            colisage_palette=100
        )
        db.add(p)
        db.commit()
        db.refresh(p)
    return p

def get_or_create_location(db: Session, code: str, x: int, y: int, z: int, warehouse_id: uuid.UUID):
    l = db.query(models.Emplacement).filter(models.Emplacement.code_emplacement == code).first()
    if not l:
        l = models.Emplacement(
            id_emplacement=uuid.uuid4(),
            code_emplacement=code,
            id_entrepot=warehouse_id,
            zone=models.Zone.PICKING,
            type_emplacement=models.EmplacementType.PICKING_RACK,
            niveau=z,
            rangee=y,
            colonne=x,
            actif=True
        )
        db.add(l)
        db.commit()
        db.refresh(l)
    return l

def seed():
    db = SessionLocal()
    try:
        print("Starting seed...")
        
        # 1. Warehouse
        entrepot = db.query(models.Entrepot).first()
        if not entrepot:
            entrepot = models.Entrepot(id_entrepot=uuid.uuid4(), nom_entrepot="Depot Central", code_entrepot="D01")
            db.add(entrepot)
            db.commit()
            db.refresh(entrepot)
        print(f"Using Warehouse: {entrepot.nom_entrepot}")

        # 2. Employee (Hardcoded ID from previous context)
        emp_id = uuid.UUID('bd1252b5-15d2-4051-9290-d70ecad8ee72')
        
        # 3. Products
        p1 = get_or_create_product(db, "Samsung Galaxy S24", "S24-128")
        p2 = get_or_create_product(db, "iPhone 15 Pro Max", "IP15-256")
        p3 = get_or_create_product(db, "Sony WH-1000XM5", "SONY-HP")
        
        # 4. Locations (Matching Frontend Layout Coordinates roughly)
        # Floor 0A
        loc1 = get_or_create_location(db, "A1-05-05", 5, 5, 0, entrepot.id_entrepot)
        loc2 = get_or_create_location(db, "A1-15-05", 15, 5, 0, entrepot.id_entrepot)
        loc3 = get_or_create_location(db, "A1-25-10", 25, 10, 0, entrepot.id_entrepot)
        
        # Floor N1 (z=1)
        loc4 = get_or_create_location(db, "B1-10-10", 10, 10, 1, entrepot.id_entrepot)
        
        # 5. Create Preparation Order
        prep = models.PreparationOrder(
            id=uuid.uuid4(),
            reference=f"PREP-{datetime.now().strftime('%Y%m%d%H%M')}",
            date_prevue=datetime.now(),
            statut=models.OrderStatus.APPROVED,
            generated_by_ai=True
        )
        db.add(prep)
        db.commit()
        db.refresh(prep)
        
        # 6. Create Picking Task 1 (Floor 0A)
        pick1 = models.PickingOrder(
            id=uuid.uuid4(),
            reference="PICK-DEMO-001",
            id_preparation_order=prep.id,
            assigned_to=emp_id,
            statut=models.OrderStatus.PENDING,
            generated_by_ai=True,
            route_distance_m=120.5
        )
        db.add(pick1)
        db.commit()
        db.refresh(pick1)
        
        # Stops for Pick 1
        stops1 = [
            models.PickingOrderStop(id=uuid.uuid4(), id_picking_order=pick1.id, stop_sequence=1, id_produit=p1.id_produit, id_emplacement_source=loc1.id_emplacement, quantite=10, statut=models.TransactionStatus.PENDING),
            models.PickingOrderStop(id=uuid.uuid4(), id_picking_order=pick1.id, stop_sequence=2, id_produit=p2.id_produit, id_emplacement_source=loc2.id_emplacement, quantite=5, statut=models.TransactionStatus.PENDING),
            models.PickingOrderStop(id=uuid.uuid4(), id_picking_order=pick1.id, stop_sequence=3, id_produit=p3.id_produit, id_emplacement_source=loc3.id_emplacement, quantite=2, statut=models.TransactionStatus.PENDING)
        ]
        db.add_all(stops1)
        
        # 7. Create Picking Task 2 (Floor N1)
        pick2 = models.PickingOrder(
            id=uuid.uuid4(),
            reference="PICK-DEMO-N1-002",
            id_preparation_order=prep.id,
            assigned_to=emp_id,
            statut=models.OrderStatus.PENDING,
            generated_by_ai=True,
            route_distance_m=45.0
        )
        db.add(pick2)
        db.commit()
        db.refresh(pick2)
        
        stops2 = [
            models.PickingOrderStop(id=uuid.uuid4(), id_picking_order=pick2.id, stop_sequence=1, id_produit=p1.id_produit, id_emplacement_source=loc4.id_emplacement, quantite=20, statut=models.TransactionStatus.PENDING)
        ]
        db.add_all(stops2)
        
        db.commit()
        print("Successfully seeded 2 picking tasks for employee.")
        
    except Exception as e:
        print(f"Error seeding: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
