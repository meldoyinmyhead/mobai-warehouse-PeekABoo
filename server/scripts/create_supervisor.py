import hashlib
from database import SessionLocal
from models import Utilisateur, Role
import uuid

def create_supervisor():
    db = SessionLocal()
    try:
        email = "supervisor@mobai.com"
        # Check if already exists
        existing = db.query(Utilisateur).filter(Utilisateur.email == email).first()
        if existing:
            print(f"User {email} already exists. Updating password.")
            db_user = existing
        else:
            db_user = Utilisateur(
                id_utilisateur=uuid.uuid4(),
                nom_complet="Serine Designer",
                email=email,
                role=Role.SUPERVISOR,
                actif=True
            )
            db.add(db_user)
        
        password = "password123"
        hashed_password = hashlib.sha256(password.encode()).hexdigest()
        db_user.password_hash = hashed_password
        
        db.commit()
        print(f"Successfully created/updated supervisor: {email}")
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_supervisor()
