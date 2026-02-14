import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

def create_tasks_table():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        print("Creating 'tasks' table...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.tasks (
                id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
                title varchar(255) NOT NULL,
                description text,
                status varchar(50) DEFAULT 'pending',
                priority varchar(50) DEFAULT 'medium',
                type varchar(50) DEFAULT 'general',
                assigned_to varchar(255),
                location_data jsonb DEFAULT '{}',
                ai_path_data jsonb DEFAULT '[]',
                products jsonb DEFAULT '[]',
                details jsonb DEFAULT '{}',
                is_synced boolean DEFAULT false,
                created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
                updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
            );
        """)
        
        # Enable RLS
        cur.execute("ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;")
        
        # Create a simple policy to allow all access for now (development mode)
        cur.execute("""
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT FROM pg_catalog.pg_policies 
                    WHERE tablename = 'tasks' AND policyname = 'Enable all access for temp dev'
                ) THEN
                    CREATE POLICY "Enable all access for temp dev" ON public.tasks FOR ALL USING (true) WITH CHECK (true);
                END IF;
            END $$;
        """)

        conn.commit()
        print("Table 'tasks' created successfully.")
        
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    create_tasks_table()
