-- Create Signalements Table for Flag Management
create table if not exists public.signalements (
    id uuid default uuid_generate_v4() primary key,
    type_signalement varchar(50) not null, -- DAMAGED, QUANTITY, LOCATION, OTHER
    priorite varchar(20) default 'MEDIUM', -- HIGH, MEDIUM, LOW
    description text not null,
    id_emplacement uuid references public.emplacements(id_emplacement),
    id_utilisateur_rapporteur uuid references public.utilisateurs(id_utilisateur),
    statut varchar(20) default 'PENDING', -- PENDING, IN_PROGRESS, RESOLVED
    reference_tache varchar(50), -- Optional reference to order/task
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.signalements enable row level security;

-- Policy: Anyone can create a signalement
create policy "Anyone can create signalements" on public.signalements
    for insert with check (true);

-- Policy: Supervisors and Admins can see all signalements
create policy "Supervisors see all signalements" on public.signalements
    for select using (
        exists (
            select 1 from public.utilisateurs
            where id_utilisateur = auth.uid() and role in ('SUPERVISOR', 'ADMIN')
        )
    );

-- Policy: Employees see their own reported signalements
create policy "Employees see own signalements" on public.signalements
    for select using (id_utilisateur_rapporteur = auth.uid());
