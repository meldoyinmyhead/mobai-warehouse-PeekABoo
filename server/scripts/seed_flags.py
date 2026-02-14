import os
from supabase import create_client, Client
from dotenv import load_dotenv
from datetime import datetime, timedelta
import uuid

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file")
    exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def seed_flags():
    print("🔄 Seeding sample signalements (flags) data...")
    
    try:
        # First, get some existing data to reference
        # Get a supervisor user ID
        users_response = supabase.table('utilisateurs').select('id_utilisateur').eq('role', 'EMPLOYEE').limit(1).execute()
        if not users_response.data:
            print("⚠️ No employees found. Creating flags without reporter reference.")
            reporter_id = None
        else:
            reporter_id = users_response.data[0]['id_utilisateur']
        
        # Get some location IDs
        locations_response = supabase.table('emplacements').select('id_emplacement').limit(5).execute()
        if not locations_response.data:
            print("⚠️ No emplacements found. Creating flags without location reference.")
            location_ids = [None, None, None, None, None]
        else:
            location_ids = [loc['id_emplacement'] for loc in locations_response.data]
            # Pad with None if not enough locations
            while len(location_ids) < 5:
                location_ids.append(None)
        
        # Sample flags data
        sample_flags = [
            {
                'type_signalement': 'DAMAGED',
                'priorite': 'HIGH',
                'description': 'Produit endommagé lors du transport - palette renversée',
                'id_emplacement': location_ids[0],
                'id_utilisateur_rapporteur': reporter_id,
                'statut': 'PENDING',
                'reference_tache': 'TASK-2024-001',
                'created_at': (datetime.now() - timedelta(hours=2)).isoformat()
            },
            {
                'type_signalement': 'QUANTITY',
                'priorite': 'MEDIUM',
                'description': 'Écart de quantité détecté - 50 unités manquantes',
                'id_emplacement': location_ids[1],
                'id_utilisateur_rapporteur': reporter_id,
                'statut': 'IN_PROGRESS',
                'reference_tache': 'TASK-2024-002',
                'created_at': (datetime.now() - timedelta(hours=5)).isoformat()
            },
            {
                'type_signalement': 'LOCATION',
                'priorite': 'LOW',
                'description': 'Produit mal placé - emplacement incorrect',
                'id_emplacement': location_ids[2],
                'id_utilisateur_rapporteur': reporter_id,
                'statut': 'RESOLVED',
                'reference_tache': 'TASK-2024-003',
                'created_at': (datetime.now() - timedelta(days=1)).isoformat()
            },
            {
                'type_signalement': 'OTHER',
                'priorite': 'MEDIUM',
                'description': 'Emballage défectueux - risque de contamination',
                'id_emplacement': location_ids[3],
                'id_utilisateur_rapporteur': reporter_id,
                'statut': 'PENDING',
                'reference_tache': None,
                'created_at': (datetime.now() - timedelta(hours=12)).isoformat()
            },
            {
                'type_signalement': 'DAMAGED',
                'priorite': 'HIGH',
                'description': 'Produits périssables expirés - retrait urgent nécessaire',
                'id_emplacement': location_ids[4],
                'id_utilisateur_rapporteur': reporter_id,
                'statut': 'IN_PROGRESS',
                'reference_tache': 'TASK-2024-005',
                'created_at': (datetime.now() - timedelta(minutes=30)).isoformat()
            }
        ]
        
        # Insert sample flags
        response = supabase.table('signalements').insert(sample_flags).execute()
        
        if response.data:
            print(f"✅ Successfully inserted {len(response.data)} sample signalements!")
            print(f"   - {sum(1 for f in sample_flags if f['statut'] == 'PENDING')} PENDING")
            print(f"   - {sum(1 for f in sample_flags if f['statut'] == 'IN_PROGRESS')} IN_PROGRESS")
            print(f"   - {sum(1 for f in sample_flags if f['statut'] == 'RESOLVED')} RESOLVED")
        else:
            print("⚠️ Insert completed but no data returned")
            
    except Exception as e:
        print(f"❌ Error seeding flags: {e}")
        print(f"   Make sure the signalements table exists and RLS policies are set correctly")

if __name__ == "__main__":
    seed_flags()
