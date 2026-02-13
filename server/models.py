from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Float, DateTime, Enum, JSON, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import UUID
from database import Base
import enum
import uuid

# Enums - Aligned with database_schema.sql
class Role(str, enum.Enum):
    ADMIN = "ADMIN"
    SUPERVISOR = "SUPERVISOR"
    EMPLOYEE = "EMPLOYEE"

class TransactionType(str, enum.Enum):
    RECEIPT = "RECEIPT"
    TRANSFER = "TRANSFER"
    PICKING = "PICKING"
    DELIVERY = "DELIVERY"

class TransactionStatus(str, enum.Enum):
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class Zone(str, enum.Enum):
    RECEPTION = "RECEPTION"
    STORAGE = "STORAGE"
    PICKING = "PICKING"
    EXPEDITION = "EXPEDITION"

class EmplacementType(str, enum.Enum):
    STORAGE_SLOT = "STORAGE_SLOT"
    PICKING_RACK = "PICKING_RACK"
    ZONE = "ZONE" 

class OrderStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    PENDING = "PENDING"
    PENDING_REVIEW = "PENDING_REVIEW"
    APPROVED = "APPROVED"
    OVERRIDDEN = "OVERRIDDEN"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    Cancelled = "Cancelled"

class ChariotStatus(str, enum.Enum):
    AVAILABLE = "AVAILABLE"
    IN_USE = "IN_USE"
    MAINTENANCE = "MAINTENANCE"

# 2.1 Core Infrastructure Tables
class Entrepot(Base):
    __tablename__ = "entrepots"
    id_entrepot = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code_entrepot = Column(String, unique=True, index=True)
    nom_entrepot = Column(String)
    ville = Column(String)
    actif = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Emplacement(Base):
    __tablename__ = "emplacements"
    id_emplacement = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code_emplacement = Column(String, unique=True, index=True)
    id_entrepot = Column(UUID(as_uuid=True), ForeignKey("entrepots.id_entrepot"))
    zone = Column(Enum(Zone, name="zone_type", create_type=False))
    type_emplacement = Column(Enum(EmplacementType, name="location_type", create_type=False))
    niveau = Column(Integer, default=0)
    rangee = Column(Integer, default=0)
    colonne = Column(Integer, default=0)
    distance_to_expedition = Column(Float, default=0.0)
    capacite_palettes = Column(Integer, default=1)
    actif = Column(Boolean, default=True)

class Utilisateur(Base):
    __tablename__ = "utilisateurs"
    id_utilisateur = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nom_complet = Column(String)
    role = Column(Enum(Role, name="user_role", create_type=False))
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)
    actif = Column(Boolean, default=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"), nullable=True)
    last_login = Column(DateTime)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Produit(Base):
    __tablename__ = "produits"
    id_produit = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sku = Column(String, unique=True, index=True)
    nom_produit = Column(String)
    unite_mesure = Column(String)
    categorie = Column(String)
    poids_kg = Column(Float)
    is_gerbable = Column(Boolean, default=True)
    colisage_fardeau = Column(Integer)
    colisage_palette = Column(Integer)

class CodeBarresProduit(Base):
    __tablename__ = "code_barres_produit"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    code_barre = Column(String, unique=True, index=True) # Changed from code_barres to code_barre to match schema
    principal = Column(Boolean, default=False)

# 2.2 Stock Tracking & Transactions
class StockParEmplacement(Base):
    __tablename__ = "stock_par_emplacement"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    id_emplacement = Column(UUID(as_uuid=True), ForeignKey("emplacements.id_emplacement"))
    quantite = Column(Integer, default=0)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    version = Column(Integer, default=1) # Optimistic locking

class Transaction(Base):
    __tablename__ = "transactions"
    id_transaction = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    type_transaction = Column(Enum(TransactionType, name="transaction_type", create_type=False))
    statut = Column(Enum(TransactionStatus, name="transaction_status", create_type=False))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"))

class LigneTransaction(Base):
    __tablename__ = "lignes_transactions"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_transaction = Column(UUID(as_uuid=True), ForeignKey("transactions.id_transaction"))
    no_ligne = Column(Integer)
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    quantite = Column(Integer)
    id_emplacement_source = Column(UUID(as_uuid=True), ForeignKey("emplacements.id_emplacement"), nullable=True)
    id_emplacement_destination = Column(UUID(as_uuid=True), ForeignKey("emplacements.id_emplacement"), nullable=True)
    lot_serie = Column(String)
    code_motif = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 2.3 Order Tables
class CommandOrder(Base):
    __tablename__ = "command_orders"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    reference = Column(String, unique=True, index=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"))
    statut = Column(Enum(OrderStatus, name="order_status", create_type=False))
    notes = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class CommandOrderLine(Base):
    __tablename__ = "command_order_lines"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_command_order = Column(UUID(as_uuid=True), ForeignKey("command_orders.id"))
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    quantite_attendue = Column(Integer)
    quantite_recue = Column(Integer, nullable=True)

class PreparationOrder(Base):
    __tablename__ = "preparation_orders"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    reference = Column(String, unique=True, index=True)
    date_prevue = Column(Date)
    generated_by_ai = Column(Boolean, default=True)
    ai_model_version = Column(String)
    statut = Column(Enum(OrderStatus, name="order_status", create_type=False))
    approved_by = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"), nullable=True)
    approved_at = Column(DateTime)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class PreparationOrderLine(Base):
    __tablename__ = "preparation_order_lines"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_preparation_order = Column(UUID(as_uuid=True), ForeignKey("preparation_orders.id"))
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    quantite_ai = Column(Integer)
    quantite_finale = Column(Integer)

class PickingOrder(Base):
    __tablename__ = "picking_orders"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    reference = Column(String, unique=True, index=True)
    id_preparation_order = Column(UUID(as_uuid=True), ForeignKey("preparation_orders.id"), nullable=True)
    assigned_to = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"))
    id_chariot = Column(UUID(as_uuid=True), ForeignKey("chariots.id"), nullable=True)
    generated_by_ai = Column(Boolean, default=True)
    statut = Column(Enum(OrderStatus, name="order_status", create_type=False))
    approved_by = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"), nullable=True)
    route_distance_m = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class PickingOrderStop(Base):
    __tablename__ = "picking_order_stops"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_picking_order = Column(UUID(as_uuid=True), ForeignKey("picking_orders.id"))
    stop_sequence = Column(Integer)
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    id_emplacement_source = Column(UUID(as_uuid=True), ForeignKey("emplacements.id_emplacement"))
    id_emplacement_destination = Column(UUID(as_uuid=True), ForeignKey("emplacements.id_emplacement"))
    quantite = Column(Integer)
    statut = Column(Enum(TransactionStatus, name="transaction_status", create_type=False))
    completed_at = Column(DateTime)

class DeliveryRecord(Base):
    __tablename__ = "delivery_records"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_picking_order = Column(UUID(as_uuid=True), ForeignKey("picking_orders.id"))
    executed_by = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"))
    resultat = Column(Enum(name="delivery_result", create_type=False)) 
    notes = Column(String)
    delivered_at = Column(DateTime(timezone=True), server_default=func.now())

# 2.4 Override & Audit
class AIOverride(Base):
    __tablename__ = "ai_overrides"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    order_type = Column(String) # PREPARATION, PICKING, STORAGE
    order_id = Column(UUID(as_uuid=True))
    overridden_by = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"))
    justification = Column(String, nullable=False)
    ai_suggestion = Column(JSON)
    final_decision = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class AuditLog(Base):
    __tablename__ = "audit_log"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_utilisateur = Column(UUID(as_uuid=True), ForeignKey("utilisateurs.id_utilisateur"))
    action = Column(String)
    entity_type = Column(String)
    entity_id = Column(UUID(as_uuid=True))
    payload = Column(JSON)
    ip_address = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 2.6 Supporting
class Chariot(Base):
    __tablename__ = "chariots"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code_chariot = Column(String, unique=True, index=True)
    statut = Column(Enum(ChariotStatus, name="chariot_status", create_type=False))
    id_entrepot = Column(UUID(as_uuid=True), ForeignKey("entrepots.id_entrepot"))
    last_known_location = Column(UUID(as_uuid=True), ForeignKey("emplacements.id_emplacement"), nullable=True)
    actif = Column(Boolean, default=True)

# AI Forecasting & Policy (GIVEN in 1.8, 1.10, 1.11)
class HistoriqueDemande(Base):
    __tablename__ = "historique_demandes"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    date = Column(Date)
    quantite_demandee = Column(Integer)

class PolitiqueReapprovisionnement(Base):
    __tablename__ = "politique_reapprovisionnement"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    stock_securite = Column(Integer)
    quantite_min_commande = Column(Integer)
    taille_lot = Column(Integer)

class DelaisApprovisionnement(Base):
    __tablename__ = "delais_approvisionnement"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_produit = Column(UUID(as_uuid=True), ForeignKey("produits.id_produit"))
    nb_jours_delai = Column(Integer)
