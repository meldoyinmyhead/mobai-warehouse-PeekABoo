-- Fix for infinite recursion in RLS policies
-- The issue is that querying 'public.utilisateurs' inside a policy on 'public.utilisateurs' triggers the policy again.

-- 1. Create a secure function to get the current user's role without triggering RLS
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER -- Runs with privileges of the creator (bypassing RLS)
SET search_path = public -- Secure search path
STABLE
AS $$
  SELECT role FROM public.utilisateurs WHERE id_utilisateur = auth.uid();
$$;

-- 2. Drop the recursive policy
DROP POLICY IF EXISTS "Supervisors see all users" ON public.utilisateurs;

-- 3. Re-create the policy using the secure function
CREATE POLICY "Supervisors see all users" ON public.utilisateurs
    FOR SELECT USING (
        (SELECT get_my_role()) IN ('SUPERVISOR', 'ADMIN')
        OR
        id_utilisateur = auth.uid() -- Users can always see themselves
    );

-- 4. Also fix other tables that might rely on querying utilisateurs directly in their policies if necessary
-- ensuring they don't trip up. (Preparation orders etc seem fine as they queried auth.uid() directly or used this pattern)
