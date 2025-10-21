-- Create shared_medical_history table for QR code sharing
CREATE TABLE IF NOT EXISTS public.shared_medical_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    share_code TEXT NOT NULL UNIQUE,
    medical_history_ids TEXT[] NOT NULL DEFAULT '{}',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create index on share_code for fast lookups
CREATE INDEX IF NOT EXISTS idx_shared_medical_history_share_code
ON public.shared_medical_history(share_code);

-- Create index on user_id for user's active shares
CREATE INDEX IF NOT EXISTS idx_shared_medical_history_user_id
ON public.shared_medical_history(user_id);

-- Create index on expires_at for cleanup queries
CREATE INDEX IF NOT EXISTS idx_shared_medical_history_expires_at
ON public.shared_medical_history(expires_at);

-- Enable Row Level Security
ALTER TABLE public.shared_medical_history ENABLE ROW LEVEL SECURITY;

-- Policy: Users can insert their own shares
CREATE POLICY "Users can create their own shares"
ON public.shared_medical_history
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can view their own shares
CREATE POLICY "Users can view their own shares"
ON public.shared_medical_history
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Anyone can view shares by share_code (for doctors scanning QR)
CREATE POLICY "Anyone can view shares by share_code"
ON public.shared_medical_history
FOR SELECT
USING (true);

-- Policy: Users can delete their own shares
CREATE POLICY "Users can delete their own shares"
ON public.shared_medical_history
FOR DELETE
USING (auth.uid() = user_id);

-- Policy: Users can update their own shares
CREATE POLICY "Users can update their own shares"
ON public.shared_medical_history
FOR UPDATE
USING (auth.uid() = user_id);

-- Add comment to table
COMMENT ON TABLE public.shared_medical_history IS 'Stores temporary sharing sessions for medical history via QR codes';
