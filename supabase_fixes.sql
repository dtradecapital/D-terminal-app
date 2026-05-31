-- =========================================================================
-- DTrade Terminal — Supabase RLS Policies Fix Script
-- =========================================================================
-- Instructions:
-- 1. Go to your Supabase Dashboard (https://supabase.com).
-- 2. Open the SQL Editor on the left sidebar.
-- 3. Click "New Query".
-- 4. Paste this entire script into the editor and click "Run".
-- =========================================================================

-- Step 1: Enable Row Level Security (RLS) on the tables
ALTER TABLE public.payment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Step 2: Create INSERT and SELECT policies for payment_submissions
DROP POLICY IF EXISTS "Allow users to view own payment submissions" ON public.payment_submissions;
CREATE POLICY "Allow users to view own payment submissions" 
ON public.payment_submissions FOR SELECT 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow users to insert own payment submissions" ON public.payment_submissions;
CREATE POLICY "Allow users to insert own payment submissions" 
ON public.payment_submissions FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Step 3: Create INSERT and SELECT policies for payments (payment_history)
DROP POLICY IF EXISTS "Allow users to view own payments" ON public.payments;
CREATE POLICY "Allow users to view own payments" 
ON public.payments FOR SELECT 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow users to insert own payments" ON public.payments;
CREATE POLICY "Allow users to insert own payments" 
ON public.payments FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Step 4: Ensure the 'payment_submissions' Storage Bucket exists and has policies
INSERT INTO storage.buckets (id, name, public) 
VALUES ('payment_submissions', 'payment_submissions', true)
ON CONFLICT (id) DO NOTHING;

-- Allows authenticated users to write/upload screenshots
DROP POLICY IF EXISTS "Allow authenticated users to upload screenshots to payment_submissions" ON storage.objects;
CREATE POLICY "Allow authenticated users to upload screenshots to payment_submissions" 
ON storage.objects FOR INSERT TO authenticated 
WITH CHECK (bucket_id = 'payment_submissions');

-- Allows public read access to screenshots
DROP POLICY IF EXISTS "Allow public read access to payment_submissions" ON storage.objects;
CREATE POLICY "Allow public read access to payment_submissions" 
ON storage.objects FOR SELECT TO public 
USING (bucket_id = 'payment_submissions');
