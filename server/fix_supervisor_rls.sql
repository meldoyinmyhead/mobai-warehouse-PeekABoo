-- Enable RLS on order tables
alter table public.preparation_orders enable row level security;
alter table public.preparation_order_lines enable row level security;
alter table public.picking_orders enable row level security;
alter table public.picking_order_stops enable row level security;

-- DROP existing if any to avoid conflicts
drop policy if exists "Supervisors see all prep orders" on public.preparation_orders;
drop policy if exists "Supervisors see all prep lines" on public.preparation_order_lines;
drop policy if exists "Supervisors see all picking orders" on public.picking_orders;
drop policy if exists "Supervisors see all picking stops" on public.picking_order_stops;

-- Preparation Orders
create policy "Supervisors see all prep orders" on public.preparation_orders
    for all using (
        exists (
            select 1 from public.utilisateurs
            where id_utilisateur = auth.uid() and role in ('SUPERVISOR', 'ADMIN')
        )
    );

-- Preparation Order Lines
create policy "Supervisors see all prep lines" on public.preparation_order_lines
    for all using (
        exists (
            select 1 from public.utilisateurs
            where id_utilisateur = auth.uid() and role in ('SUPERVISOR', 'ADMIN')
        )
    );

-- Picking Orders (Update/Re-add for consistency)
create policy "Supervisors see all picking orders" on public.picking_orders
    for all using (
        exists (
            select 1 from public.utilisateurs
            where id_utilisateur = auth.uid() and role in ('SUPERVISOR', 'ADMIN')
        )
    );

-- Picking Order Stops
create policy "Supervisors see all picking stops" on public.picking_order_stops
    for all using (
        exists (
            select 1 from public.utilisateurs
            where id_utilisateur = auth.uid() and role in ('SUPERVISOR', 'ADMIN')
        )
    );
