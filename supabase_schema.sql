-- =========================================================================
-- DTrade Terminal — Full Database Schema Setup
-- =========================================================================
-- Instructions:
-- Paste this entire script into the Supabase SQL Editor and run it. 
-- This script creates the 7 required tables, enables Row Level Security (RLS),
-- sets up policies, initializes the 'verifications' storage bucket, and 
-- creates automatic sign-up triggers.
-- =========================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================================================================
-- PART 1: TABLE CREATIONS
-- =========================================================================

-- 1. profiles Table
-- Stores user identity data linked directly to auth.users.
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
COMMENT ON TABLE public.profiles IS 'Stores user profile metadata synced from auth.users.';

-- 2. subscriptions Table
-- Tracks active subscription tiers (e.g. ZERO, PRO, etc.) and audit identifiers.
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    plan_name TEXT DEFAULT 'ZERO' NOT NULL,
    status TEXT DEFAULT 'ACTIVE' NOT NULL,
    expiry_date TEXT,
    audit_id TEXT DEFAULT 'DTC-46731' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.subscriptions IS 'Stores subscription plans and validation status for each user.';

-- 3. trade Table
-- Records executing history for Paper Trading simulation.
CREATE TABLE IF NOT EXISTS public.trade (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    symbol TEXT NOT NULL,
    type TEXT NOT NULL, -- e.g. BUY, SELL
    amount DOUBLE PRECISION NOT NULL,
    price DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.trade IS 'Tracks virtual/simulated executions placed by users.';

-- 4. support_tickets Table
-- Contains customer tickets raised from the Help/Support panel.
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    subject TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'OPEN' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.support_tickets IS 'Stores user-submitted help desk issues and status logs.';

-- 5. ticket_messages Table
-- Logs communication history and community/announcement alerts.
CREATE TABLE IF NOT EXISTS public.ticket_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    type TEXT DEFAULT 'all' NOT NULL, -- e.g., SUPPORT, ANNOUNCEMENT
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.ticket_messages IS 'Used for ticket threads, announcements, and direct notices.';

-- 6. payment_history Table
-- Audits payment logs and premium plan purchase transactions.
CREATE TABLE IF NOT EXISTS public.payment_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plan_name TEXT NOT NULL,
    amount TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    status TEXT DEFAULT 'PENDING' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.payment_history IS 'Audits transaction payment status logs.';

-- 7. verifications Table
-- Holds payment verification records submitted for TL approval (UTR, payment date, Notes).
CREATE TABLE IF NOT EXISTS public.verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    method TEXT NOT NULL,
    amount TEXT NOT NULL,
    utr TEXT NOT NULL,
    payment_date TEXT NOT NULL,
    notes TEXT,
    status TEXT DEFAULT 'UNDER REVIEW' NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.verifications IS 'Contains transaction hashes and image links for payment audit approval.';

-- =========================================================================
-- PART 2: ROW LEVEL SECURITY (RLS)
-- =========================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trade ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifications ENABLE ROW LEVEL SECURITY;

-- =========================================================================
-- PART 3: SECURITY POLICIES (Access Controls)
-- =========================================================================

-- Profiles Policies
CREATE POLICY "Allow users to view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow users to update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Subscriptions Policies
CREATE POLICY "Allow users to view own subscription" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);

-- Trades Policies
CREATE POLICY "Allow users to view own trades" ON public.trade FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow users to insert own trades" ON public.trade FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Support Tickets Policies
CREATE POLICY "Allow users to view own tickets" ON public.support_tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow users to insert own tickets" ON public.support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Ticket Messages Policies (Public select is required for streaming community announcements)
CREATE POLICY "Allow public select on ticket_messages" ON public.ticket_messages FOR SELECT USING (true);
CREATE POLICY "Allow authenticated insert on ticket_messages" ON public.ticket_messages FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Payment History Policies
CREATE POLICY "Allow users to view own payment history" ON public.payment_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow users to insert own payment history" ON public.payment_history FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Verifications Policies
CREATE POLICY "Allow users to view own verifications" ON public.verifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow users to insert own verifications" ON public.verifications FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =========================================================================
-- PART 4: STORAGE BUCKET CONFIGURATION (For screenshots)
-- =========================================================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('verifications', 'verifications', true)
ON CONFLICT (id) DO NOTHING;

-- Allows authenticated users to write image attachments
CREATE POLICY "Allow authenticated users to upload screenshots" 
ON storage.objects FOR INSERT TO authenticated 
WITH CHECK (bucket_id = 'verifications');

-- Allows public read access so the admin can audit payment verifications
CREATE POLICY "Allow public read access to uploaded screenshots" 
ON storage.objects FOR SELECT TO public 
USING (bucket_id = 'verifications');

-- =========================================================================
-- PART 5: USER CREATION AUTOMATION TRIGGERS
-- =========================================================================
-- Runs automatically on user signup (auth.users inserts).
-- Automatically populates their profiles row and active ZERO subscription tier.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create Profile
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (new.id, new.email, COALESCE(new.raw_user_meta_data->>'full_name', 'New Trader'));

  -- Create Default ZERO Subscription (Unique code DTC-XXXXX generated)
  INSERT INTO public.subscriptions (user_id, plan_name, status, audit_id)
  VALUES (new.id, 'ZERO', 'ACTIVE', 'DTC-' || floor(random() * 90000 + 10000)::text);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
