-- Schema Database per l'applicazione Eventi
-- Questo schema deve essere eseguito su Supabase

-- Estensioni necessarie
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABELLA PROFILES (estende auth.users con informazioni custom)
-- =====================================================
CREATE TABLE public.profiles (
  id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  full_name text,
  avatar_url text,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT profiles_pkey PRIMARY KEY (id)
);

-- Trigger per creare automaticamente un profilo quando si registra un utente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- TABELLA EVENTS (eventi)
-- =====================================================
CREATE TABLE public.events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  location text,
  event_date date NOT NULL,
  start_event_time time without time zone NOT NULL, -- Ora inizio evento
  end_event_time time without time zone, -- Ora fine evento (opzionale)
  cover_image text, -- URL dell'immagine di copertina
  cover_video text, -- URL del video di copertina (alternativo all'immagine)
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  is_published boolean NOT NULL DEFAULT true, -- Permette agli admin di salvare bozze
  max_participants integer, -- Numero massimo di partecipanti (opzionale)
  category text, -- Categoria evento (es: "Concerto", "Sport", "Cultura")
  contact_phone text, -- Numero di telefono per info/prenotazioni
  price decimal(10,2), -- Prezzo dell'evento (opzionale)
  booking_deadline date, -- Data limite per le prenotazioni
  bookings_enabled boolean NOT NULL DEFAULT true, -- Permette di abilitare/disabilitare prenotazioni
  CONSTRAINT events_pkey PRIMARY KEY (id)
);

-- Indici per migliorare le performance
CREATE INDEX idx_events_date ON public.events(event_date);
CREATE INDEX idx_events_created_by ON public.events(created_by);
CREATE INDEX idx_events_category ON public.events(category);

-- =====================================================
-- TABELLA USER_EVENTS (relazione utenti-eventi per favoriti/partecipazioni)
-- =====================================================
CREATE TABLE public.user_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  is_favorite boolean NOT NULL DEFAULT false, -- L'utente ha messo il preferito
  is_participating boolean NOT NULL DEFAULT false, -- L'utente partecipa
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT user_events_pkey PRIMARY KEY (id),
  CONSTRAINT user_events_unique UNIQUE (user_id, event_id)
);

CREATE INDEX idx_user_events_user ON public.user_events(user_id);
CREATE INDEX idx_user_events_event ON public.user_events(event_id);

-- =====================================================
-- TABELLA BOOKINGS (prenotazioni eventi)
-- =====================================================
CREATE TABLE public.bookings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_unique UNIQUE (user_id, event_id) -- Un utente può prenotare un evento una sola volta
);

CREATE INDEX idx_bookings_user ON public.bookings(user_id);
CREATE INDEX idx_bookings_event ON public.bookings(event_id);

-- =====================================================
-- TABELLA NOTIFICATIONS (notifiche)
-- =====================================================
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id uuid REFERENCES public.events(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL CHECK (type IN ('event_reminder', 'event_update', 'event_cancelled', 'new_event', 'system')),
  is_read boolean NOT NULL DEFAULT false,
  scheduled_for timestamp with time zone, -- Quando la notifica deve essere inviata
  sent_at timestamp with time zone, -- Quando è stata effettivamente inviata
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT notifications_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_read ON public.notifications(user_id, is_read);
CREATE INDEX idx_notifications_scheduled ON public.notifications(scheduled_for) WHERE sent_at IS NULL;

-- =====================================================
-- TABELLA EVENT_CATEGORIES (categorie eventi)
-- =====================================================
CREATE TABLE public.event_categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  icon text, -- Nome dell'icona Material
  color text, -- Colore esadecimale
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT event_categories_pkey PRIMARY KEY (id)
);

-- Inserimento categorie di default
INSERT INTO public.event_categories (name, icon, color) VALUES
  ('Musica', 'music_note', '#FF6B9D'),
  ('Sport', 'sports_soccer', '#00C9FF'),
  ('Cultura', 'museum', '#6B4CE6'),
  ('Cibo', 'restaurant', '#FFA06B'),
  ('Tecnologia', 'computer', '#4776E6'),
  ('Arte', 'palette', '#FF416C'),
  ('Festival', 'celebration', '#92FE9D'),
  ('Altro', 'event', '#9B6EE8');

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Abilita RLS su tutte le tabelle
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_categories ENABLE ROW LEVEL SECURITY;

-- PROFILES: tutti possono vedere, solo l'utente può modificare il proprio profilo
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- EVENTS: tutti possono vedere eventi pubblicati, solo admin possono creare/modificare/eliminare
CREATE POLICY "Published events are viewable by everyone"
  ON public.events FOR SELECT
  USING (is_published = true OR auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

CREATE POLICY "Admins can insert events"
  ON public.events FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

CREATE POLICY "Admins can update events"
  ON public.events FOR UPDATE
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

CREATE POLICY "Admins can delete events"
  ON public.events FOR DELETE
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- USER_EVENTS: gli utenti possono gestire solo i propri favoriti/partecipazioni
CREATE POLICY "Users can view their own user_events"
  ON public.user_events FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own user_events"
  ON public.user_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own user_events"
  ON public.user_events FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own user_events"
  ON public.user_events FOR DELETE
  USING (auth.uid() = user_id);

-- BOOKINGS: gli utenti possono gestire le proprie prenotazioni, admin possono vedere tutte
CREATE POLICY "Users can view their own bookings"
  ON public.bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all bookings"
  ON public.bookings FOR SELECT
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

CREATE POLICY "Users can create their own bookings"
  ON public.bookings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bookings"
  ON public.bookings FOR DELETE
  USING (auth.uid() = user_id);

-- NOTIFICATIONS: gli utenti possono vedere e aggiornare solo le proprie notifiche
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- EVENT_CATEGORIES: tutti possono vedere, solo admin possono modificare
CREATE POLICY "Categories are viewable by everyone"
  ON public.event_categories FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage categories"
  ON public.event_categories FOR ALL
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- =====================================================
-- FUNCTIONS UTILI
-- =====================================================

-- Funzione per ottenere il ruolo dell'utente corrente
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Funzione per verificare se l'utente è admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
$$ LANGUAGE sql SECURITY DEFINER;

-- Trigger per aggiornare updated_at automaticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
