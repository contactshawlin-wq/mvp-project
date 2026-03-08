# SalesFlow - Automated Sales Follow-Up System

An MVP for automating sales email follow-up sequences with lead management, pipeline tracking, and reply detection.

## Features

- **Lead Management** - Add leads manually or import via CSV. Search, filter, and track status.
- **Email Sequences** - Create multi-step follow-up sequences with configurable delays and template variables.
- **Automated Sending** - Cron-based engine sends emails on schedule through your SMTP server.
- **Reply Detection** - IMAP polling detects replies and auto-pauses sequences.
- **Pipeline Dashboard** - Visual pipeline (New > Contacted > Replied > Won/Lost) with key metrics.

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Styling**: Tailwind CSS
- **Database**: PostgreSQL via Supabase
- **Auth**: Supabase Auth
- **Email**: Nodemailer (user-provided SMTP)
- **Reply Detection**: imapflow (IMAP)
- **Hosting**: Vercel

## Setup

### 1. Supabase Project

1. Create a project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run the contents of `supabase-schema.sql`
3. In Authentication > Settings, enable email/password sign-ups

### 2. Environment Variables

Copy `.env.local` and fill in your Supabase credentials:

```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
CRON_SECRET=any-random-secret-string
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 3. Install & Run

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

### 4. First-Time Setup

1. Sign up for an account
2. Go to **Settings** and configure your SMTP/IMAP credentials
3. Add leads (manually or import `sample-leads.csv`)
4. Create a sequence with email steps
5. Select leads and assign them to a sequence
6. The cron job at `/api/cron/send` handles automated sending

## Cron Endpoints

These run automatically on Vercel (every 15 min) or can be triggered manually:

```bash
# Send due emails
curl -H "Authorization: Bearer YOUR_CRON_SECRET" http://localhost:3000/api/cron/send

# Check for replies
curl -H "Authorization: Bearer YOUR_CRON_SECRET" http://localhost:3000/api/cron/replies
```

## Template Variables

Use these in sequence email subjects and bodies:

| Variable | Description |
|----------|-------------|
| `{{first_name}}` | Lead's first name |
| `{{name}}` | Lead's full name |
| `{{company}}` | Lead's company |
| `{{email}}` | Lead's email |

## Project Structure

```
src/
  app/
    (auth)/          # Login & signup pages
    (app)/           # Authenticated app pages
      dashboard/     # Stats & pipeline view
      leads/         # Lead management
      sequences/     # Sequence builder
      settings/      # SMTP/IMAP configuration
    api/
      cron/send/     # Scheduled email sender
      cron/replies/  # Reply detection
      email/test/    # Test email endpoint
      leads/assign/  # Assign leads to sequence
  components/        # Reusable UI components
  lib/               # Utilities, types, Supabase clients
```
