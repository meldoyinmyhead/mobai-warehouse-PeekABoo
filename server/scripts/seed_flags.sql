-- Run this SQL script directly in your Supabase SQL Editor
-- to populate sample flags data without needing Python

-- Insert 5 sample flags with different types and statuses
INSERT INTO public.signalements (
    type_signalement, 
    priorite, 
    description, 
    statut,
    created_at
) VALUES 
    -- Flag 1: Damaged product (PENDING)
    (
        'DAMAGED', 
        'HIGH', 
        'Produit endommagé lors du transport - palette renversée', 
        'PENDING',
        now() - interval '2 hours'
    ),
    
    -- Flag 2: Quantity discrepancy (IN_PROGRESS)
    (
        'QUANTITY', 
        'MEDIUM', 
        'Écart de quantité détecté - 50 unités manquantes', 
        'IN_PROGRESS',
        now() - interval '5 hours'
    ),
    
    -- Flag 3: Wrong location (RESOLVED)
    (
        'LOCATION', 
        'LOW', 
        'Produit mal placé - emplacement incorrect', 
        'RESOLVED',
        now() - interval '1 day'
    ),
    
    -- Flag 4: Other issue (PENDING)
    (
        'OTHER', 
        'MEDIUM', 
        'Emballage défectueux - risque de contamination', 
        'PENDING',
        now() - interval '12 hours'
    ),
    
    -- Flag 5: Expired products (IN_PROGRESS)
    (
        'DAMAGED', 
        'HIGH', 
        'Produits périssables expirés - retrait urgent nécessaire', 
        'IN_PROGRESS',
        now() - interval '30 minutes'
    );

-- Verify the insert worked
SELECT 
    type_signalement,
    priorite,
    statut,
    description,
    created_at
FROM public.signalements
ORDER BY created_at DESC
LIMIT 10;
