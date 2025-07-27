\# Auto Service Demo - Database Schema



This repository contains the complete database schema for an auto service management system.



\## Database Overview



This schema manages:

\- \*\*Customer Management\*\* - Customer information, vehicles, and preferences

\- \*\*Appointment Scheduling\*\* - Service appointments with bay and personnel assignment

\- \*\*Service Management\*\* - Service catalog, records, and appointment services

\- \*\*Communication\*\* - Call logs and automation triggers

\- \*\*Lead Management\*\* - Lead tracking and conversion



\## Main Tables



\### Core Business Tables

\- `customers` - Customer information and contact details

\- `customer\_vehicles` - Vehicle information for each customer

\- `appointments` - Service appointments with scheduling details

\- `services` - Service catalog with pricing and duration

\- `appointment\_services` - Services assigned to specific appointments



\### Operational Tables

\- `personnel` - Staff members and their roles

\- `bays` - Service bay information and equipment

\- `service\_records` - Completed service history

\- `call\_logs` - Customer communication records

\- `automation\_triggers` - Automated workflow triggers



\### Supporting Tables

\- `leads` - Lead management and conversion tracking

\- `customer\_preferences` - Customer communication preferences

\- `workflow\_status` - Workflow management



\## Key Relationships



\- Customers can have multiple vehicles and appointments

\- Appointments can have multiple services

\- Personnel are assigned to appointments

\- Bays are assigned to appointments based on service requirements

\- Service records track completed work



\## Schema Features



\- UUID primary keys for all tables

\- Comprehensive foreign key relationships

\- Check constraints for data validation

\- Automated timestamps for audit trails

\- JSONB fields for flexible data storage



\## Last Updated

July 27, 2025

