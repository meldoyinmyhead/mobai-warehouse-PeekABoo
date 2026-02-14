-- INSTRUCTIONS:
-- 1. Run the Python seeder first: `python seed.py`
-- 2. Sign up/Login to your app (or Supabase Dashboard) to get your Authentication User ID (UUID).
-- 3. Replace 'YOUR_USER_ID_HERE' with that UUID in the scripts below.
-- 4. Run this script in the Supabase SQL Editor.

-- STEP 1: Link your Auth User to the Employee Table
INSERT INTO public.utilisateurs (id_utilisateur, nom_complet, role, email)
VALUES (
    'YOUR_USER_ID_HERE',   -- <--- PASTE YOUR UUID HERE
    'Demo User', 
    'SUPERVISOR',          -- Role: SUPERVISOR or EMPLOYEE
    'demo@mobai.com'
) ON CONFLICT (id_utilisateur) DO NOTHING;

-- STEP 2: Create a Mock Picking Order assigned to YOU
INSERT INTO public.picking_orders (
    reference, 
    assigned_to, 
    statut, 
    route_distance_m,
    created_at
) VALUES (
    'PICK-DEMO-001', 
    'YOUR_USER_ID_HERE',   -- <--- PASTE YOUR UUID HERE
    'PENDING', 
    150.5,
    now()
);

-- STEP 3: Add stops to the Picking Order
-- (Relies on Products/Locations created by seed.py)
INSERT INTO public.picking_order_stops (
    id_picking_order, 
    stop_sequence, 
    id_produit, 
    id_emplacement_source, 
    id_emplacement_destination, 
    quantite, 
    statut
) VALUES 
(
    (SELECT id FROM public.picking_orders WHERE reference = 'PICK-DEMO-001'),
    1,
    (SELECT id_produit FROM public.produits WHERE sku = 'ABC-001'),
    (SELECT id_emplacement FROM public.emplacements WHERE code_emplacement = 'B7-N2-C4'),
    (SELECT id_emplacement FROM public.emplacements WHERE code_emplacement = 'B7-RECEPTION-01'),
    5,
    'PENDING'
),
(
    (SELECT id FROM public.picking_orders WHERE reference = 'PICK-DEMO-001'),
    2,
    (SELECT id_produit FROM public.produits WHERE sku = 'ABC-002'),
    (SELECT id_emplacement FROM public.emplacements WHERE code_emplacement = 'B7-0A-03-05'),
    (SELECT id_emplacement FROM public.emplacements WHERE code_emplacement = 'B7-RECEPTION-01'),
    3,
    'PENDING'
);
