-- Migration: Add layout_map to entrepot

ALTER TABLE public.entrepots 
ADD COLUMN IF NOT EXISTS layout_map jsonb DEFAULT '{}';
