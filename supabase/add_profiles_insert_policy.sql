-- Add missing INSERT policy for profiles table
-- This policy allows users to create their own profile during signup

CREATE POLICY "Users can insert own profile."
  ON profiles FOR INSERT
  WITH CHECK ( auth.uid() = id );
