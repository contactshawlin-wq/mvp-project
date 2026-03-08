-- Users table is handled by Supabase Auth

-- SMTP/IMAP settings per user
CREATE TABLE IF NOT EXISTS smtp_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  smtp_host TEXT NOT NULL DEFAULT '',
  smtp_port INTEGER NOT NULL DEFAULT 587,
  smtp_user TEXT NOT NULL DEFAULT '',
  smtp_pass TEXT NOT NULL DEFAULT '',
  imap_host TEXT NOT NULL DEFAULT '',
  imap_port INTEGER NOT NULL DEFAULT 993,
  imap_user TEXT NOT NULL DEFAULT '',
  imap_pass TEXT NOT NULL DEFAULT '',
  from_name TEXT NOT NULL DEFAULT '',
  from_email TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);

-- Sequences
CREATE TABLE IF NOT EXISTS sequences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Sequence steps
CREATE TABLE IF NOT EXISTS sequence_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sequence_id UUID NOT NULL REFERENCES sequences(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL,
  delay_days INTEGER NOT NULL DEFAULT 1,
  subject_template TEXT NOT NULL DEFAULT '',
  body_template TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Leads
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  company TEXT,
  source TEXT NOT NULL DEFAULT 'manual',
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'replied', 'won', 'lost')),
  assigned_sequence_id UUID REFERENCES sequences(id) ON DELETE SET NULL,
  current_step INTEGER NOT NULL DEFAULT 0,
  next_send_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Email logs
CREATE TABLE IF NOT EXISTS email_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  sequence_step_id UUID NOT NULL REFERENCES sequence_steps(id) ON DELETE CASCADE,
  sent_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  replied_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'opened', 'replied', 'bounced', 'failed')),
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_leads_user_status ON leads(user_id, status);
CREATE INDEX IF NOT EXISTS idx_leads_next_send ON leads(next_send_at) WHERE next_send_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_email_logs_lead ON email_logs(lead_id);
CREATE INDEX IF NOT EXISTS idx_sequence_steps_sequence ON sequence_steps(sequence_id, step_order);

-- Row Level Security
ALTER TABLE smtp_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE sequence_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own smtp_settings" ON smtp_settings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own sequences" ON sequences
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own sequence_steps" ON sequence_steps
  FOR ALL USING (
    sequence_id IN (SELECT id FROM sequences WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can manage own leads" ON leads
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own email_logs" ON email_logs
  FOR ALL USING (
    lead_id IN (SELECT id FROM leads WHERE user_id = auth.uid())
  );
