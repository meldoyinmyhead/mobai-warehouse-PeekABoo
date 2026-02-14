-- Allow supervisors to see basic info of all users
drop policy if exists "Supervisors see all users" on public.utilisateurs;
create policy "Supervisors see all users" on public.utilisateurs
    for select using (
        exists (
            select 1 from public.utilisateurs
            where id_utilisateur = auth.uid() and role in ('SUPERVISOR', 'ADMIN')
        )
    );

-- Also allow users to see themselves
drop policy if exists "Users see themselves" on public.utilisateurs;
create policy "Users see themselves" on public.utilisateurs
    for select using (id_utilisateur = auth.uid());

-- Ensure entrepots is visible (usually it's not RLS enabled in my script yet, but just in case)
alter table public.entrepots enable row level security;
drop policy if exists "Everyone can see warehouses" on public.entrepots;
create policy "Everyone can see warehouses" on public.entrepots
    for select using (true);
