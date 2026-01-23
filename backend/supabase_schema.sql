-- -----------------------------------------------------------------------------
-- 1. SETUP & EXTENSIONS
-- -----------------------------------------------------------------------------
-- Enable UUID extension for generating unique IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable moddatetime for automatic updated_at maintenance
CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

-- -----------------------------------------------------------------------------
-- 2. TABLES
-- -----------------------------------------------------------------------------

-- Table: profiles
-- Stores user profile data. Linked to auth.users.
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  business_name TEXT,
  owner_name TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to auto-update updated_at on profiles
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

-- Table: transactions
-- Stores all income and expense records.
CREATE TABLE transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  amount BIGINT NOT NULL CHECK (amount > 0),
  category TEXT,
  note TEXT,
  effective_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 3. SECURITY (Row Level Security)
-- -----------------------------------------------------------------------------

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Policies for PROFILES
CREATE POLICY "Users can view their own profile" 
ON profiles FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
ON profiles FOR UPDATE 
USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" 
ON profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Policies for TRANSACTIONS
-- Policy: Select (GET /history)
CREATE POLICY "Users can view their own transactions" 
ON transactions FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Insert (POST /add_income, POST /add_expense)
CREATE POLICY "Users can insert their own transactions" 
ON transactions FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Policy: Update (If needed for future editing)
CREATE POLICY "Users can update their own transactions" 
ON transactions FOR UPDATE 
USING (auth.uid() = user_id);

-- Policy: Delete (If needed for future deletion)
CREATE POLICY "Users can delete their own transactions" 
ON transactions FOR DELETE 
USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 4. PERFORMANCE & INDEXES
-- -----------------------------------------------------------------------------

-- Index for filtering by user and sorting by created_at (Pagination efficiency)
-- Supports: .order('created_at', { ascending: false })
CREATE INDEX idx_transactions_user_created 
ON transactions(user_id, created_at DESC);

-- Index for filtering by user and effective_date (Period filtering: today, week, month)
-- Supports: .gte('effective_date', ...).lte('effective_date', ...)
CREATE INDEX idx_transactions_user_date 
ON transactions(user_id, effective_date DESC);

-- -----------------------------------------------------------------------------
-- 6. HELPER FUNCTIONS & SEEDING (FOR TESTING)
-- -----------------------------------------------------------------------------

-- Function: seed_my_data()
-- Purpose: Quickly populates the current user's account with dummy data for testing.
-- Usage: Run `SELECT seed_my_data();` in Supabase SQL Editor after logging in (or via API).
CREATE OR REPLACE FUNCTION seed_my_data()
RETURNS void AS $$
DECLARE
  my_id UUID;
BEGIN
  -- Get current user ID
  my_id := auth.uid();
  
  IF my_id IS NULL THEN
    RAISE EXCEPTION 'You must be logged in to seed data.';
  END IF;

  -- 1. Create Profile if not exists
  INSERT INTO profiles (id, business_name, owner_name)
  VALUES (my_id, 'Warung Contoh', 'Budi Santoso')
  ON CONFLICT (id) DO NOTHING;

  -- 2. Insert Dummy Transactions (History)
  INSERT INTO transactions (user_id, type, amount, category, note, effective_date, created_at)
  VALUES
    -- Income Today
    (my_id, 'income', 150000, 'sales', 'Jual Nasi Uduk Pagi', NOW(), NOW()),
    (my_id, 'income', 75000, 'sales', 'Jual Gorengan', NOW() - INTERVAL '2 hours', NOW()),
    
    -- Expense Today
    (my_id, 'expense', 50000, 'material', 'Beli Beras', NOW() - INTERVAL '5 hours', NOW()),

    -- Income Yesterday
    (my_id, 'income', 500000, 'sales', 'Omzet Kemarin Full', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

    -- Expense Last Week
    (my_id, 'expense', 1200000, 'operational', 'Bayar Listrik', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days');

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- 7. API MAPPING DOCUMENTATION (Comments)
-- -----------------------------------------------------------------------------
/*
  MAPPING ENDPOINTS TO SUPABASE JS CLIENT:

  1. GET /history
     const { data, error } = await supabase
       .from('transactions')
       .select('*')
       .order('created_at', { ascending: false })
       .range(offset, offset + limit - 1);
       // Optional: Add .gte('effective_date', start).lte('effective_date', end) for period filter

  2. POST /add_income
     const { data, error } = await supabase
       .from('transactions')
       .insert({
         user_id: supabase.auth.user().id,
         type: 'income',
         amount: 150000,
         category: 'sales',
         note: 'Jual Dimsum',
         effective_date: new Date()
       })
       .select()
       .single();

  3. POST /add_expense
     const { data, error } = await supabase
       .from('transactions')
       .insert({
         user_id: supabase.auth.user().id,
         type: 'expense',
         amount: 50000,
         category: 'material',
         note: 'Beli Tepung',
         effective_date: new Date()
       })
       .select()
       .single();

  4. GET /profile
     const { data, error } = await supabase
       .from('profiles')
       .select('*')
       .single();
*/