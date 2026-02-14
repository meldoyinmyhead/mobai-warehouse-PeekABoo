import csv
import os
import uuid
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models

# Paths to CSV files
PRODUITS_CSV = r"f:\summer\PeekABoo\ai\notebooks\storageOpt\produits.csv"
EMPLACEMENTS_CSV = r"f:\summer\PeekABoo\ai\notebooks\storageOpt\emplacements.csv"

def seed_from_csv():
    db = SessionLocal()
    try:
        # 1. Ensure Warehouse B7 exists
        entrepot = db.query(models.Entrepot).filter(models.Entrepot.code_entrepot == "B7").first()
        if not entrepot:
            print("Creating Warehouse B7...")
            entrepot = models.Entrepot(
                id_entrepot=str(uuid.uuid4()),
                code_entrepot="B7",
                nom_entrepot="Depot B7",
                ville="Dubai",
                actif=True
            )
            db.add(entrepot)
            db.commit()
            db.refresh(entrepot)
        
        id_entrepot = entrepot.id_entrepot
        print(f"Using Warehouse ID: {id_entrepot}")

        # 2. Seed Products
        print("Seeding Products...")
        with open(PRODUITS_CSV, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            # Skip metadata rows (row 2 and 3)
            next(reader) 
            next(reader)
            
            for row in reader:
                sku = row['sku'] or row['id_produit']
                if not sku:
                    continue
                
                # Check if product exists
                existing = db.query(models.Produit).filter(models.Produit.sku == sku).first()
                if not existing:
                    p = models.Produit(
                        id_produit=str(uuid.uuid4()),
                        sku=sku,
                        nom_produit=row['nom_produit'] or f"Produit {sku}",
                        unite_mesure=row['unite_mesure'],
                        categorie=row['categorie'],
                        poids_kg=float(row['Poids(kg)']) if row['Poids(kg)'] else 0.0,
                        is_gerbable=row['Is_Gerbable'].lower() == 'true',
                        colisage_fardeau=int(row['colisage fardeau']) if row['colisage fardeau'] else 0,
                        colisage_palette=int(row['colisage palette']) if row['colisage palette'] else 0
                    )
                    db.add(p)
            db.commit()
            print("Products seeded.")

        # 3. Seed Emplacements
        print("Seeding Emplacements...")
        with open(EMPLACEMENTS_CSV, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            # emplacements.csv doesn't seem to have metadata rows like produits.csv
            
            for row in reader:
                code = row['code_emplacement']
                if not code:
                    continue
                
                # Check if location exists
                existing = db.query(models.Emplacement).filter(models.Emplacement.code_emplacement == code).first()
                if not existing:
                    # Map Zone and Type
                    zone_raw = row['zone']
                    type_raw = row['type_emplacement']
                    
                    zone = models.Zone.STORAGE
                    if 'PCK' in zone_raw or type_raw == 'PICKING':
                        zone = models.Zone.PICKING
                    elif 'RECEPTION' in zone_raw:
                        zone = models.Zone.RECEPTION
                    elif 'EXPEDITION' in zone_raw:
                        zone = models.Zone.EXPEDITION
                    
                    loc_type = models.EmplacementType.STORAGE_SLOT
                    if type_raw == 'PICKING':
                        loc_type = models.EmplacementType.PICKING_RACK
                    
                    # Parse level from code (e.g., 0A-01-01 -> level 0, B07-N1-A1 -> level 1)
                    niveau = 0
                    if '-N' in code:
                        try:
                            # Extract N1, N2, etc.
                            niveau_str = code.split('-N')[1][0]
                            niveau = int(niveau_str)
                        except:
                            niveau = 0
                    elif code.startswith('0'):
                        niveau = 0
                    elif code.startswith('1'):
                        niveau = 1
                    elif code.startswith('2'):
                        niveau = 2
                    elif code.startswith('3'):
                        niveau = 3

                    e = models.Emplacement(
                        id_emplacement=str(uuid.uuid4()),
                        code_emplacement=code,
                        id_entrepot=id_entrepot,
                        zone=zone,
                        type_emplacement=loc_type,
                        niveau=niveau,
                        actif=row['actif'].lower() == 'true' if row['actif'] else True
                    )
                    db.add(e)
            db.commit()
            print("Emplacements seeded.")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_from_csv()
