from pydantic import BaseModel, EmailStr
from typing import List, Optional, Any
from uuid import UUID
from datetime import datetime, date
from models import Role, TransactionType, TransactionStatus, Zone, EmplacementType, OrderStatus, ChariotStatus

# Auth Schemas
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: 'Utilisateur' # We'll define Utilisateur later or use a forward ref

# Base Schemas
class EntrepotBase(BaseModel):
    code_entrepot: str
    nom_entrepot: str
    ville: str
    actif: bool = True

class EntrepotCreate(EntrepotBase):
    pass

class Entrepot(EntrepotBase):
    id_entrepot: UUID
    created_at: datetime
    class Config:
        from_attributes = True

class EmplacementBase(BaseModel):
    code_emplacement: str
    id_entrepot: UUID
    zone: Zone
    type_emplacement: EmplacementType
    niveau: int = 0
    rangee: int = 0
    colonne: int = 0
    distance_to_expedition: float = 0.0
    capacite_palettes: int = 1
    actif: bool = True

class EmplacementCreate(EmplacementBase):
    pass

class Emplacement(EmplacementBase):
    id_emplacement: UUID
    class Config:
        from_attributes = True

class UtilisateurBase(BaseModel):
    nom_complet: str
    role: Role
    email: EmailStr
    actif: bool = True

class UtilisateurCreate(UtilisateurBase):
    password: str

class Utilisateur(UtilisateurBase):
    id_utilisateur: UUID
    created_at: datetime
    last_login: Optional[datetime] = None
    class Config:
        from_attributes = True

class ProduitBase(BaseModel):
    sku: str
    nom_produit: str
    unite_mesure: str
    categorie: str
    poids_kg: float
    is_gerbable: bool = True
    colisage_fardeau: Optional[int] = None
    colisage_palette: Optional[int] = None

class ProduitCreate(ProduitBase):
    pass

class Produit(ProduitBase):
    id_produit: UUID
    class Config:
        from_attributes = True

# Stock
class StockParEmplacementBase(BaseModel):
    id_produit: UUID
    id_emplacement: UUID
    quantite: int

class StockParEmplacement(StockParEmplacementBase):
    id: UUID
    updated_at: Optional[datetime] = None
    version: int
    class Config:
        from_attributes = True

# Transactions
class TransactionBase(BaseModel):
    type_transaction: TransactionType
    statut: TransactionStatus

class TransactionCreate(TransactionBase):
    created_by: UUID

class Transaction(TransactionBase):
    id_transaction: UUID
    created_at: datetime
    created_by: UUID
    class Config:
        from_attributes = True

# Orders
class CommandOrderBase(BaseModel):
    reference: str
    statut: OrderStatus
    notes: Optional[str] = None

class CommandOrderCreate(CommandOrderBase):
    created_by: UUID

class CommandOrder(CommandOrderBase):
    id: UUID
    created_at: datetime
    created_by: UUID
    class Config:
        from_attributes = True

class PreparationOrderBase(BaseModel):
    reference: str
    date_prevue: date
    statut: OrderStatus

class PreparationOrderCreate(PreparationOrderBase):
    ai_model_version: str

class PreparationOrder(PreparationOrderBase):
    id: UUID
    generated_by_ai: bool
    ai_model_version: str
    created_at: datetime
    class Config:
        from_attributes = True

class PickingOrderBase(BaseModel):
    reference: str
    assigned_to: Optional[UUID] = None
    statut: OrderStatus

class PickingOrderCreate(PickingOrderBase):
    id_preparation_order: Optional[UUID] = None
    id_chariot: Optional[UUID] = None
    route_distance_m: float

class PickingOrder(PickingOrderBase):
    id: UUID
    id_preparation_order: Optional[UUID] = None
    id_chariot: Optional[UUID] = None
    generated_by_ai: bool
    route_distance_m: float
    created_at: datetime
    class Config:
        from_attributes = True

# AI & Audit
class AIOverrideCreate(BaseModel):
    order_type: str
    order_id: UUID
    overridden_by: UUID
    justification: str
    ai_suggestion: Any
    final_decision: Any

class AuditLogCreate(BaseModel):
    id_utilisateur: UUID
    action: str
    entity_type: str
    entity_id: str
    payload: Optional[Any] = None

class AuditLog(BaseModel):
    id: UUID
    id_utilisateur: UUID
    action: str
    entity_type: str
    entity_id: str
    payload: Any
    created_at: datetime
    class Config:
        from_attributes = True

# Resolve forward references
TokenResponse.model_rebuild()

# --- AI Service Schemas ---

# 1. Forecasting
class ForecastRequest(BaseModel):
    target_date: date

# 2. Storage Assignment
class ReceivedItem(BaseModel):
    id_produit: UUID
    quantite: int
    current_zone: str = "RECEPTION"

class StorageAssignmentRequest(BaseModel):
    received_items: List[ReceivedItem]

class StorageAssignment(BaseModel):
    id_produit: UUID
    target_location_code: str
    path_to_location: Optional[List[str]] = None
    reasoning: Optional[str] = None

# 3. Picking Optimization
class PickingOptimizationRequest(BaseModel):
    id_preparation_order: UUID
    available_employees: Optional[List[UUID]] = None

class PickingStop(BaseModel):
    sequence: int
    location_code: str
    product_name: str
    quantity: int
    niveau: int
    rangee: int
    colonne: int

class OptimizedRoute(BaseModel):
    id: Optional[UUID] = None
    reference: Optional[str] = None
    assigned_to: Optional[UUID]
    total_distance_m: float
    stops: List[PickingStop]

# 4. Override Handling
class OverrideLogRequest(BaseModel):
    original_ai_suggestion: Any
    user_override_value: Any
    justification: str
    user_id: str
    order_id: Optional[str] = None
    order_type: Optional[str] = None
