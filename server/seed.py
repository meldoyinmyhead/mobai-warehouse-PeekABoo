from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
import uuid

def seed():
    # Ensure tables are created
    models.Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    # 1. Seed Warehouse (Entrepot)
    depot_b7 = models.Entrepot(
        id_entrepot=str(uuid.uuid4()),
        code_entrepot="B7",
        nom_entrepot="Depot B7",
        ville="Dubai",
        actif=True
    )
    db.add(depot_b7)
    db.commit()
    db.refresh(depot_b7)

    # 2. Seed Users
    admin = models.Utilisateur(
        nom_complet="Admin User",
        email="admin@mobai.com",
        role=models.Role.ADMIN,
        password_hash="admin123", # Placeholder
        actif=True
    )
    supervisor = models.Utilisateur(
        nom_complet="Supervisor User",
        email="supervisor@mobai.com",
        role=models.Role.SUPERVISOR,
        password_hash="supervisor123",
        actif=True
    )
    employee = models.Utilisateur(
        nom_complet="Employee One",
        email="employee@mobai.com",
        role=models.Role.EMPLOYEE,
        password_hash="employee123",
        actif=True
    )
    db.add_all([admin, supervisor, employee])

    # 3. Seed Products
    p1 = models.Produit(
        sku="ABC-001",
        nom_produit="Mixer Tap 1/2 inch",
        unite_mesure="pcs",
        categorie="Plumbing",
        poids_kg=1.5,
        is_gerbable=True
    )
    p2 = models.Produit(
        sku="ABC-002",
        nom_produit="Kitchen Sink Large",
        unite_mesure="pcs",
        categorie="Kitchen",
        poids_kg=12.0,
        is_gerbable=False
    )
    db.add_all([p1, p2])

    # 4. Seed Emplacements (Locations)
    e1 = models.Emplacement(
        code_emplacement="B7-RECEPTION-01",
        id_entrepot=depot_b7.id_entrepot,
        zone=models.Zone.RECEPTION,
        type_emplacement=models.EmplacementType.RECEPTION
    )
    e2 = models.Emplacement(
        code_emplacement="B7-N2-C4",
        id_entrepot=depot_b7.id_entrepot,
        zone=models.Zone.STORAGE,
        type_emplacement=models.EmplacementType.STORAGE_SLOT,
        niveau=2,
        rangee=3,
        colonne=4
    )
    e3 = models.Emplacement(
        code_emplacement="B7-0A-03-05",
        id_entrepot=depot_b7.id_entrepot,
        zone=models.Zone.PICKING,
        type_emplacement=models.EmplacementType.PICKING_RACK,
        niveau=0
    )
    db.add_all([e1, e2, e3])

    db.commit()
    print("Database seeded successfully!")
    db.close()

if __name__ == "__main__":
    seed()
