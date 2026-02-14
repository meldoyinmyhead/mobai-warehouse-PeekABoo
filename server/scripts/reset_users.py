import models
from database import SessionLocal, engine
from sqlalchemy import text
import uuid

def reset_users():
    db = SessionLocal()
    try:
        print("Resetting Users Table...")
        
        # 1. Truncate tables with CASCADE to handle foreign keys
        # We need to clear tables that reference utilisateurs first or use CASCADE
        db.execute(text("TRUNCATE TABLE utilisateurs, ai_overrides, audit_log, picking_orders, preparation_orders, command_orders, transactions CASCADE;"))
        db.commit()
        print("Tables truncated.")
        
        import hashlib
        
        # Hash passwords before storing
        password_plain = "password123"
        password_hashed = hashlib.sha256(password_plain.encode()).hexdigest()
        
        # 2. Create Admin User (Supervisor)
        admin_id = uuid.uuid4()
        admin = models.Utilisateur(
            id_utilisateur=admin_id,
            nom_complet="Serine Designer",
            email="admin@mobai.com",
            role=models.Role.SUPERVISOR,
            password_hash=password_hashed,
            actif=True
        )
        db.add(admin)
        
        # 3. Create Employee User
        employee_id = uuid.uuid4()
        employee = models.Utilisateur(
            id_utilisateur=employee_id,
            nom_complet="John Helper",
            email="employee@mobai.com",
            role=models.Role.EMPLOYEE,
            password_hash=password_hashed,
            actif=True,
            created_by=admin_id
        )
        db.add(employee)
        
        db.commit()
        print("Users re-created successfully!")
        print(f"Admin: admin@mobai.com / password123 (ID: {admin_id})")
        print(f"Employee: employee@mobai.com / password123 (ID: {employee_id})")
        
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    # Ensure tables exist (just in case)
    models.Base.metadata.create_all(bind=engine)
    reset_users()
