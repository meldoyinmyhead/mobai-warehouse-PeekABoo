-- Migration: Add extended warehouse metadata and floors

-- 1. Extend entrepots
ALTER TABLE public.entrepots 
ADD COLUMN IF NOT EXISTS adresse text,
ADD COLUMN IF NOT EXISTS heures_ouverture varchar(100),
ADD COLUMN IF NOT EXISTS manager_id uuid REFERENCES public.utilisateurs(id_utilisateur),
ADD COLUMN IF NOT EXISTS largeur float DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS longueur float DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS hauteur float DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS type_climat varchar(50);

-- 2. Create etages table
CREATE TABLE IF NOT EXISTS public.etages (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    id_entrepot uuid REFERENCES public.entrepots(id_entrepot),
    nom_etage varchar(100) NOT NULL,
    code_etage varchar(50) NOT NULL,
    nombre_emplacements int DEFAULT 0,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Extend emplacements
ALTER TABLE public.emplacements
ADD COLUMN IF NOT EXISTS id_etage uuid REFERENCES public.etages(id);
