from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
import uuid

def seed():
    # Ensure tables are created
    models.Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    # 1. Seed Warehouse (Entrepot)
    depot_b7 = db.query(models.Entrepot).filter(models.Entrepot.code_entrepot == "B7").first()
    if not depot_b7:
        depot_b7 = models.Entrepot(
            id_entrepot=uuid.uuid4(),
            code_entrepot="B7",
            nom_entrepot="Depot B7",
            ville="Dubai",
            actif=True
        )
        db.add(depot_b7)
        db.commit()
        db.refresh(depot_b7)
    
    # 3. Seed Products
    p1_existing = db.query(models.Produit).filter(models.Produit.sku == "ABC-001").first()
    if not p1_existing:
        p1 = models.Produit(
            sku="ABC-001",
            nom_produit="Mixer Tap 1/2 inch",
            unite_mesure="pcs",
            categorie="Plumbing",
            poids_kg=1.5,
            is_gerbable=True
        )
        db.add(p1)

    p2_existing = db.query(models.Produit).filter(models.Produit.sku == "ABC-002").first()
    if not p2_existing:
        p2 = models.Produit(
            sku="ABC-002",
            nom_produit="Kitchen Sink Large",
            unite_mesure="pcs",
            categorie="Kitchen",
            poids_kg=12.0,
            is_gerbable=False
        )
        db.add(p2)
    db.commit()

    # 4. Seed Emplacements (Locations)
    e1_existing = db.query(models.Emplacement).filter(models.Emplacement.code_emplacement == "B7-RECEPTION-01").first()
    if not e1_existing:
        e1 = models.Emplacement(
            code_emplacement="B7-RECEPTION-01",
            id_entrepot=depot_b7.id_entrepot,
            zone=models.Zone.RECEPTION,
            type_emplacement=models.EmplacementType.ZONE # RECEPTION handled by zone, type is ZONE
        )
        db.add(e1)

    e2_existing = db.query(models.Emplacement).filter(models.Emplacement.code_emplacement == "B7-N2-C4").first()
    if not e2_existing:
        e2 = models.Emplacement(
            code_emplacement="B7-N2-C4",
            id_entrepot=depot_b7.id_entrepot,
            zone=models.Zone.STORAGE,
            type_emplacement=models.EmplacementType.STORAGE_SLOT,
            niveau=2,
            rangee=3,
            colonne=4
        )
        db.add(e2)

    db.commit()
    print("Database seeded successfully!")
    db.close()

if __name__ == "__main__":
    seed()
