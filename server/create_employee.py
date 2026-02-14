from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
import uuid

def create_employee():
    db = SessionLocal()
    
    email = "employee@mobai.com"
    password = "password123"
    
    # Check if exists
    existing_user = db.query(models.Utilisateur).filter(models.Utilisateur.email == email).first()
    if existing_user:
        print(f"User {email} already exists with ID: {existing_user.id_utilisateur}")
        # Update password just in case
        existing_user.password_hash = password
        db.commit()
        print("Updated password.")
    else:
        # Create User
        new_user = models.Utilisateur(
            id_utilisateur=uuid.uuid4(),
            nom_complet="John Employee",
            email=email,
            role=models.Role.EMPLOYEE,
            password_hash=password, # Plain text as per main.py logic
            actif=True
        )
        
        db.add(new_user)
        db.commit()
        print(f"Created user: {email} with password: {password}")
    
    db.close()

if __name__ == "__main__":
    create_employee()
