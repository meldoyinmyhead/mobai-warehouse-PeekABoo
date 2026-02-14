from fastapi import FastAPI, Depends, HTTPException, status, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List, Optional
import models, schemas
from database import engine, SessionLocal, Base

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="MobAI WMS Backend", version="1.0.0")

# Security Scheme
security = HTTPBearer()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Auth Dependency
def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security), db: Session = Depends(get_db)) -> models.Utilisateur:
    token = credentials.credentials
    if not token.startswith("mock_token_"):
        raise HTTPException(status_code=403, detail="Invalid authentication token")
    
    try:
        user_id_str = token.replace("mock_token_", "")
        import uuid
        user_uuid = uuid.UUID(user_id_str)
        user = db.query(models.Utilisateur).filter(models.Utilisateur.id_utilisateur == user_uuid).first()
    except:
         raise HTTPException(status_code=403, detail="Invalid token format")

    if not user:
        raise HTTPException(status_code=403, detail="User not found")
    if not user.actif:
        raise HTTPException(status_code=403, detail="User inactive")
    return user

def require_role(allowed_roles: List[str]):
    def role_checker(user: models.Utilisateur = Depends(get_current_user)):
        if user.role.value not in allowed_roles:
            raise HTTPException(status_code=403, detail=f"Operation not permitted for role {user.role.value}")
        return user
    return role_checker

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
def create_user(user: schemas.UtilisateurCreate, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["ADMIN"]))):
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
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["ADMIN"]))):
    users = db.query(models.Utilisateur).offset(skip).limit(limit).all()
    return users

@app.put("/users/{user_id}", response_model=schemas.Utilisateur)
def update_user(user_id: str, user_update: schemas.UtilisateurBase, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["ADMIN"]))):
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
def delete_user(user_id: str, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["ADMIN"]))):
    import uuid
    db_user = db.query(models.Utilisateur).filter(models.Utilisateur.id_utilisateur == uuid.UUID(user_id)).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(db_user)
    db.commit()
    return {"status": "success", "message": "User deleted"}

@app.get("/employees", response_model=List[schemas.Utilisateur])
def get_employees(db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["SUPERVISOR", "ADMIN"]))):
    return db.query(models.Utilisateur).filter(models.Utilisateur.role == models.Role.EMPLOYEE).all()

@app.get("/chariots", response_model=List[schemas.Chariot])
def get_chariots(db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["SUPERVISOR", "ADMIN"]))):
    chariots = db.query(models.Chariot).all()
    # Dynamic status update: if chariot is linked to an active order, it's IN_USE
    active_chariot_ids = [order.id_chariot for order in db.query(models.PickingOrder).filter(models.PickingOrder.statut.in_([models.OrderStatus.PENDING, models.OrderStatus.IN_PROGRESS, models.OrderStatus.APPROVED])).all() if order.id_chariot]
    
    for chariot in chariots:
        if chariot.id in active_chariot_ids:
            chariot.statut = models.ChariotStatus.IN_USE
        else:
            chariot.statut = models.ChariotStatus.AVAILABLE # "Standby"
            
    return chariots

# 2. Warehouse Infrastructure
@app.get("/entrepots/", response_model=List[schemas.Entrepot])
def list_entrepots(db: Session = Depends(get_db)):
    return db.query(models.Entrepot).all()

@app.post("/entrepots/", response_model=schemas.Entrepot, status_code=status.HTTP_201_CREATED)
def create_entrepot(entrepot: schemas.EntrepotCreate, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["ADMIN"]))):
    db_entrepot = models.Entrepot(**entrepot.dict())
    db.add(db_entrepot)
    db.commit()
    db.refresh(db_entrepot)
    return db_entrepot

@app.put("/entrepots/{entrepot_id}", response_model=schemas.Entrepot)
def update_entrepot(entrepot_id: str, entrepot_update: schemas.EntrepotUpdate, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["ADMIN"]))):
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
def delete_entrepot(entrepot_id: str, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["ADMIN"]))):
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

def get_user_last_location(user_id: str, db: Session) -> str:
    """
    Finds the last known location of a user based on their task history.
    Defaults to 'ENTRANCE' (or a specific depot location ID) if no history.
    """
    try:
        import uuid
        uid = uuid.UUID(user_id)
        
        # 1. Find last completed task for this user
        last_log = db.query(models.AuditLog).filter(
            models.AuditLog.id_utilisateur == uid,
            models.AuditLog.action == 'TASK_COMPLETED',
            models.AuditLog.entity_type == 'PICKING_ORDER'
        ).order_by(models.AuditLog.created_at.desc()).first()
        
        if last_log:
            # 2. Get the last stop of that task
            last_task_id = uuid.UUID(last_log.entity_id)
            last_stop = db.query(models.PickingOrderStop).filter(
                models.PickingOrderStop.id_picking_order == last_task_id
            ).order_by(models.PickingOrderStop.stop_sequence.desc()).first()
            
            if last_stop:
                # 3. Return the location of that stop
                loc = db.query(models.Emplacement).get(last_stop.id_emplacement_source)
                if loc:
                    return str(loc.id_emplacement)
    except Exception as e:
        print(f"Error finding last location: {e}")
        
    # Default to Entrance if can't determine
    # In a real app, you'd fetch the ID of 'ENTRANCE' location
    # For now, let's assume 'DEPOT_001' is the entrance/start
    return "DEPOT_001"

# 3. Picking Optimization Service
@app.post("/ai/optimize-picking", response_model=schemas.OptimizedRoute)
async def optimize_picking(request: schemas.PickingOptimizationRequest, db: Session = Depends(get_db)):
    """
    Generates an optimized picking route.
    Logic: Query AI service with dynamic start location.
    """
    # 0. Determine Start Location
    start_location_id = "DEPOT_001"
    if request.available_employees:
        start_location_id = get_user_last_location(str(request.available_employees[0]), db)

    # 1. Get lines for this preparation order
    lines = db.query(models.PreparationOrderLine).filter(
        models.PreparationOrderLine.id_preparation_order == request.id_preparation_order
    ).all()
    
    # Collect data for AI
    picks_data = []
    locations_data = []
    location_ids = set()

    stops_map = {} # Map custom ID to stop info for later

    # Add Start Location to locations_data if it's a UUID (real location)
    try:
        import uuid
        start_uuid = uuid.UUID(start_location_id)
        start_loc = db.query(models.Emplacement).get(start_uuid)
        if start_loc:
             locations_data.append({
                "location_id": str(start_loc.id_emplacement),
                "code": start_loc.code_emplacement,
                "x": float(start_loc.rangee) * 2.0,
                "y": float(start_loc.colonne) * 1.5,
                "z": float(start_loc.niveau) * 1.0,
                "zone": start_loc.zone.value if hasattr(start_loc.zone, 'value') else str(start_loc.zone)
            })
             location_ids.add(start_loc.id_emplacement)
    except ValueError:
        # Not a UUID, assume it's a special code like "DEPOT_001"
        if start_location_id == "DEPOT_001" and start_location_id not in location_ids:
             locations_data.append({
                "location_id": start_location_id,
                "code": "ENTRANCE",
                "x": 0.0,
                "y": 0.0,
                "z": 0.0,
                "zone": "ENTRANCE"
            })
             location_ids.add(start_location_id)


    for line in lines:
        # Find where this product is stored
        stock = db.query(models.StockParEmplacement, models.Emplacement).join(models.Emplacement).filter(
            models.StockParEmplacement.id_produit == line.id_produit,
            models.StockParEmplacement.quantite > 0
        ).first()
        
        if stock:
            loc = stock.Emplacement
            prod = db.query(models.Produit).get(line.id_produit)
            
            # Add to picks data
            pick_id = f"PICK-{line.id}"
            picks_data.append({
                "id": pick_id,
                "location_id": str(loc.id_emplacement),
                "product_id": str(prod.id_produit),
                "quantity": line.quantite_finale,
                "priority": 1
            })

            # Add to locations data if new
            if loc.id_emplacement not in location_ids:
                locations_data.append({
                    "location_id": str(loc.id_emplacement),
                    "code": loc.code_emplacement,
                    "x": float(loc.rangee) * 2.0, # Mock coordinates if not in DB
                    "y": float(loc.colonne) * 1.5,
                    "z": float(loc.niveau) * 1.0,
                    "zone": loc.zone.value if hasattr(loc.zone, 'value') else str(loc.zone)
                })
                location_ids.add(loc.id_emplacement)

            # Store metadata for creating the stop later
            stops_map[pick_id] = {
                "line": line,
                "loc": loc,
                "prod": prod
            }

    # Call AI Service
    from services.ai_client import AIClient
    ai_client = AIClient()
    
    # Run async AI call in sync context (using asyncio.run or similar if needed, 
    # but FastAPI supports async def. transforming this endpoint to async def)
    
    # We need to change the function signature to async first. 
    # Since I am only replacing the body, I will assume I can use `await` if I change the signature.
    # WAIT: The current function is `def`, not `async def`. I need to change it to `async def`.
    # I will do that in a separate step or assume I can use a sync wrapper? 
    # No, better to make it async.
    
    # For now, I will write the LOGIC assuming I can use await. 
    # I will replace the signature in the next step.
    
    try:
        ai_result = await ai_client.optimize_picking(
            picks_data=picks_data,
            locations_data=locations_data,
            strategy="wave", 
            optimize_route=True,
            start_location=start_location_id
        )
    except Exception as e:
        print(f"AI Call failed: {e}")
        ai_result = {"success": False}

    # 4. Create Picking Order in DB
    import uuid
    new_picking = models.PickingOrder(
        id=uuid.uuid4(),
        reference=f"PICK-{uuid.uuid4().hex[:8].upper()}",
        id_preparation_order=request.id_preparation_order,
        assigned_to=request.available_employees[0] if request.available_employees else None,
        statut=models.OrderStatus.PENDING,
        generated_by_ai=True,
        route_distance_m=ai_result.get("metrics", {}).get("total_distance", len( stops) * 5.5) 
    )
    db.add(new_picking)
    db.flush() 
    
    for stop in stops:
        # Find ID again (inefficient but safe)
        loc = db.query(models.Emplacement).filter(models.Emplacement.code_emplacement == stop.location_code).first()
        prod = db.query(models.Produit).filter(models.Produit.nom_produit == stop.product_name).first()
        
        db_stop = models.PickingOrderStop(
            id=uuid.uuid4(),
            id_picking_order=new_picking.id,
            stop_sequence=stop.sequence,
            id_produit=prod.id_produit,
            id_emplacement_source=loc.id_emplacement,
            id_emplacement_destination=loc.id_emplacement, 
            quantite=stop.quantity,
            statut=models.TransactionStatus.PENDING
        )
        db.add(db_stop)

    db.commit()
    
    # 5. Prepend Start Location to Response ONLY (for UI Path)
    response_stops = list(stops) # Copy
    
    # Resolving start location coordinates
    start_x, start_y, start_z, start_code = 0.0, 0.0, 0.0, "ENTRANCE"
    if start_location_id == "DEPOT_001":
        pass # Defaults
    else:
        try:
             start_uuid_resp = uuid.UUID(start_location_id)
             s_loc = db.query(models.Emplacement).get(start_uuid_resp)
             if s_loc:
                 start_code = s_loc.code_emplacement
                 start_z = s_loc.niveau
                 start_x = s_loc.colonne # Sent as 'colonne' -> x
                 start_y = s_loc.rangee  # Sent as 'rangee' -> y
        except:
             pass

    # Add start stop at index 0
    response_stops.insert(0, schemas.PickingStop(
        sequence=0,
        location_code=start_code,
        product_name="Start",
        quantity=0,
        niveau=int(start_z),
        rangee=int(start_y),
        colonne=int(start_x)
    ))

    return schemas.OptimizedRoute(
        id=new_picking.id,
        reference=new_picking.reference,
        assigned_to=new_picking.assigned_to,
        total_distance_m=new_picking.route_distance_m,
        stops=response_stops
    )

    # 4. Create Picking Order in DB (Same as before)
    import uuid
    new_picking = models.PickingOrder(
        id=uuid.uuid4(),
        reference=f"PICK-{uuid.uuid4().hex[:8].upper()}",
        id_preparation_order=request.id_preparation_order,
        assigned_to=request.available_employees[0] if request.available_employees else None,
        statut=models.OrderStatus.PENDING,
        generated_by_ai=True,
        route_distance_m=ai_result.get("metrics", {}).get("total_distance", len(stops) * 5.5) 
    )
    db.add(new_picking)
    db.flush() 
    
    for stop in stops:
        # Find ID again (inefficient but safe)
        loc = db.query(models.Emplacement).filter(models.Emplacement.code_emplacement == stop.location_code).first()
        prod = db.query(models.Produit).filter(models.Produit.nom_produit == stop.product_name).first()
        
        db_stop = models.PickingOrderStop(
            id=uuid.uuid4(),
            id_picking_order=new_picking.id,
            stop_sequence=stop.sequence,
            id_produit=prod.id_produit,
            id_emplacement_source=loc.id_emplacement,
            id_emplacement_destination=loc.id_emplacement, 
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
def complete_employee_task(task_id: str, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["EMPLOYEE", "SUPERVISOR", "ADMIN"]))):
    import uuid
    from datetime import datetime
    import logging
    
    logger = logging.getLogger("uvicorn.error")
    
    try:
        task_uuid = uuid.UUID(task_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid task ID format")

    # 1. Update Picking Order Status
    order = db.query(models.PickingOrder).filter(models.PickingOrder.id == task_uuid).first()
    if not order:
        logger.error(f"Task {task_id} not found")
        raise HTTPException(status_code=404, detail="Task not found")
    
    if order.statut == models.OrderStatus.COMPLETED:
        return {"status": "success", "message": "Task already completed"}

    # 2. Execute Stock Movements for each stop
    stops = db.query(models.PickingOrderStop).filter(models.PickingOrderStop.id_picking_order == order.id).all()
    logger.info(f"Completing task {task_id} with {len(stops)} stops")
    
    for stop in stops:
        # Check source stock
        source_stock = db.query(models.StockParEmplacement).filter(
            models.StockParEmplacement.id_emplacement == stop.id_emplacement_source,
            models.StockParEmplacement.id_produit == stop.id_produit
        ).first() 
        
        if not source_stock or source_stock.quantite < stop.quantite:
             logger.error(f"Insufficient stock for product {stop.id_produit} at {stop.id_emplacement_source}")
             raise HTTPException(status_code=400, detail=f"Insufficient stock for product {stop.id_produit} at source")

        # Decrement source
        source_stock.quantite -= stop.quantite
        source_stock.updated_at = datetime.now()
        source_stock.version += 1
        
        # Increment destination
        if stop.id_emplacement_destination and stop.id_emplacement_destination != stop.id_emplacement_source:
             dest_stock = db.query(models.StockParEmplacement).filter(
                models.StockParEmplacement.id_emplacement == stop.id_emplacement_destination,
                models.StockParEmplacement.id_produit == stop.id_produit
             ).first()
             
             if dest_stock:
                 dest_stock.quantite += stop.quantite
                 dest_stock.updated_at = datetime.now()
                 dest_stock.version += 1
             else:
                 # Create new stock record
                 new_stock = models.StockParEmplacement(
                     id=uuid.uuid4(),
                     id_produit=stop.id_produit,
                     id_emplacement=stop.id_emplacement_destination,
                     quantite=stop.quantite,
                     version=1,
                     updated_at=datetime.now()
                 )
                 db.add(new_stock)
        
        # Mark stop as completed
        stop.statut = models.TransactionStatus.COMPLETED
        stop.completed_at = datetime.now()

    order.statut = models.OrderStatus.COMPLETED
    
    # 3. Log Action (Using a dummy ID for test if auth disabled)
    audit = models.AuditLog(
        id_utilisateur=order.assigned_to, # Use the assigned user's ID
        action="TASK_COMPLETED",
        entity_type="PICKING_ORDER",
        entity_id=order.id,
        payload={"reference": order.reference},
        created_at=datetime.now()
    )
    db.add(audit)
    
    try:
        db.commit()
        logger.info(f"Task {task_id} completed successfully")
    except Exception as e:
        db.rollback()
        logger.exception("Transaction failed during task completion")
        raise HTTPException(status_code=500, detail=f"Transaction failed: {str(e)}")
        
    return {"status": "success", "message": "Task completed and stock updated"}

# --- Supervisor: Pending AI Reviews (for offline cache & sync) ---
@app.get("/supervisor/pending-reviews")
def get_pending_reviews(db: Session = Depends(get_db)):
    """
    Returns preparation and picking orders with status PENDING_REVIEW for supervisor to approve/override.
    Used by mobile to fetch when online and cache locally for offline review.
    """
    prep_orders = db.query(models.PreparationOrder).filter(
        models.PreparationOrder.statut == models.OrderStatus.PENDING_REVIEW
    ).all()
    pick_orders = db.query(models.PickingOrder).filter(
        models.PickingOrder.statut == models.OrderStatus.PENDING_REVIEW
    ).all()

    prep_list = []
    for o in prep_orders:
        lines = db.query(models.PreparationOrderLine).filter(
            models.PreparationOrderLine.id_preparation_order == o.id
        ).all()
        line_data = []
        for ln in lines:
            prod = db.query(models.Produit).filter(models.Produit.id_produit == ln.id_produit).first()
            line_data.append({
                "id": str(ln.id),
                "quantite_ai": ln.quantite_ai,
                "quantite_finale": ln.quantite_finale,
                "sku": prod.sku if prod else "",
                "nom_produit": prod.nom_produit if prod else "",
            })
        prep_list.append({
            "id": str(o.id),
            "reference": o.reference,
            "type": "preparation",
            "statut": o.statut.value,
            "date_prevue": o.date_prevue.isoformat() if o.date_prevue else None,
            "created_at": o.created_at.isoformat() if o.created_at else None,
            "lines": line_data,
        })

    pick_list = []
    for o in pick_orders:
        stops = db.query(models.PickingOrderStop).filter(
            models.PickingOrderStop.id_picking_order == o.id
        ).order_by(models.PickingOrderStop.stop_sequence).all()
        stop_data = []
        for st in stops:
            prod = db.query(models.Produit).filter(models.Produit.id_produit == st.id_produit).first()
            stop_data.append({
                "stop_sequence": st.stop_sequence,
                "quantite": st.quantite,
                "sku": prod.sku if prod else "",
                "nom_produit": prod.nom_produit if prod else "",
            })
        pick_list.append({
            "id": str(o.id),
            "reference": o.reference,
            "type": "picking",
            "statut": o.statut.value,
            "route_distance_m": o.route_distance_m,
            "created_at": o.created_at.isoformat() if o.created_at else None,
            "stops": stop_data,
        })

    return {"preparation_orders": prep_list, "picking_orders": pick_list}


@app.post("/supervisor/preparation-orders/{order_id}/approve")
def approve_preparation_order(order_id: str, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["SUPERVISOR", "ADMIN"]))):
    import uuid
    order = db.query(models.PreparationOrder).filter(
        models.PreparationOrder.id == uuid.UUID(order_id)
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Preparation order not found")
    order.statut = models.OrderStatus.APPROVED
    db.commit()
    return {"status": "success", "message": "Preparation order approved"}


@app.post("/supervisor/picking-orders/{order_id}/approve")
def approve_picking_order(order_id: str, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["SUPERVISOR", "ADMIN"]))):
    import uuid
    order = db.query(models.PickingOrder).filter(
        models.PickingOrder.id == uuid.UUID(order_id)
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Picking order not found")
    order.statut = models.OrderStatus.APPROVED
    db.commit()
    return {"status": "success", "message": "Picking order approved"}


# 4. Override Logging
@app.post("/ai/log-override")
def log_override(request: schemas.OverrideLogRequest, db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["SUPERVISOR", "ADMIN"]))):
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
    # Mark the original order as OVERRIDDEN so it no longer appears in pending reviews
    if request.order_id and request.order_type:
        try:
            oid = uuid.UUID(request.order_id)
            if request.order_type.upper() == "PREPARATION":
                order = db.query(models.PreparationOrder).filter(models.PreparationOrder.id == oid).first()
            else:
                order = db.query(models.PickingOrder).filter(models.PickingOrder.id == oid).first()
            if order:
                order.statut = models.OrderStatus.OVERRIDDEN
        except (ValueError, TypeError):
            pass
    db.commit()
    return {"status": "logged", "id": str(override.id)}

# 6. Scheduler Integration
from scheduler import start_scheduler, daily_forecast_job

@app.on_event("startup")
def startup_event():
    start_scheduler()

@app.post("/scheduler/trigger-daily")
def trigger_daily_job_manual(db: Session = Depends(get_db), current_user: models.Utilisateur = Depends(require_role(["ADMIN"]))):
    """
    Manually triggers the daily forecast job (for testing).
    """
    try:
        # Run sync for now, or trigger the job via scheduler
        daily_forecast_job()
        return {"status": "triggered", "message": "Daily forecast job triggered successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

