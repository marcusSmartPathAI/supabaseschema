-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE auto_service_demo.appointment_services (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL,
  service_id uuid NOT NULL,
  order_index integer NOT NULL,
  estimated_duration interval,
  quoted_price numeric,
  status text DEFAULT 'pending'::text,
  customer_approved boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT appointment_services_pkey PRIMARY KEY (id),
  CONSTRAINT fk_service FOREIGN KEY (service_id) REFERENCES auto_service_demo.services(id),
  CONSTRAINT fk_appt FOREIGN KEY (appointment_id) REFERENCES auto_service_demo.appointments(id)
);
CREATE TABLE auto_service_demo.appointments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL,
  bay_id uuid,
  personnel_id uuid,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone NOT NULL,
  status text DEFAULT 'scheduled'::text CHECK (status = ANY (ARRAY['scheduled'::text, 'confirmed'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text, 'no_show'::text])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  notes text,
  estimated_duration interval,
  total_quoted_price numeric,
  booking_source text DEFAULT 'retell_ai'::text,
  CONSTRAINT appointments_pkey PRIMARY KEY (id),
  CONSTRAINT fk_personnel FOREIGN KEY (personnel_id) REFERENCES auto_service_demo.personnel(id),
  CONSTRAINT fk_bay FOREIGN KEY (bay_id) REFERENCES auto_service_demo.bays(id),
  CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES auto_service_demo.customers(id)
);
CREATE TABLE auto_service_demo.automation_triggers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  appointment_id uuid,
  customer_id uuid,
  customer_name text,
  customer_phone text,
  trigger_type text NOT NULL,
  old_status text,
  new_status text,
  status_changed_by text,
  appointment_start_time timestamp with time zone,
  appointment_services text,
  appointment_bay text,
  appointment_technician text,
  total_appointment_value numeric,
  automation_actions jsonb,
  automation_sent boolean DEFAULT false,
  automation_sent_at timestamp with time zone,
  retry_count integer DEFAULT 0,
  business_hours boolean,
  days_until_appointment integer,
  previous_status_changes integer,
  customer_history jsonb,
  triggered_at timestamp with time zone DEFAULT now(),
  notes text,
  CONSTRAINT automation_triggers_pkey PRIMARY KEY (id),
  CONSTRAINT fk_automation_appointment FOREIGN KEY (appointment_id) REFERENCES auto_service_demo.appointments(id),
  CONSTRAINT fk_automation_customer FOREIGN KEY (customer_id) REFERENCES auto_service_demo.customers(id)
);
CREATE TABLE auto_service_demo.bays (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  type text NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  equipment text,
  description text,
  is_active boolean,
  CONSTRAINT bays_pkey PRIMARY KEY (id)
);
CREATE TABLE auto_service_demo.call_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid,
  agent_type text,
  call_time timestamp without time zone DEFAULT (now() AT TIME ZONE 'mdt'::text),
  call_status text CHECK ((call_status = ANY (ARRAY['completed'::text, 'missed'::text, 'busy'::text, 'failed'::text])) OR call_status IS NULL),
  transcript text,
  summary text,
  automation_trigger text,
  legacy_call_cost numeric,
  call_duration numeric,
  call_date date,
  call_direction text CHECK ((call_direction = ANY (ARRAY['inbound'::text, 'outbound'::text])) OR call_direction IS NULL),
  call_purpose text,
  call_outcome text,
  lead_id uuid,
  total_call_cost numeric,
  call_duration_seconds integer,
  phone_number text,
  CONSTRAINT call_logs_pkey PRIMARY KEY (id),
  CONSTRAINT fk_call_lead FOREIGN KEY (lead_id) REFERENCES auto_service_demo.leads(id),
  CONSTRAINT call_logs_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES auto_service_demo.customers(id)
);
CREATE TABLE auto_service_demo.customer_preferences (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL,
  preferred_contact_method text DEFAULT 'phone'::text,
  preferred_contact_time text DEFAULT 'business_hours'::text,
  language_preference text DEFAULT 'english'::text,
  do_not_call boolean DEFAULT false,
  CONSTRAINT customer_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT fk_customer_prefs FOREIGN KEY (customer_id) REFERENCES auto_service_demo.customers(id)
);
CREATE TABLE auto_service_demo.customer_vehicles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL,
  make text NOT NULL,
  model text NOT NULL,
  year integer NOT NULL,
  mileage integer,
  last_service_date date,
  next_service_due_date date,
  is_primary boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT customer_vehicles_pkey PRIMARY KEY (id),
  CONSTRAINT fk_vehicle_customer FOREIGN KEY (customer_id) REFERENCES auto_service_demo.customers(id)
);
CREATE TABLE auto_service_demo.customers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  phone text UNIQUE CHECK (phone IS NULL OR phone ~~ '+%'::text),
  email text,
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'mdt'::text),
  last_name text,
  CONSTRAINT customers_pkey PRIMARY KEY (id)
);
CREATE TABLE auto_service_demo.leads (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  phone text NOT NULL,
  email text,
  first_name text,
  last_name text,
  lead_source text DEFAULT 'inbound_call'::text,
  qualification_status text DEFAULT 'new'::text,
  converted_to_customer_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  notes text,
  CONSTRAINT leads_pkey PRIMARY KEY (id)
);
CREATE TABLE auto_service_demo.personnel (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  role text NOT NULL,
  calendar_email text UNIQUE,
  created_at timestamp without time zone DEFAULT now(),
  last_name text,
  CONSTRAINT personnel_pkey PRIMARY KEY (id)
);
CREATE TABLE auto_service_demo.service_records (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid DEFAULT gen_random_uuid(),
  service_details jsonb,
  parts_used jsonb,
  labor_hours real,
  total_cost numeric,
  warranty_applied boolean,
  service_date timestamp with time zone DEFAULT (now() AT TIME ZONE 'mdt'::text),
  service_id uuid,
  CONSTRAINT service_records_pkey PRIMARY KEY (id),
  CONSTRAINT service_records_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES auto_service_demo.customers(id),
  CONSTRAINT service_records_service_id_fkey FOREIGN KEY (service_id) REFERENCES auto_service_demo.services(id)
);
CREATE TABLE auto_service_demo.services (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  estimated_duration interval NOT NULL,
  required_bay_type text NOT NULL,
  base_price numeric DEFAULT 0,
  is_active boolean DEFAULT true,
  CONSTRAINT services_pkey PRIMARY KEY (id)
);
CREATE TABLE auto_service_demo.workflow_status (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  workflow_name text NOT NULL,
  status text,
  related_customer uuid DEFAULT gen_random_uuid(),
  CONSTRAINT workflow_status_pkey PRIMARY KEY (id),
  CONSTRAINT workflow_status_related_customer_fkey FOREIGN KEY (related_customer) REFERENCES auto_service_demo.customers(id)
);