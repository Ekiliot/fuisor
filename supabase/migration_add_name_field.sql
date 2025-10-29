-- Migration: Add name field to profiles table
-- This migration adds a 'name' field to the profiles table

-- Add name column to profiles table
ALTER TABLE profiles 
ADD COLUMN name TEXT;

-- Update existing profiles to have name = username (temporary)
UPDATE profiles 
SET name = username 
WHERE name IS NULL;

-- Make name column NOT NULL after updating existing records
ALTER TABLE profiles 
ALTER COLUMN name SET NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN profiles.name IS 'User display name (different from username)';
