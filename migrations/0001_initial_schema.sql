-- Ooty Cabz booking management schema
-- Apply this migration to the Cloudflare D1 database: ootycabz-bookings.
-- Safe to run once; all objects use IF NOT EXISTS.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS drivers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  licence_number TEXT,
  notes TEXT,
  active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS vehicles (
  id TEXT PRIMARY KEY,
  vehicle_type TEXT NOT NULL,
  make_model TEXT,
  registration_number TEXT NOT NULL UNIQUE,
  seating_capacity INTEGER NOT NULL DEFAULT 4 CHECK (seating_capacity > 0),
  active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS bookings (
  id TEXT PRIMARY KEY,
  booking_reference TEXT NOT NULL UNIQUE,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_email TEXT,
  pickup_location TEXT NOT NULL,
  drop_location TEXT NOT NULL,
  travel_date TEXT NOT NULL,
  pickup_time TEXT NOT NULL,
  passengers INTEGER NOT NULL DEFAULT 1 CHECK (passengers > 0),
  vehicle_preference TEXT,
  luggage_details TEXT,
  service_type TEXT,
  special_requests TEXT,
  assigned_driver_id TEXT REFERENCES drivers(id) ON DELETE SET NULL,
  assigned_vehicle_id TEXT REFERENCES vehicles(id) ON DELETE SET NULL,
  quoted_fare_paise INTEGER CHECK (quoted_fare_paise IS NULL OR quoted_fare_paise >= 0),
  advance_paid_paise INTEGER NOT NULL DEFAULT 0 CHECK (advance_paid_paise >= 0),
  payment_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (payment_status IN ('pending','part_paid','paid','refunded','not_required')),
  booking_status TEXT NOT NULL DEFAULT 'new'
    CHECK (booking_status IN ('new','confirmed','driver_assigned','in_progress','completed','cancelled')),
  source TEXT NOT NULL DEFAULT 'website',
  internal_notes TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_bookings_travel_date ON bookings(travel_date);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_bookings_phone ON bookings(customer_phone);
CREATE INDEX IF NOT EXISTS idx_bookings_created_at ON bookings(created_at);

CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY,
  booking_id TEXT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  amount_paise INTEGER NOT NULL CHECK (amount_paise > 0),
  payment_method TEXT,
  payment_reference TEXT,
  payment_status TEXT NOT NULL DEFAULT 'received'
    CHECK (payment_status IN ('pending','received','failed','refunded')),
  paid_at TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id);

-- Password hashes only; never store plaintext admin passwords.
CREATE TABLE IF NOT EXISTS admin_users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  last_login_at TEXT
);

-- Store only hashes of random session tokens, never raw browser tokens.
CREATE TABLE IF NOT EXISTS admin_sessions (
  id TEXT PRIMARY KEY,
  admin_user_id TEXT NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_admin_sessions_expiry ON admin_sessions(expires_at);

CREATE TABLE IF NOT EXISTS booking_activity (
  id TEXT PRIMARY KEY,
  booking_id TEXT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  details TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_booking_activity_booking ON booking_activity(booking_id);
