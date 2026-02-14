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
    import hashlib
    
    # Hash the incoming password to compare with stored hash
    hashed_input = hashlib.sha256(request.password.encode()).hexdigest()
    
    if not user or user.password_hash != hashed_input:
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
        "access_token": f"mock_token_{str(user.id_utilisateur)}",
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

@app.put("/users/{user_id}", response_model=schemas.Utilisateur)
def update_user(user_id: str, user_update: schemas.UtilisateurBase, db: Session = Depends(get_db)):
    import uuid
    db_user = db.query(models.Utilisateur).filter(models.Utilisateur.id_utilisateur == uuid.UUID(user_id)).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    for key, value in user_update.dict().items():
        setattr(db_user, key, value)
    
    db.commit()
    db.refresh(db_user)
    return db_user

@app.delete("/users/{user_id}")
def delete_user(user_id: str, db: Session = Depends(get_db)):
    import uuid
    db_user = db.query(models.Utilisateur).filter(models.Utilisateur.id_utilisateur == uuid.UUID(user_id)).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(db_user)
    db.commit()
    return {"status": "success", "message": "User deleted"}

# 2. Warehouse Infrastructure
@app.get("/entrepots/", response_model=List[schemas.Entrepot])
def list_entrepots(db: Session = Depends(get_db)):
    return db.query(models.Entrepot).all()

@app.post("/entrepots/", response_model=schemas.Entrepot, status_code=status.HTTP_201_CREATED)
def create_entrepot(entrepot: schemas.EntrepotCreate, db: Session = Depends(get_db)):
    db_entrepot = models.Entrepot(**entrepot.dict())
    db.add(db_entrepot)
    db.commit()
    db.refresh(db_entrepot)
    return db_entrepot

@app.put("/entrepots/{entrepot_id}", response_model=schemas.Entrepot)
def update_entrepot(entrepot_id: str, entrepot_update: schemas.EntrepotUpdate, db: Session = Depends(get_db)):
    import uuid
    db_entrepot = db.query(models.Entrepot).filter(models.Entrepot.id_entrepot == uuid.UUID(entrepot_id)).first()
    if not db_entrepot:
        raise HTTPException(status_code=404, detail="Warehouse not found")
    
    update_data = entrepot_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_entrepot, key, value)
    
    db.commit()
    db.refresh(db_entrepot)
    return db_entrepot

@app.delete("/entrepots/{entrepot_id}")
def delete_entrepot(entrepot_id: str, db: Session = Depends(get_db)):
    import uuid
    db_entrepot = db.query(models.Entrepot).filter(models.Entrepot.id_entrepot == uuid.UUID(entrepot_id)).first()
    if not db_entrepot:
        raise HTTPException(status_code=404, detail="Warehouse not found")
    
    db.delete(db_entrepot)
    db.commit()
    return {"status": "success", "message": "Warehouse deleted"}

# --- Etage (Floor) Management ---

@app.post("/entrepots/{entrepot_id}/etages", response_model=schemas.Etage)
def create_etage(entrepot_id: str, etage: schemas.EtageCreate, db: Session = Depends(get_db)):
    import uuid
    # Ensure entrepot matches
    if str(etage.id_entrepot) != entrepot_id:
         raise HTTPException(status_code=400, detail="Entrepot ID mismatch")
    
    db_etage = models.Etage(**etage.dict())
    db.add(db_etage)
    db.commit()
    db.refresh(db_etage)
    return db_etage

@app.delete("/etages/{etage_id}")
def delete_etage(etage_id: str, db: Session = Depends(get_db)):
    import uuid
    db_etage = db.query(models.Etage).filter(models.Etage.id == uuid.UUID(etage_id)).first()
    if not db_etage:
        raise HTTPException(status_code=404, detail="Floor not found")
    
    db.delete(db_etage)
    db.commit()
    return {"status": "success", "message": "Floor deleted"}

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

# 5. AI Service Endpoints
@app.get("/ai/available-slots", response_model=List[schemas.Emplacement])
def get_available_slots(zone: str = None, db: Session = Depends(get_db)):
    """
    Returns a list of empty slots (where stock quantity is 0 or NULL).
    Used by the AI Agent to determine where to store incoming items.
    """
    # Find all occupied slots (quantity > 0)
    occupied_slots = db.query(models.StockParEmplacement.id_emplacement).filter(models.StockParEmplacement.quantite > 0).subquery()
    
    # Select emplacements NOT IN the occupied list
    query = db.query(models.Emplacement).filter(models.Emplacement.id_emplacement.notin_(occupied_slots))
    
    if zone:
        query = query.filter(models.Emplacement.zone == zone)
    
    return query.all()

@app.get("/ai/inventory", response_model=List[schemas.StockParEmplacement])
def get_ai_inventory(db: Session = Depends(get_db)):
    """
    Returns current inventory levels for AI forecasting and picking optimization.
    """
    return db.query(models.StockParEmplacement).filter(models.StockParEmplacement.quantite > 0).all()

# 1. Forecasting Service
@app.post("/ai/forecast", response_model=List[schemas.PreparationOrder])
def generate_forecast(request: schemas.ForecastRequest, db: Session = Depends(get_db)):
    """
    Generates a Preparation Order based on historical demand.
    For MVP: Simply duplicates the last order or selects random products.
    """
    # 1. Check if forecast already exists for this date
    existing = db.query(models.PreparationOrder).filter(models.PreparationOrder.date_prevue == request.target_date).first()
    if existing:
        return [existing]
        
    # 2. Logic: Create a new Preparation Order
    import uuid
    from datetime import datetime
    
    new_order = models.PreparationOrder(
        id=uuid.uuid4(),
        reference=f"PREP-{request.target_date.strftime('%Y%m%d')}",
        date_prevue=request.target_date,
        statut=models.OrderStatus.PENDING_REVIEW,
        generated_by_ai=True,
        ai_model_version="v1.0-mvp"
    )
    db.add(new_order)
    db.flush() # flush to get ID
    
    # 3. Add random products for demo (Real logic would query models.HistoriqueDemande)
    # Get first 5 products
    products = db.query(models.Produit).limit(5).all()
    for p in products:
        line = models.PreparationOrderLine(
            id=uuid.uuid4(),
            id_preparation_order=new_order.id,
            id_produit=p.id_produit,
            quantite_ai=10, # Mock prediction
            quantite_finale=10
        )
        db.add(line)
    
    db.commit()
    db.refresh(new_order)
    return [new_order]

# 2. Storage Assignment Service
@app.post("/ai/prescribe-storage", response_model=List[schemas.StorageAssignment])
def prescribe_storage(request: schemas.StorageAssignmentRequest, db: Session = Depends(get_db)):
    """
    Assigns a storage slot for received items.
    Logic: Finds the first empty slot in Zone STORAGE.
    """
    assignments = []
    
    # Get all empty slots
    occupied_subquery = db.query(models.StockParEmplacement.id_emplacement).filter(models.StockParEmplacement.quantite > 0).subquery()
    available_slots = db.query(models.Emplacement).filter(
        models.Emplacement.zone == models.Zone.STORAGE,
        models.Emplacement.id_emplacement.notin_(occupied_subquery)
    ).all()
    
    slot_index = 0
    
    for item in request.received_items:
        if slot_index < len(available_slots):
            target_slot = available_slots[slot_index]
            slot_index += 1
            
            assignments.append(schemas.StorageAssignment(
                id_produit=item.id_produit,
                target_location_code=target_slot.code_emplacement,
                reasoning="Nearest available empty slot based on FIFO logic."
            ))
        else:
             assignments.append(schemas.StorageAssignment(
                id_produit=item.id_produit,
                target_location_code="OVERFLOW",
                reasoning="No empty slots available in Storage Zone."
            ))
            
    return assignments

# 3. Picking Optimization Service
@app.post("/ai/optimize-picking", response_model=schemas.OptimizedRoute)
def optimize_picking(request: schemas.PickingOptimizationRequest, db: Session = Depends(get_db)):
    """
    Generates an optimized picking route.
    Logic: Sorts items by location code (simple TSP heuristic).
    """
    # 1. Get lines for this preparation order
    lines = db.query(models.PreparationOrderLine).filter(
        models.PreparationOrderLine.id_preparation_order == request.id_preparation_order
    ).all()
    
    stops = []
    sequence = 1
    
    for line in lines:
        # Find where this product is stored
        stock = db.query(models.StockParEmplacement, models.Emplacement).join(models.Emplacement).filter(
            models.StockParEmplacement.id_produit == line.id_produit,
            models.StockParEmplacement.quantite > 0
        ).first()
        
        if stock:
            loc = stock.Emplacement
            prod = db.query(models.Produit).get(line.id_produit)
            stops.append(schemas.PickingStop(
                sequence=sequence, # Temporary, will sort later
                location_code=loc.code_emplacement,
                product_name=prod.nom_produit,
                quantity=line.quantite_finale,
                niveau=loc.niveau,
                rangee=loc.rangee,
                colonne=loc.colonne
            ))
    
    # 2. Sort stops by location code (Simple "S-Shape" routing heuristic)
    stops.sort(key=lambda x: x.location_code)
    
    # 3. Re-assign sequence numbers
    for i, stop in enumerate(stops):
        stop.sequence = i + 1
    
    # 4. Create Picking Order in DB
    import uuid
    new_picking = models.PickingOrder(
        id=uuid.uuid4(),
        reference=f"PICK-{uuid.uuid4().hex[:8].upper()}",
        id_preparation_order=request.id_preparation_order,
        assigned_to=request.available_employees[0] if request.available_employees else None,
        statut=models.OrderStatus.PENDING,
        generated_by_ai=True,
        route_distance_m=len(stops) * 5.5 # Mock distance calculation
    )
    db.add(new_picking)
    db.flush() # Flush to get ID for stops
    
    # 4.1 Save stops to DB
    for stop in stops:
        # Find ID for location and product again (simplified)
        loc = db.query(models.Emplacement).filter(models.Emplacement.code_emplacement == stop.location_code).first()
        prod = db.query(models.Produit).filter(models.Produit.nom_produit == stop.product_name).first() # Imprecise but works for mock
        
        db_stop = models.PickingOrderStop(
            id=uuid.uuid4(),
            id_picking_order=new_picking.id,
            stop_sequence=stop.sequence,
            id_produit=prod.id_produit,
            id_emplacement_source=loc.id_emplacement,
            id_emplacement_destination=loc.id_emplacement, # Mock destination
            quantite=stop.quantity,
            statut=models.TransactionStatus.PENDING
        )
        db.add(db_stop)

    db.commit()
    
    return schemas.OptimizedRoute(
        id=new_picking.id,
        reference=new_picking.reference,
        assigned_to=new_picking.assigned_to,
        total_distance_m=new_picking.route_distance_m,
        stops=stops
    )

# 5. Employee Task Endpoints

@app.get("/employee/tasks/{user_id}", response_model=List[schemas.OptimizedRoute])
def get_employee_tasks(user_id: str, db: Session = Depends(get_db)):
    """
    Returns pending picking tasks for an employee, including map coordinates.
    """
    import uuid
    
    # Get pending picking orders assigned to user
    orders = db.query(models.PickingOrder).filter(
        models.PickingOrder.assigned_to == uuid.UUID(user_id),
        models.PickingOrder.statut.in_([models.OrderStatus.PENDING, models.OrderStatus.IN_PROGRESS])
    ).all()
    
    result = []
    for order in orders:
        # Get stops for this order
        db_stops = db.query(models.PickingOrderStop).filter(
            models.PickingOrderStop.id_picking_order == order.id
        ).order_by(models.PickingOrderStop.stop_sequence).all()
        
        stops = []
        for s in db_stops:
            loc = db.query(models.Emplacement).get(s.id_emplacement_source)
            prod = db.query(models.Produit).get(s.id_produit)
            
            stops.append(schemas.PickingStop(
                sequence=s.stop_sequence,
                location_code=loc.code_emplacement,
                product_name=prod.nom_produit,
                quantity=s.quantite,
                niveau=loc.niveau,
                rangee=loc.rangee,
                colonne=loc.colonne
            ))
            
        result.append(schemas.OptimizedRoute(
            id=order.id,
            reference=order.reference,
            assigned_to=order.assigned_to, 
            order_type=order.order_type,
            total_distance_m=order.route_distance_m,
            stops=stops
        ))
        
    return result

@app.post("/employee/tasks/{task_id}/complete")
def complete_employee_task(task_id: str, db: Session = Depends(get_db)):
    import uuid
    from datetime import datetime
    
    # 1. Update Picking Order Status
    order = db.query(models.PickingOrder).filter(models.PickingOrder.id == uuid.UUID(task_id)).first()
    if not order:
        raise HTTPException(status_code=404, detail="Task not found")
        
    order.statut = models.OrderStatus.COMPLETED
    
    # 2. Log Action
    audit = models.AuditLog(
        id_utilisateur=order.assigned_to,
        action="TASK_COMPLETED",
        entity_type="PICKING_ORDER",
        entity_id=str(order.id),
        payload={"reference": order.reference},
        created_at=datetime.now()
    )
    db.add(audit)
    
    db.commit()
    return {"status": "success", "message": "Task completed"}

# 4. Override Logging
@app.post("/ai/log-override")
def log_override(request: schemas.OverrideLogRequest, db: Session = Depends(get_db)):
    """
    Logs a supervisor's decision to override AI.
    """
    import uuid
    from datetime import datetime
    
    override = models.AIOverride(
        id=uuid.uuid4(),
        order_type=request.order_type or "UNKNOWN",
        order_id=uuid.UUID(request.order_id) if request.order_id else None,
        overridden_by=uuid.UUID(request.user_id),
        justification=request.justification,
        ai_suggestion=request.original_ai_suggestion,
        final_decision=request.user_override_value,
        created_at=datetime.utcnow()
    )
    db.add(override)
    db.commit()
    return {"status": "logged", "id": str(override.id)}
