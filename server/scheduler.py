from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import uuid
import asyncio

from database import SessionLocal
import models
from services.ai_client import AIClient

scheduler = BackgroundScheduler()
ai_client = AIClient()

def get_db_session():
    return SessionLocal()

def daily_forecast_job():
    """
    Job that runs daily to:
    1. Fetch forecast from AI Microservice.
    2. Create a Preparation Order in the DB.
    """
    print(f"[{datetime.now()}] Starting Daily Forecast Job...")
    db = get_db_session()
    try:
        # 1. Call AI Service (Async call in sync context needs handling)
        # For simplicity in this demo, we might use a sync wrapper or just standard requests if httpx is trouble.
        # But since we used httpx async, we need a loop. 
        # However, APScheduler runs in threads. 
        
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        forecast_data = loop.run_until_complete(ai_client.get_forecast(horizon_days=1))
        loop.close()
        
        if not forecast_data:
            print("No forecast data received or error occurred.")
            return

        # 2. Process Forecast Data
        # Assuming forecast_data is a list of {"product_id": ..., "quantity": ...}
        # Or maybe it returns a dict with "predictions". 
        # I'll implement a generic handler for now.
        
        target_date = datetime.now().date() + timedelta(days=1) # Forecast for tomorrow
        
        # Check if text exists
        existing = db.query(models.PreparationOrder).filter(
            models.PreparationOrder.date_prevue == target_date,
            models.PreparationOrder.generated_by_ai == True
        ).first()
        
        if existing:
            print(f"Preparation Order for {target_date} already exists. Skipping.")
            return

        # Create Order
        new_order = models.PreparationOrder(
            id=uuid.uuid4(),
            reference=f"CMD-AI-{target_date.strftime('%Y%m%d')}",
            date_prevue=target_date,
            statut=models.OrderStatus.DRAFT, # Needs review
            generated_by_ai=True,
            ai_model_version="v1.0-scheduler"
        )
        db.add(new_order)
        db.flush()
        
        # Add Lines (Mock logic if real AI response is empty for now, or parse it)
        # Using the mockup logic from main.py as fallback if AI returns empty but valid structure
        
        products = db.query(models.Produit).limit(5).all()
        for p in products:
             # Logic to find quantity from forecast_data would go here
             # For now, we seed random values to simulate "AI"
            line = models.PreparationOrderLine(
                id=uuid.uuid4(),
                id_preparation_order=new_order.id,
                id_produit=p.id_produit,
                quantite_ai=15, 
                quantite_finale=15
            )
            db.add(line)
            
        db.commit()
        print(f"Successfully created Daily Preparation Order: {new_order.reference}")

        # 3. Automatically Create Picking Task for Employee (Assignment)
        # Find an employee
        employee = db.query(models.Utilisateur).filter(models.Utilisateur.role == models.Role.EMPLOYEE).first()
        if not employee:
            print("No employee found to assign tasks.")
            return

        # Create Picking Order
        new_picking = models.PickingOrder(
            id=uuid.uuid4(),
            reference=f"PICK-{new_order.reference.split('-')[-1]}",
            id_preparation_order=new_order.id,
            assigned_to=employee.id_utilisateur,
            statut=models.OrderStatus.PENDING,
            generated_by_ai=True,
            route_distance_m=150.5 # Mock distance
        )
        db.add(new_picking)
        db.flush()

        # Create Stops (One per product line)
        order_lines = db.query(models.PreparationOrderLine).filter(
            models.PreparationOrderLine.id_preparation_order == new_order.id
        ).all()
        for i, line in enumerate(order_lines):
            # Find location for product
            stock = db.query(models.StockParEmplacement).filter(
                models.StockParEmplacement.id_produit == line.id_produit,
                models.StockParEmplacement.quantite > 0
            ).first()
            
            location_id = stock.id_emplacement if stock else None
            # If no stock, we pick a random location or skip
            if not location_id:
                # Fallback to first location
                loc = db.query(models.Emplacement).first()
                location_id = loc.id_emplacement if loc else None

            if location_id:
                stop = models.PickingOrderStop(
                    id=uuid.uuid4(),
                    id_picking_order=new_picking.id,
                    stop_sequence=i + 1,
                    id_produit=line.id_produit,
                    id_emplacement_source=location_id,
                    id_emplacement_destination=location_id, # Simplified
                    quantite=line.quantite_finale,
                    statut=models.TransactionStatus.PENDING
                )
                db.add(stop)

        db.commit()
        print(f"Successfully created Picking Order {new_picking.reference} assigned to {employee.nom_complet}")

    except Exception as e:
        print(f"Error in Daily Forecast Job: {e}")
        db.rollback()
    finally:
        db.close()

def start_scheduler():
    # Run every day at 00:00
    trigger = CronTrigger(hour=0, minute=0)
    scheduler.add_job(daily_forecast_job, trigger, id='daily_forecast')
    scheduler.start()
    print("Scheduler started. Daily forecast job scheduled for 00:00.")
