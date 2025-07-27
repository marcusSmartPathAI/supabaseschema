-- =============================================================================
-- Complete Auto Service Demo Schema
-- Generated: July 27, 2025
-- Includes: Tables, Indexes, Triggers, RLS Policies, Views, Functions
-- =============================================================================

-- Schema Creation
CREATE SCHEMA IF NOT EXISTS auto_service_demo;

-- =============================================================================
-- TABLES
-- =============================================================================

CREATE TABLE auto_service_demo.customers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  phone text UNIQUE CHECK (phone IS NULL OR phone ~~ '+%'::text),
  email text,
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'mdt'::text),
  last_name text,
  CONSTRAINT customers_pkey PRIMARY KEY (id)
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

CREATE TABLE auto_service_demo.personnel (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  role text NOT NULL,
  calendar_email text UNIQUE,
  created_at timestamp without time zone DEFAULT now(),
  last_name text,
  CONSTRAINT personnel_pkey PRIMARY KEY (id)
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
  CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES auto_service_demo.customers(id),
  CONSTRAINT check_appointment_times CHECK (end_time > start_time)
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

CREATE TABLE auto_service_demo.workflow_status (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  workflow_name text NOT NULL,
  status text,
  related_customer uuid DEFAULT gen_random_uuid(),
  CONSTRAINT workflow_status_pkey PRIMARY KEY (id),
  CONSTRAINT workflow_status_related_customer_fkey FOREIGN KEY (related_customer) REFERENCES auto_service_demo.customers(id)
);

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX idx_call_logs_date_customer ON auto_service_demo.call_logs USING btree (call_date, customer_id);
CREATE INDEX idx_call_logs_outcome ON auto_service_demo.call_logs USING btree (call_outcome);
CREATE UNIQUE INDEX unique_customer_phone ON auto_service_demo.customers USING btree (phone);
CREATE UNIQUE INDEX unique_personnel_email ON auto_service_demo.personnel USING btree (calendar_email);
CREATE UNIQUE INDEX unique_bay_name ON auto_service_demo.bays USING btree (name);
CREATE UNIQUE INDEX unique_service_name ON auto_service_demo.services USING btree (name);
CREATE UNIQUE INDEX unique_appointment_service ON auto_service_demo.appointment_services USING btree (appointment_id, service_id);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Phone formatting function (referenced but may need to be created)
CREATE OR REPLACE FUNCTION format_phone_number(phone_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
  -- Basic phone formatting logic - customize as needed
  IF phone_input IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Remove all non-digit characters
  phone_input := regexp_replace(phone_input, '[^0-9]', '', 'g');
  
  -- Add + if not present and format as needed
  IF length(phone_input) = 10 THEN
    RETURN '+1' || phone_input;
  ELSIF length(phone_input) = 11 AND left(phone_input, 1) = '1' THEN
    RETURN '+' || phone_input;
  ELSE
    RETURN '+' || phone_input;
  END IF;
END;
$$;

-- Phone format trigger function
CREATE OR REPLACE FUNCTION public.auto_format_phone_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.phone := format_phone_number(NEW.phone);
  RETURN NEW;
END;
$$;

-- Appointment automation trigger function
CREATE OR REPLACE FUNCTION public.trigger_appointment_automation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  customer_record RECORD;
  appointment_details RECORD;
  automation_actions jsonb;
  business_hours_check boolean;
  days_until_appt integer;
  customer_history_summary jsonb;
  previous_changes integer;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    
    -- Get customer intelligence
    SELECT 
      c.first_name || ' ' || COALESCE(c.last_name, '') as full_name,
      c.phone,
      c.email,
      COUNT(DISTINCT a2.id) as total_appointments,
      COUNT(DISTINCT CASE WHEN a2.status = 'no_show' THEN a2.id END) as no_show_count,
      COUNT(DISTINCT CASE WHEN a2.status = 'completed' THEN a2.id END) as completed_count
    INTO customer_record
    FROM auto_service_demo.customers c
    LEFT JOIN auto_service_demo.appointments a2 ON c.id = a2.customer_id
    WHERE c.id = NEW.customer_id
    GROUP BY c.id, c.first_name, c.last_name, c.phone, c.email;
    
    -- Get appointment context from view (if exists)
    SELECT 
      services_list, bay_name, technician_name, total_quoted_price
    INTO appointment_details
    FROM auto_service_demo.appointment_calendar_view 
    WHERE appointment_id = NEW.id;
    
    -- Business intelligence
    business_hours_check := (
      EXTRACT(DOW FROM NOW()) BETWEEN 1 AND 5 AND
      EXTRACT(HOUR FROM NOW()) BETWEEN 9 AND 18
    );
    
    -- Calculate days until appointment
    days_until_appt := NEW.start_time::date - CURRENT_DATE;
    
    -- Count previous status changes
    SELECT COUNT(*) INTO previous_changes
    FROM auto_service_demo.automation_triggers
    WHERE appointment_id = NEW.id AND trigger_type = 'status_change';
    
    -- Customer tier analysis
    customer_history_summary := json_build_object(
      'total_appointments', COALESCE(customer_record.total_appointments, 0),
      'no_show_count', COALESCE(customer_record.no_show_count, 0),
      'completed_count', COALESCE(customer_record.completed_count, 0),
      'customer_tier', CASE 
        WHEN customer_record.total_appointments >= 10 THEN 'vip'
        WHEN customer_record.total_appointments >= 5 THEN 'regular'
        WHEN customer_record.no_show_count > 2 THEN 'at_risk'
        ELSE 'new'
      END
    );
    
    -- Smart automation decisions based on context
    automation_actions := CASE NEW.status
      WHEN 'no_show' THEN
        json_build_object(
          'primary_action', 'missed_appointment_follow_up',
          'priority', CASE 
            WHEN customer_record.no_show_count >= 2 THEN 'high'
            WHEN appointment_details.total_quoted_price > 200 THEN 'high'
            ELSE 'medium'
          END,
          'delay_minutes', CASE WHEN business_hours_check THEN 30 ELSE 480 END,
          'escalate_to_manager', (customer_record.no_show_count >= 3),
          'offer_discount', (customer_record.total_appointments < 3)
        )
      WHEN 'completed' THEN
        json_build_object(
          'primary_action', 'satisfaction_survey',
          'priority', 'low',
          'delay_minutes', CASE WHEN appointment_details.total_quoted_price > 300 THEN 60 ELSE 240 END,
          'request_review', (customer_record.completed_count >= 3),
          'survey_type', CASE WHEN appointment_details.total_quoted_price > 200 THEN 'detailed' ELSE 'quick' END
        )
      WHEN 'cancelled' THEN
        json_build_object(
          'primary_action', 'reschedule_outreach',
          'priority', CASE WHEN days_until_appt <= 1 THEN 'high' ELSE 'medium' END,
          'delay_minutes', CASE WHEN days_until_appt <= 1 THEN 60 ELSE 1440 END,
          'offer_discount', (customer_record.total_appointments < 3)
        )
      ELSE json_build_object('primary_action', 'log_only')
    END;
    
    -- Insert detailed log
    INSERT INTO auto_service_demo.automation_triggers (
      appointment_id, customer_id, customer_name, customer_phone,
      trigger_type, old_status, new_status, status_changed_by,
      appointment_start_time, appointment_services, appointment_bay, appointment_technician,
      total_appointment_value, automation_actions, business_hours, days_until_appointment,
      previous_status_changes, customer_history, notes
    ) VALUES (
      NEW.id, NEW.customer_id, customer_record.full_name, customer_record.phone,
      'status_change', OLD.status, NEW.status,
      COALESCE(current_setting('app.current_user', true), 'system'),
      NEW.start_time, appointment_details.services_list, appointment_details.bay_name, appointment_details.technician_name,
      appointment_details.total_quoted_price, automation_actions, business_hours_check, days_until_appt,
      previous_changes, customer_history_summary,
      'Intelligent automation triggered'
    );
    
    -- Send notification to external systems
    IF automation_actions->>'primary_action' != 'log_only' THEN
      PERFORM pg_notify('appointment_automation', json_build_object(
        'type', automation_actions->>'primary_action',
        'priority', automation_actions->>'priority',
        'appointment_id', NEW.id,
        'customer_name', customer_record.full_name,
        'customer_phone', customer_record.phone,
        'customer_tier', customer_history_summary->>'customer_tier',
        'automation_config', automation_actions
      )::text);
    END IF;
    
  END IF;
  RETURN NEW;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Log errors but don't fail the update
    INSERT INTO auto_service_demo.automation_triggers (
      appointment_id, trigger_type, old_status, new_status, notes
    ) VALUES (
      NEW.id, 'error', OLD.status, NEW.status, 
      'Error in automation trigger: ' || SQLERRM
    );
    RETURN NEW;
END;
$$;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

CREATE TRIGGER customers_phone_format_trigger 
  BEFORE INSERT OR UPDATE ON auto_service_demo.customers 
  FOR EACH ROW EXECUTE FUNCTION auto_format_phone_trigger();

CREATE TRIGGER appointment_status_automation_trigger 
  AFTER UPDATE ON auto_service_demo.appointments 
  FOR EACH ROW EXECUTE FUNCTION trigger_appointment_automation();

-- =============================================================================
-- VIEWS
-- =============================================================================

CREATE VIEW auto_service_demo.appointment_calendar_view AS
SELECT 
    a.id as appointment_id,
    a.start_time,
    a.end_time,
    a.status,
    a.notes,
    a.booking_source,
    a.created_at,
    a.updated_at,
    
    -- Customer information
    c.first_name || ' ' || COALESCE(c.last_name, '') as customer_name,
    c.phone as customer_phone,
    c.email as customer_email,
    
    -- Bay and technician information
    b.name as bay_name,
    b.type as bay_type,
    p.first_name || ' ' || COALESCE(p.last_name, '') as technician_name,
    p.role as technician_role,
    
    -- Service aggregations
    COALESCE(STRING_AGG(s.name, ', ' ORDER BY aps.order_index), 'No services') as services_list,
    COALESCE(COUNT(aps.id), 0) as service_count,
    COALESCE(SUM(EXTRACT(EPOCH FROM aps.estimated_duration)/60), 0) as total_duration_minutes,
    COALESCE(SUM(aps.quoted_price), 0) as total_quoted_price,
    
    -- Calculated fields
    EXTRACT(EPOCH FROM (a.end_time - a.start_time))/60 as scheduled_duration_minutes,
    DATE(a.start_time) as appointment_date,
    TO_CHAR(a.start_time, 'HH24:MI') as start_time_formatted,
    TO_CHAR(a.end_time, 'HH24:MI') as end_time_formatted,
    
    -- Status indicators
    CASE 
        WHEN a.start_time < NOW() AND a.status = 'scheduled' THEN 'overdue'
        WHEN a.start_time < NOW() + INTERVAL '1 hour' AND a.status = 'scheduled' THEN 'upcoming'
        ELSE a.status
    END as status_indicator

FROM auto_service_demo.appointments a
JOIN auto_service_demo.customers c ON a.customer_id = c.id
LEFT JOIN auto_service_demo.bays b ON a.bay_id = b.id
LEFT JOIN auto_service_demo.personnel p ON a.personnel_id = p.id
LEFT JOIN auto_service_demo.appointment_services aps ON a.id = aps.appointment_id
LEFT JOIN auto_service_demo.services s ON aps.service_id = s.id
GROUP BY 
    a.id, a.start_time, a.end_time, a.status, a.notes, a.booking_source, a.created_at, a.updated_at,
    c.first_name, c.last_name, c.phone, c.email,
    b.name, b.type,
    p.first_name, p.last_name, p.role
ORDER BY a.start_time;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE auto_service_demo.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_service_demo.bays ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_service_demo.call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_service_demo.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_service_demo.personnel ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_service_demo.service_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_service_demo.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_service_demo.workflow_status ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users
CREATE POLICY "Enable insert for authenticated users only" ON auto_service_demo.appointments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable select for authenticated users only" ON auto_service_demo.appointments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable update for authenticated users only" ON auto_service_demo.appointments FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON auto_service_demo.appointments FOR DELETE TO authenticated USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON auto_service_demo.bays FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable select for authenticated users only" ON auto_service_demo.bays FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable update for authenticated users only" ON auto_service_demo.bays FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON auto_service_demo.bays FOR DELETE TO authenticated USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON auto_service_demo.call_logs FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable select for authenticated users only" ON auto_service_demo.call_logs FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable update for authenticated users only" ON auto_service_demo.call_logs FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON auto_service_demo.call_logs FOR DELETE TO authenticated USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON auto_service_demo.customers FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable select for authenticated users only" ON auto_service_demo.customers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable update for authenticated users only" ON auto_service_demo.customers FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON auto_service_demo.customers FOR DELETE TO authenticated USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON auto_service_demo.personnel FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable select for authenticated users only" ON auto_service_demo.personnel FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable update for authenticated users only" ON auto_service_demo.personnel FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON auto_service_demo.personnel FOR DELETE TO authenticated USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON auto_service_demo.service_records FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable select for authenticated users only" ON auto_service_demo.service_records FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable update for authenticated users only" ON auto_service_demo.service_records FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON auto_service_demo.service_records FOR DELETE TO authenticated USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON auto_service_demo.services FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable select for authenticated users only" ON auto_service_demo.services FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable update for authenticated users only" ON auto_service_demo.services FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON auto_service_demo.services FOR DELETE TO authenticated USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON auto_service_demo.workflow_status FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable select for authenticated users only" ON auto_service_demo.workflow_status FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable update for authenticated users only" ON auto_service_demo.workflow_status FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable delete for authenticated users only" ON auto_service_demo.workflow_status FOR DELETE TO authenticated USING (true);

-- =============================================================================
-- GRANTS AND PERMISSIONS
-- =============================================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA auto_service_demo TO authenticated, anon;

-- Grant permissions on tables
GRANT ALL ON ALL TABLES IN SCHEMA auto_service_demo TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA auto_service_demo TO anon;

-- Grant permissions on sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA auto_service_demo TO authenticated;

-- Grant permissions on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auto_service_demo TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;