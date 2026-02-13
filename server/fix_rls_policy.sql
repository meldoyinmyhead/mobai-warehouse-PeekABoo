-- FIX: Resolve Infinite Recursion Error (42P17)
-- We need to drop the old policies first to clean up the recursion.

DROP POLICY IF EXISTS "Users can view their own profile" ON public.utilisateurs;
DROP POLICY IF EXISTS "Supervisors/Admins can view all profiles" ON public.utilisateurs;

-- 1. Simple policy: Every authenticated user can view ONLY their own profile.
-- This does NOT cause recursion because it uses auth.uid() directly.
CREATE POLICY "Users can view their own profile" 
ON public.utilisateurs 
FOR SELECT 
TO authenticated 
USING (auth.uid() = id_utilisateur);
