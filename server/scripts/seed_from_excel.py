import pandas as pd
import os
import uuid
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import models

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("DATABASE_URL not found in .env")
    exit(1)

EXCEL_PATH = r"f:\summer\PeekABoo\wms\WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx"
WAREHOUSE_CODE = "B7"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def clean_data(df):
    """Skips the first two metadata rows and resets index."""
    return df.iloc[2:].reset_index(drop=True)

def seed():
    if not os.path.exists(EXCEL_PATH):
        print(f"File not found: {EXCEL_PATH}")
        return

    xl = pd.ExcelFile(EXCEL_PATH)
    print(f"Detected Sheets: {xl.sheet_names}")
    
    def get_sheet_name(target):
        for s in xl.sheet_names:
            if s.strip().upper() == target.upper():
                return s
        return None

    db = SessionLocal()
    try:
        # 0. Ensure Warehouse B7 exists
        entrepot = db.query(models.Entrepot).filter(models.Entrepot.code_entrepot == WAREHOUSE_CODE).first()
        if not entrepot:
            entrepot = models.Entrepot(
                id_entrepot=uuid.uuid4(),
                code_entrepot=WAREHOUSE_CODE,
                nom_entrepot="Depot B7",
                ville="Dubai",
                actif=True
            )
            db.add(entrepot)
            db.commit()
            db.refresh(entrepot)
        
        id_entrepot = entrepot.id_entrepot
        print(f"Using Warehouse: {WAREHOUSE_CODE} ({id_entrepot})")

        # Skip Products/Locations as they are already seeded
        prod_count = db.query(models.Produit).count()
        if prod_count < 100:
            print("Seeding Products...")
            # (Keep product seeding logic here if needed, but for now skipping)
            pass
        else:
            print(f"Products already seeded ({prod_count}). Skipping.")

        loc_count = db.query(models.Emplacement).count()
        if loc_count < 100:
            print("Seeding Locations...")
            pass
        else:
            print(f"Locations already seeded ({loc_count}). Skipping.")

        # 4. Seed Purchase Orders
        s_po = get_sheet_name('cmd_achat_ouvertes_opt')
        if s_po:
            print(f"Seeding Purchase Orders from {s_po}...")
            df_po = clean_data(pd.read_excel(xl, sheet_name=s_po))
            count_orders = 0
            count_lines = 0
            for _, row in df_po.iterrows():
                ref = str(row['id_commande_achat']).strip()
                prod_sku = str(row['id_produit']).strip()
                qty = int(row['quantite_commandee']) if pd.notnull(row['quantite_commandee']) else 0
                
                product = db.query(models.Produit).filter(models.Produit.sku == prod_sku).first()
                if not product:
                    print(f"Creating placeholder product for SKU: {prod_sku}")
                    product = models.Produit(
                        sku=prod_sku,
                        nom_produit=f"Produit {prod_sku}",
                        unite_mesure="pcs",
                        categorie="Achat"
                    )
                    db.add(product)
                    db.flush()

                order = db.query(models.CommandOrder).filter(models.CommandOrder.reference == ref).first()
                if not order:
                    order = models.CommandOrder(
                        id=uuid.uuid4(),
                        reference=ref,
                        statut='PENDING',
                        created_at=pd.to_datetime(row['date_reception_prevue']) if pd.notnull(row['date_reception_prevue']) else None
                    )
                    db.add(order)
                    db.flush()
                    count_orders += 1
                
                # Check for existing line to avoid duplicates
                existing_line = db.query(models.CommandOrderLine).filter(
                    models.CommandOrderLine.id_command_order == order.id,
                    models.CommandOrderLine.id_produit == product.id_produit
                ).first()
                
                if not existing_line:
                    line = models.CommandOrderLine(
                        id=uuid.uuid4(),
                        id_command_order=order.id,
                        id_produit=product.id_produit,
                        quantite_attendue=qty
                    )
                    db.add(line)
                    count_lines += 1
            db.commit()
            print(f"Purchase Orders seeded ({count_orders} orders, {count_lines} lines).")
        else:
            print("Sheet 'cmd_achat_ouvertes_opt' missing.")

    except Exception as e:
        print(f"Error during seeding: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
