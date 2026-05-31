# DTrade Terminal — Supabase Database Schema Documentation

This document explains the database structure, storage requirements, security rules, and triggers required to run the DTrade terminal application. You can share this file directly with your Team Lead (TL) to deploy on your Supabase instance.

---

## Table of Contents
1. [Overview](#1-overview)
2. [Database Schema (7 Tables)](#2-database-schema-7-tables)
3. [Row Level Security (RLS) Policies](#3-row-level-security-rls-policies)
4. [Storage Bucket (Proof of Transaction)](#4-storage-bucket-proof-of-transaction)
5. [Automated Triggers](#5-automated-triggers)
6. [Complete Database Initialization Script](#6-complete-database-initialization-script)

---

## 1. Overview
The DTrade Flutter application uses Supabase for user authentication, real-time data tracking, and image storage. To prevent errors during paper trading, billing, audits, and support operations, the database requires **7 tables**, **1 storage bucket**, and **1 database trigger**.

### 1.1 App Feature Mapping
To help your Team Lead (TL) understand how the Flutter app features correspond to the backend:

| App Feature | Supabase Table / Bucket | Backend Service | Description |
| :--- | :--- | :--- | :--- |
| **Profile** | `profiles` | `SupabaseAuthService` | Stores user metadata like full name, synced via user trigger. |
| **Plan** | `subscriptions` | `BillingService` | Tracks user membership level (e.g. Free `ZERO` vs Premium plans). |
| **Payment Details** | `payment_history` | `BillingService` | Stores transactional metadata when purchasing plans. |
| **History** | `payment_history` | `BillingService` | Logs user invoice records and payment transactions list. |
| **Verify** | `verifications` & bucket `verifications` | `BillingService` | Audits offline transaction IDs (UTRs) and receipt image uploads. |
| **Support & Tickets** | `support_tickets` | `SupportService` | Tracks user-submitted support inquiries and statuses. |
| **Community** | `ticket_messages` | `CommunityService` | Streams live announcements and forum entries to users. |
| **Notify** | External (WebSockets / AI REST API) | `SocketService` / `IntelligenceService` | Listens to socket events (`notifications_new`) and gets AI-driven alerts. |

---

## 2. Database Schema (7 Tables)

### A. `profiles`
* **Purpose**: Holds additional metadata (like the user's name) linked directly to the Supabase Auth system.
* **Columns**:
  * `id` (`UUID`, Primary Key): References the authenticated user (`auth.users.id`).
  * `email` (`TEXT`): User's primary email address.
  * `full_name` (`TEXT`): Display name.
  * `updated_at` (`TIMESTAMPTZ`): Last profile modification timestamp.

### B. `subscriptions`
* **Purpose**: Tracks active membership tiers (like Free `ZERO` vs Premium accounts).
* **Columns**:
  * `id` (`UUID`, Primary Key)
  * `user_id` (`UUID`, Unique): References the user profile. Each user has exactly one subscription status.
  * `plan_name` (`TEXT`): The active plan name (defaults to `ZERO`).
  * `status` (`TEXT`): The status of the plan (defaults to `ACTIVE`).
  * `expiry_date` (`TEXT`): Plan expiration date.
  * `audit_id` (`TEXT`): Administrative reference code (defaults to `DTC-46731`).
  * `updated_at` (`TIMESTAMPTZ`)

### C. `trade`
* **Purpose**: Records simulated execution history for paper trading.
* **Columns**:
  * `id` (`UUID`, Primary Key)
  * `user_id` (`UUID`): References the user.
  * `symbol` (`TEXT`): Asset pair traded (e.g. `EUR/USD`, `BTC/USD`).
  * `type` (`TEXT`): Direction (`BUY` or `SELL`).
  * `amount` (`DOUBLE PRECISION`): Lot size (e.g., `0.1`, `1.0`).
  * `price` (`DOUBLE PRECISION`): Entry price at execution.
  * `created_at` (`TIMESTAMPTZ`)

### D. `support_tickets`
* **Purpose**: Logs customer help desk inquiries created in the help console.
* **Columns**:
  * `id` (`UUID`, Primary Key)
  * `user_id` (`UUID`): References the user.
  * `subject` (`TEXT`): Short summary of the issue.
  * `category` (`TEXT`): The ticket department (e.g. `PAYMENT`, `TRADING`, `TECHNICAL`).
  * `description` (`TEXT`): Detailed explanation from the user.
  * `status` (`TEXT`): Current ticket status (defaults to `OPEN`).
  * `created_at` (`TIMESTAMPTZ`)

### E. `ticket_messages`
* **Purpose**: Stores forum announcements and messaging history for help desk threads.
* **Columns**:
  * `id` (`UUID`, Primary Key)
  * `user_id` (`UUID`): References the sender.
  * `title` (`TEXT`): Header notice.
  * `content` (`TEXT`): Text content.
  * `type` (`TEXT`): Type classification (defaults to `all`).
  * `created_at` (`TIMESTAMPTZ`)

### F. `payment_history`
* **Purpose**: Audits premium plan billing and transaction invoices.
* **Columns**:
  * `id` (`UUID`, Primary Key)
  * `user_id` (`UUID`): References the payer.
  * `plan_name` (`TEXT`): Plan name.
  * `amount` (`TEXT`): Price paid.
  * `payment_method` (`TEXT`): Method used (e.g. `STRIPE`, `PAYPAL`).
  * `status` (`TEXT`): Transaction state (defaults to `PENDING`).
  * `created_at` (`TIMESTAMPTZ`)

### G. `verifications`
* **Purpose**: Audits offline payment verification records (Bank transfer/Crypto transactions) waiting for admin approval.
* **Columns**:
  * `id` (`UUID`, Primary Key)
  * `user_id` (`UUID`): References the user submitting proof.
  * `method` (`TEXT`): Selected payment method.
  * `amount` (`TEXT`): Total amount paid.
  * `utr` (`TEXT`): The Transaction Hash / UTR reference number.
  * `payment_date` (`TEXT`): Inputted payment date.
  * `notes` (`TEXT`): Optional user comment.
  * `status` (`TEXT`): Verification status (defaults to `UNDER REVIEW`).
  * `image_url` (`TEXT`): URL to the uploaded receipt screenshot inside Supabase Storage.
  * `created_at` (`TIMESTAMPTZ`)

---

## 3. Row Level Security (RLS) Policies
By default, Row Level Security is **enabled** on all tables. This guarantees that standard users **cannot view or modify other users' data**.

* **Rule Pattern**:
  * `SELECT` queries check if `auth.uid() = user_id`.
  * `INSERT`/`UPDATE` operations validate `auth.uid() = user_id` before saving.
  * `ticket_messages` allows public read access (`SELECT true`) so all users can view announcements.

---

## 4. Storage Bucket (Proof of Transaction)
The application allows users to upload transaction receipts (up to 5MB) from their gallery.
* **Bucket ID**: `verifications`
* **Visibility**: `Public` (Allows generating public URLs for the admins to review images).
* **Insert Policy**: Authenticated users only (`authenticated` role check).
* **Select Policy**: Public read (`public` role check).

---

## 5. Automated Triggers
To prevent empty query states, a PostgreSQL function and trigger is configured:
1. **Trigger Action**: Fires after a user registers (`auth.users` insert).
2. **Function Details**:
   * Creates a matching row inside `public.profiles` with the user's details.
   * Auto-assigns the user to a free `ZERO` tier subscription inside `public.subscriptions` with an auto-generated transaction ID.

---

## 6. Complete Database Initialization Script

Paste the following script into the **Supabase SQL Editor**:

```sql
-- Enable UUID generator extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------
-- A. CREATE TABLES
-- ----------------------------------------------------

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    plan_name TEXT DEFAULT 'ZERO' NOT NULL,
    status TEXT DEFAULT 'ACTIVE' NOT NULL,
    expiry_date TEXT,
    audit_id TEXT DEFAULT 'DTC-46731' NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.trade (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    symbol TEXT NOT NULL,
    type TEXT NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    price DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    subject TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'OPEN' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.ticket_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    type TEXT DEFAULT 'all' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.payment_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plan_name TEXT NOT NULL,
    amount TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    status TEXT DEFAULT 'PENDING' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

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

-- ----------------------------------------------------
-- B. ENABLE RLS
-- ----------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trade ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifications ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------
-- C. RLS POLICIES
-- ----------------------------------------------------
CREATE POLICY "Allow users to view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow users to update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Allow users to view own subscription" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Allow users to view own trades" ON public.trade FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow users to insert own trades" ON public.trade FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to view own tickets" ON public.support_tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow users to insert own tickets" ON public.support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow public select on ticket_messages" ON public.ticket_messages FOR SELECT USING (true);
CREATE POLICY "Allow authenticated insert on ticket_messages" ON public.ticket_messages FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to view own payment history" ON public.payment_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow users to insert own payment history" ON public.payment_history FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to view own verifications" ON public.verifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow users to insert own verifications" ON public.verifications FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------
-- D. STORAGE BUCKET CONFIGURATION
-- ----------------------------------------------------
INSERT INTO storage.buckets (id, name, public) 
VALUES ('verifications', 'verifications', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Allow authenticated users to upload screenshots" 
ON storage.objects FOR INSERT TO authenticated 
WITH CHECK (bucket_id = 'verifications');

CREATE POLICY "Allow public read access to uploaded screenshots" 
ON storage.objects FOR SELECT TO public 
USING (bucket_id = 'verifications');

-- ----------------------------------------------------
-- E. SIGN-UP TRIGGER SETUP
-- ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert profile
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (new.id, new.email, COALESCE(new.raw_user_meta_data->>'full_name', 'New Trader'));

  -- Insert default ZERO subscription
  INSERT INTO public.subscriptions (user_id, plan_name, status, audit_id)
  VALUES (new.id, 'ZERO', 'ACTIVE', 'DTC-' || floor(random() * 90000 + 10000)::text);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```
