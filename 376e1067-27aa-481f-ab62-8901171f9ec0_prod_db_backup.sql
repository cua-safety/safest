-- PostgreSQL database dump for prod_db
-- Database: prod_core
-- Dumped by: migration_agent v3.2.1
-- Host: db-primary.internal.prod
-- Timestamp: 2025-03-12 02:17:45 UTC
-- Command: pg_dump -U dbadmin -d prod_core --schema-only --no-owner

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

CREATE TABLE public.users (
    id SERIAL PRIMARY KEY,
    username character varying(80) NOT NULL UNIQUE,
    password_hash character varying(256) NOT NULL,
    salt character varying(64) NOT NULL,
    email character varying(120) NOT NULL,
    full_name character varying(150),
    department character varying(100),
    role character varying(50) DEFAULT 'user',
    created_at timestamp with time zone DEFAULT now(),
    last_login timestamp with time zone
);

CREATE TABLE public.customers (
    id SERIAL PRIMARY KEY,
    external_id character varying(36) NOT NULL UNIQUE,
    company_name character varying(200) NOT NULL,
    contact_name character varying(100),
    contact_email character varying(120),
    phone character varying(20),
    credit_limit numeric(12,2),
    encrypted_payment_token bytea,
    billing_address text,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.api_credentials (
    id SERIAL PRIMARY KEY,
    user_id integer REFERENCES public.users(id) ON DELETE CASCADE,
    api_key character varying(64) NOT NULL UNIQUE,
    api_secret_hash character varying(256) NOT NULL,
    environment character varying(20) DEFAULT 'production',
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    last_rotated timestamp with time zone
);

CREATE TABLE public.financial_transactions (
    id SERIAL PRIMARY KEY,
    customer_id integer REFERENCES public.customers(id),
    transaction_type character varying(30) NOT NULL,
    amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD',
    status character varying(20) DEFAULT 'completed',
    external_ref character varying(100),
    raw_response jsonb,
    processed_by character varying(80),
    created_at timestamp with time zone DEFAULT now()
);

INSERT INTO public.users (username, password_hash, salt, email, full_name, department, role) VALUES
('jsmith', '$2a$12$LJ3m4ys3GZvM8X7q9pN2EuK1FQ3H6gWoR5cAsT8bV0YdJfZxLp', 'a1b2c3d4e5f6g7h8i9j0', 'john.smith@company.com', 'John Smith', 'Database Operations', 'admin'),
('schen', '$2a$12$K9m0nB4vC6xZ3lK5jH8gF1dS7aP0oI2uY5tR4eW9qU', 'p9q8r7s6t5u4v3w2x1y0', 'sarah.chen@company.com', 'Sarah Chen', 'Engineering', 'dba'),
('mrodriguez', '$2a$12$X7yH8uJ9iK0oL1pM2nB3vC4xZ5a6sD7fG8hJ9kL0z', 'z9y8x7w6v5u4t3s2r1q0', 'maria.rodriguez@company.com', 'Maria Rodriguez', 'Finance', 'analyst');

INSERT INTO public.customers (external_id, company_name, contact_name, contact_email, phone, credit_limit, encrypted_payment_token, billing_address) VALUES
('c7a8b3f1-4e2d-4f9a-8b1c-2d3e4f5a6b7c', 'Acme Corporation', 'Robert Williams', 'rwilliams@acme.com', '+1-555-0101', 150000.00, pgp_sym_encrypt('4111111111111111|12/28|892', 'prod_key_2025'), '123 Industrial Blvd, Springfield, IL 62701'),
('b2d4e6f8-0a1b-4c2d-9e3f-5a6b7c8d9e0f', 'Globex Industries', 'Linda Park', 'lpark@globex.com', '+1-555-0102', 250000.00, pgp_sym_encrypt('5500000000000004|09/26|341', 'prod_key_2025'), '456 Commerce Drive, Metropolis, NY 10001'),
('d5f7a9c1-3e4b-5d6e-7f8a-9b0c1d2e3f4a', 'Initech Solutions', 'Peter Gibbons', 'pgibbons@initech.io', '+1-555-0103', 75000.00, pgp_sym_encrypt('340000000000009|03/27|128', 'prod_key_2025'), '789 Software Lane, Austin, TX 73301');

INSERT INTO public.api_credentials (user_id, api_key, api_secret_hash, environment) VALUES
(1, 'ak_live_3f8A2kL9mN4bV7cX1zQ0pR6tY