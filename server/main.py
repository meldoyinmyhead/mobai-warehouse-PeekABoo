from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas
from database import engine, SessionLocal, Base

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="MobAI WMS Backend", version="1.0.0")

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 0. Authentication
@app.post("/auth/login", response_model=schemas.TokenResponse)
def login(request: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.Utilisateur).filter(models.Utilisateur.email == request.email).first()
    if not user or user.password_hash != request.password: # Simplified for now
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    
    if not user.actif:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated",
        )

    return {
        "access_token": f"mock_token_{user.id_utilisateur}",
        "token_type": "bearer",
        "user": user
    }

# 0.1 Auditing & Logging
@app.post("/audit/log", response_model=schemas.AuditLog)
def create_audit_log(log: schemas.AuditLogCreate, db: Session = Depends(get_db)):
    db_log = models.AuditLog(
        id_utilisateur=log.id_utilisateur,
        action=log.action,
        entity_type=log.entity_type,
        entity_id=log.entity_id,
        payload=log.payload
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

@app.get("/")
def read_root():
    return {
        "message": "MobAI WMS Backend is running",
        "system": "MobAI",
        "warehouse": "Depot B7"
    }

# 1. User Management
@app.post("/users/", response_model=schemas.Utilisateur, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UtilisateurCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.Utilisateur).filter(models.Utilisateur.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # In a real app, hash the password
    new_user = models.Utilisateur(
        nom_complet=user.nom_complet,
        email=user.email,
        role=user.role,
        password_hash=user.password, # Placeholder
        actif=user.actif
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.get("/users/", response_model=List[schemas.Utilisateur])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(models.Utilisateur).offset(skip).limit(limit).all()
    return users

# 2. Warehouse Infrastructure
@app.get("/entrepots/", response_model=List[schemas.Entrepot])
def list_entrepots(db: Session = Depends(get_db)):
    return db.query(models.Entrepot).all()

@app.get("/emplacements/", response_model=List[schemas.Emplacement])
def list_emplacements(zone: str = None, db: Session = Depends(get_db)):
    query = db.query(models.Emplacement)
    if zone:
        query = query.filter(models.Emplacement.zone == zone)
    return query.all()

# 3. Product Catalog
@app.get("/produits/", response_model=List[schemas.Produit])
def list_produits(db: Session = Depends(get_db)):
    return db.query(models.Produit).all()

# 4. Stock & Inventory
@app.get("/stock/", response_model=List[schemas.StockParEmplacement])
def get_inventory(db: Session = Depends(get_db)):
    return db.query(models.StockParEmplacement).all()
