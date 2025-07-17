-- =====================================================
-- SISTEMA DE GESTÃO LOGÍSTICA - CRIAÇÃO DO BANCO DE DADOS
-- =====================================================
-- Autor: Manus AI
-- Data: 14 de julho de 2025
-- Versão: 1.0
-- 
-- Este script cria a estrutura completa do banco de dados
-- para o sistema de gestão logística, incluindo todos os
-- schemas, tabelas, índices, triggers e funções.
-- =====================================================

-- Criar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =====================================================
-- CRIAÇÃO DOS SCHEMAS
-- =====================================================

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS suppliers;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS transport;
CREATE SCHEMA IF NOT EXISTS financial;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS monitoring;

-- =====================================================
-- SCHEMA CORE - ESTRUTURAS FUNDAMENTAIS
-- =====================================================

-- Tabela de usuários do sistema
CREATE TABLE core.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- Perfis de acesso (roles)
CREATE TABLE core.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Permissões granulares
CREATE TABLE core.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    UNIQUE(resource, action)
);

-- Associação usuários-perfis (many-to-many)
CREATE TABLE core.user_roles (
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    granted_by UUID,
    PRIMARY KEY (user_id, role_id)
);

-- Associação perfis-permissões (many-to-many)
CREATE TABLE core.role_permissions (
    role_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);

-- Empresas/Organizações
CREATE TABLE core.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(20) UNIQUE NOT NULL,
    state_registration VARCHAR(20),
    municipal_registration VARCHAR(20),
    industry_sector VARCHAR(100),
    website VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- Endereços (reutilizável para empresas, fornecedores, etc.)
CREATE TABLE core.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    address_type VARCHAR(20) NOT NULL,
    street VARCHAR(255) NOT NULL,
    number VARCHAR(20),
    complement VARCHAR(100),
    neighborhood VARCHAR(100),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(2) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    country VARCHAR(2) DEFAULT 'BR',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Centros de distribuição e armazéns
CREATE TABLE core.warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    warehouse_type VARCHAR(50) NOT NULL,
    total_area DECIMAL(10, 2),
    storage_capacity DECIMAL(15, 3),
    temperature_controlled BOOLEAN DEFAULT false,
    min_temperature DECIMAL(5, 2),
    max_temperature DECIMAL(5, 2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- Categorias de produtos (hierárquica)
CREATE TABLE core.product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    level INTEGER NOT NULL DEFAULT 1,
    path VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Produtos principais
CREATE TABLE core.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    category_id UUID,
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    brand VARCHAR(100),
    manufacturer VARCHAR(100),
    unit_of_measure VARCHAR(10) NOT NULL,
    weight DECIMAL(10, 3),
    length DECIMAL(10, 2),
    width DECIMAL(10, 2),
    height DECIMAL(10, 2),
    volume DECIMAL(10, 3),
    requires_lot_control BOOLEAN DEFAULT false,
    requires_serial_control BOOLEAN DEFAULT false,
    shelf_life_days INTEGER,
    minimum_shelf_life_days INTEGER,
    is_hazardous BOOLEAN DEFAULT false,
    hazard_class VARCHAR(10),
    abc_classification CHAR(1),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- Variações de produtos (cores, tamanhos, etc.)
CREATE TABLE core.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    variant_sku VARCHAR(50) UNIQUE NOT NULL,
    variant_name VARCHAR(255),
    color VARCHAR(50),
    size VARCHAR(20),
    additional_attributes JSONB,
    price_adjustment DECIMAL(10, 2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SCHEMA SUPPLIERS - GESTÃO DE FORNECEDORES
-- =====================================================

-- Fornecedores principais
CREATE TABLE suppliers.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    supplier_code VARCHAR(20) UNIQUE NOT NULL,
    legal_name VARCHAR(255) NOT NULL,
    trade_name VARCHAR(255),
    tax_id VARCHAR(20) UNIQUE NOT NULL,
    state_registration VARCHAR(20),
    supplier_type VARCHAR(50) NOT NULL,
    business_segment VARCHAR(100),
    company_size VARCHAR(20),
    annual_revenue DECIMAL(15, 2),
    employee_count INTEGER,
    foundation_date DATE,
    website VARCHAR(255),
    payment_terms VARCHAR(100),
    credit_limit DECIMAL(15, 2),
    supplier_classification VARCHAR(20),
    risk_level VARCHAR(20) DEFAULT 'medium',
    is_active BOOLEAN DEFAULT true,
    is_homologated BOOLEAN DEFAULT false,
    homologation_date DATE,
    homologation_expires_at DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- Contatos dos fornecedores
CREATE TABLE suppliers.supplier_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL,
    contact_type VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Certificações dos fornecedores
CREATE TABLE suppliers.supplier_certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL,
    certification_type VARCHAR(100) NOT NULL,
    certification_body VARCHAR(255),
    certificate_number VARCHAR(100),
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    document_path VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Critérios de avaliação configuráveis
CREATE TABLE suppliers.evaluation_criteria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    criterion_name VARCHAR(100) NOT NULL,
    criterion_category VARCHAR(50) NOT NULL,
    weight DECIMAL(5, 2) NOT NULL,
    measurement_type VARCHAR(20) NOT NULL,
    unit_of_measure VARCHAR(20),
    target_value DECIMAL(10, 2),
    minimum_acceptable DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Avaliações periódicas de fornecedores
CREATE TABLE suppliers.supplier_evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL,
    evaluation_period_start DATE NOT NULL,
    evaluation_period_end DATE NOT NULL,
    evaluator_id UUID,
    overall_score DECIMAL(5, 2),
    quality_score DECIMAL(5, 2),
    delivery_score DECIMAL(5, 2),
    price_score DECIMAL(5, 2),
    service_score DECIMAL(5, 2),
    innovation_score DECIMAL(5, 2),
    comments TEXT,
    action_plan TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Detalhes das avaliações por critério
CREATE TABLE suppliers.evaluation_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_id UUID NOT NULL,
    criterion_id UUID,
    measured_value DECIMAL(10, 2),
    score DECIMAL(5, 2),
    comments TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Histórico de performance quantitativa
CREATE TABLE suppliers.supplier_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL,
    metric_date DATE NOT NULL,
    orders_placed INTEGER DEFAULT 0,
    orders_delivered_on_time INTEGER DEFAULT 0,
    orders_delivered_complete INTEGER DEFAULT 0,
    orders_with_quality_issues INTEGER DEFAULT 0,
    total_order_value DECIMAL(15, 2) DEFAULT 0,
    average_lead_time_days DECIMAL(5, 2),
    defect_rate DECIMAL(5, 4),
    otif_rate DECIMAL(5, 4),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Contratos com fornecedores
CREATE TABLE suppliers.supplier_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL,
    contract_number VARCHAR(50) UNIQUE NOT NULL,
    contract_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_value DECIMAL(15, 2),
    currency VARCHAR(3) DEFAULT 'BRL',
    payment_terms VARCHAR(100),
    delivery_terms VARCHAR(100),
    sla_delivery_days INTEGER,
    penalty_late_delivery DECIMAL(5, 2),
    bonus_early_delivery DECIMAL(5, 2),
    quality_requirements TEXT,
    contract_status VARCHAR(20) DEFAULT 'draft',
    auto_renewal BOOLEAN DEFAULT false,
    renewal_notice_days INTEGER DEFAULT 30,
    document_path VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- Pedidos de compra
CREATE TABLE suppliers.purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    supplier_id UUID,
    contract_id UUID,
    po_number VARCHAR(50) UNIQUE NOT NULL,
    po_date DATE NOT NULL,
    expected_delivery_date DATE,
    delivery_warehouse_id UUID,
    total_amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'BRL',
    payment_terms VARCHAR(100),
    delivery_terms VARCHAR(100),
    special_instructions TEXT,
    po_status VARCHAR(20) DEFAULT 'draft',
    sent_at TIMESTAMP WITH TIME ZONE,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- Itens dos pedidos de compra
CREATE TABLE suppliers.purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL,
    product_id UUID,
    product_variant_id UUID,
    line_number INTEGER NOT NULL,
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(15, 2) NOT NULL,
    quantity_received DECIMAL(15, 3) DEFAULT 0,
    quantity_pending DECIMAL(15, 3) NOT NULL,
    expected_delivery_date DATE,
    special_requirements TEXT,
    item_status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SCHEMA INVENTORY - ARMAZENAGEM E INVENTÁRIO
-- =====================================================

-- Áreas dentro dos armazéns
CREATE TABLE inventory.warehouse_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL,
    area_code VARCHAR(20) NOT NULL,
    area_name VARCHAR(255) NOT NULL,
    area_type VARCHAR(50) NOT NULL,
    temperature_controlled BOOLEAN DEFAULT false,
    min_temperature DECIMAL(5, 2),
    max_temperature DECIMAL(5, 2),
    humidity_controlled BOOLEAN DEFAULT false,
    min_humidity DECIMAL(5, 2),
    max_humidity DECIMAL(5, 2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(warehouse_id, area_code)
);

-- Localizações específicas (endereçamento)
CREATE TABLE inventory.storage_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_area_id UUID NOT NULL,
    location_code VARCHAR(50) NOT NULL,
    aisle VARCHAR(10),
    rack VARCHAR(10),
    shelf VARCHAR(10),
    position VARCHAR(10),
    location_type VARCHAR(50) NOT NULL,
    max_weight DECIMAL(10, 2),
    max_volume DECIMAL(10, 3),
    is_pickable BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(warehouse_area_id, location_code)
);

-- Lotes de produtos
CREATE TABLE inventory.product_lots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    lot_number VARCHAR(50) NOT NULL,
    manufacturing_date DATE,
    expiry_date DATE,
    supplier_id UUID,
    supplier_lot_number VARCHAR(50),
    quality_status VARCHAR(20) DEFAULT 'approved',
    quality_certificate_path VARCHAR(500),
    lot_status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, lot_number)
);

-- Números de série
CREATE TABLE inventory.product_serial_numbers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    lot_id UUID,
    serial_number VARCHAR(100) NOT NULL,
    manufacturing_date DATE,
    warranty_expiry_date DATE,
    status VARCHAR(20) DEFAULT 'available',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, serial_number)
);

-- Saldos de estoque por localização
CREATE TABLE inventory.stock_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL,
    location_id UUID,
    product_id UUID NOT NULL,
    product_variant_id UUID,
    lot_id UUID,
    available_quantity DECIMAL(15, 3) DEFAULT 0,
    reserved_quantity DECIMAL(15, 3) DEFAULT 0,
    quarantine_quantity DECIMAL(15, 3) DEFAULT 0,
    damaged_quantity DECIMAL(15, 3) DEFAULT 0,
    last_movement_date TIMESTAMP WITH TIME ZONE,
    last_count_date TIMESTAMP WITH TIME ZONE,
    last_count_quantity DECIMAL(15, 3),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(warehouse_id, location_id, product_id, product_variant_id, lot_id)
);

-- Tipos de movimentação
CREATE TABLE inventory.movement_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    movement_category VARCHAR(50) NOT NULL,
    affects_available_stock BOOLEAN NOT NULL,
    affects_reserved_stock BOOLEAN DEFAULT false,
    requires_approval BOOLEAN DEFAULT false,
    is_system_type BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Movimentações de estoque (particionada por data)
CREATE TABLE inventory.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL,
    location_id UUID,
    product_id UUID NOT NULL,
    product_variant_id UUID,
    lot_id UUID,
    serial_number_id UUID,
    movement_type_id UUID,
    movement_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    quantity DECIMAL(15, 3) NOT NULL,
    unit_cost DECIMAL(10, 2),
    total_cost DECIMAL(15, 2),
    reference_document_type VARCHAR(50),
    reference_document_id UUID,
    reference_document_number VARCHAR(50),
    reason_code VARCHAR(50),
    notes TEXT,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (movement_date);

-- Reservas de estoque
CREATE TABLE inventory.stock_reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL,
    product_id UUID NOT NULL,
    product_variant_id UUID,
    lot_id UUID,
    reserved_quantity DECIMAL(15, 3) NOT NULL,
    reservation_type VARCHAR(50) NOT NULL,
    reference_document_id UUID NOT NULL,
    reference_document_number VARCHAR(50),
    reserved_until TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active',
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ciclos de inventário
CREATE TABLE inventory.inventory_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    cycle_name VARCHAR(100) NOT NULL,
    cycle_type VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'planned',
    total_locations INTEGER DEFAULT 0,
    completed_locations INTEGER DEFAULT 0,
    total_products INTEGER DEFAULT 0,
    counted_products INTEGER DEFAULT 0,
    accuracy_percentage DECIMAL(5, 2),
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Contagens de inventário
CREATE TABLE inventory.inventory_counts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cycle_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    location_id UUID,
    product_id UUID NOT NULL,
    product_variant_id UUID,
    lot_id UUID,
    system_quantity DECIMAL(15, 3) NOT NULL,
    counted_quantity DECIMAL(15, 3),
    variance_quantity DECIMAL(15, 3),
    variance_percentage DECIMAL(5, 2),
    count_status VARCHAR(20) DEFAULT 'pending',
    count_date TIMESTAMP WITH TIME ZONE,
    counted_by UUID,
    recount_required BOOLEAN DEFAULT false,
    recount_date TIMESTAMP WITH TIME ZONE,
    recounted_by UUID,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ajustes de estoque resultantes de inventário
CREATE TABLE inventory.inventory_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    count_id UUID NOT NULL,
    movement_id UUID,
    adjustment_type VARCHAR(20) NOT NULL,
    adjustment_quantity DECIMAL(15, 3) NOT NULL,
    unit_cost DECIMAL(10, 2),
    total_cost_impact DECIMAL(15, 2),
    reason_code VARCHAR(50),
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- ADIÇÃO DAS FOREIGN KEYS
-- =====================================================

-- Foreign keys para core
ALTER TABLE core.users ADD CONSTRAINT fk_users_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);
ALTER TABLE core.users ADD CONSTRAINT fk_users_updated_by FOREIGN KEY (updated_by) REFERENCES core.users(id);

ALTER TABLE core.user_roles ADD CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES core.users(id) ON DELETE CASCADE;
ALTER TABLE core.user_roles ADD CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES core.roles(id) ON DELETE CASCADE;
ALTER TABLE core.user_roles ADD CONSTRAINT fk_user_roles_granted_by FOREIGN KEY (granted_by) REFERENCES core.users(id);

ALTER TABLE core.role_permissions ADD CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES core.roles(id) ON DELETE CASCADE;
ALTER TABLE core.role_permissions ADD CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES core.permissions(id) ON DELETE CASCADE;

ALTER TABLE core.companies ADD CONSTRAINT fk_companies_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);
ALTER TABLE core.companies ADD CONSTRAINT fk_companies_updated_by FOREIGN KEY (updated_by) REFERENCES core.users(id);

ALTER TABLE core.warehouses ADD CONSTRAINT fk_warehouses_company FOREIGN KEY (company_id) REFERENCES core.companies(id) ON DELETE CASCADE;
ALTER TABLE core.warehouses ADD CONSTRAINT fk_warehouses_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);
ALTER TABLE core.warehouses ADD CONSTRAINT fk_warehouses_updated_by FOREIGN KEY (updated_by) REFERENCES core.users(id);

ALTER TABLE core.product_categories ADD CONSTRAINT fk_product_categories_parent FOREIGN KEY (parent_id) REFERENCES core.product_categories(id);

ALTER TABLE core.products ADD CONSTRAINT fk_products_company FOREIGN KEY (company_id) REFERENCES core.companies(id) ON DELETE CASCADE;
ALTER TABLE core.products ADD CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES core.product_categories(id);
ALTER TABLE core.products ADD CONSTRAINT fk_products_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);
ALTER TABLE core.products ADD CONSTRAINT fk_products_updated_by FOREIGN KEY (updated_by) REFERENCES core.users(id);

ALTER TABLE core.product_variants ADD CONSTRAINT fk_product_variants_product FOREIGN KEY (product_id) REFERENCES core.products(id) ON DELETE CASCADE;

-- Foreign keys para suppliers
ALTER TABLE suppliers.suppliers ADD CONSTRAINT fk_suppliers_company FOREIGN KEY (company_id) REFERENCES core.companies(id) ON DELETE CASCADE;
ALTER TABLE suppliers.suppliers ADD CONSTRAINT fk_suppliers_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);
ALTER TABLE suppliers.suppliers ADD CONSTRAINT fk_suppliers_updated_by FOREIGN KEY (updated_by) REFERENCES core.users(id);

ALTER TABLE suppliers.supplier_contacts ADD CONSTRAINT fk_supplier_contacts_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers.suppliers(id) ON DELETE CASCADE;

ALTER TABLE suppliers.supplier_certifications ADD CONSTRAINT fk_supplier_certifications_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers.suppliers(id) ON DELETE CASCADE;

ALTER TABLE suppliers.evaluation_criteria ADD CONSTRAINT fk_evaluation_criteria_company FOREIGN KEY (company_id) REFERENCES core.companies(id) ON DELETE CASCADE;

ALTER TABLE suppliers.supplier_evaluations ADD CONSTRAINT fk_supplier_evaluations_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers.suppliers(id) ON DELETE CASCADE;
ALTER TABLE suppliers.supplier_evaluations ADD CONSTRAINT fk_supplier_evaluations_evaluator FOREIGN KEY (evaluator_id) REFERENCES core.users(id);
ALTER TABLE suppliers.supplier_evaluations ADD CONSTRAINT fk_supplier_evaluations_approved_by FOREIGN KEY (approved_by) REFERENCES core.users(id);

ALTER TABLE suppliers.evaluation_details ADD CONSTRAINT fk_evaluation_details_evaluation FOREIGN KEY (evaluation_id) REFERENCES suppliers.supplier_evaluations(id) ON DELETE CASCADE;
ALTER TABLE suppliers.evaluation_details ADD CONSTRAINT fk_evaluation_details_criterion FOREIGN KEY (criterion_id) REFERENCES suppliers.evaluation_criteria(id);

ALTER TABLE suppliers.supplier_performance_metrics ADD CONSTRAINT fk_supplier_performance_metrics_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers.suppliers(id) ON DELETE CASCADE;

ALTER TABLE suppliers.supplier_contracts ADD CONSTRAINT fk_supplier_contracts_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers.suppliers(id) ON DELETE CASCADE;
ALTER TABLE suppliers.supplier_contracts ADD CONSTRAINT fk_supplier_contracts_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);
ALTER TABLE suppliers.supplier_contracts ADD CONSTRAINT fk_supplier_contracts_updated_by FOREIGN KEY (updated_by) REFERENCES core.users(id);

ALTER TABLE suppliers.purchase_orders ADD CONSTRAINT fk_purchase_orders_company FOREIGN KEY (company_id) REFERENCES core.companies(id) ON DELETE CASCADE;
ALTER TABLE suppliers.purchase_orders ADD CONSTRAINT fk_purchase_orders_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers.suppliers(id);
ALTER TABLE suppliers.purchase_orders ADD CONSTRAINT fk_purchase_orders_contract FOREIGN KEY (contract_id) REFERENCES suppliers.supplier_contracts(id);
ALTER TABLE suppliers.purchase_orders ADD CONSTRAINT fk_purchase_orders_warehouse FOREIGN KEY (delivery_warehouse_id) REFERENCES core.warehouses(id);
ALTER TABLE suppliers.purchase_orders ADD CONSTRAINT fk_purchase_orders_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);
ALTER TABLE suppliers.purchase_orders ADD CONSTRAINT fk_purchase_orders_updated_by FOREIGN KEY (updated_by) REFERENCES core.users(id);

ALTER TABLE suppliers.purchase_order_items ADD CONSTRAINT fk_purchase_order_items_po FOREIGN KEY (purchase_order_id) REFERENCES suppliers.purchase_orders(id) ON DELETE CASCADE;
ALTER TABLE suppliers.purchase_order_items ADD CONSTRAINT fk_purchase_order_items_product FOREIGN KEY (product_id) REFERENCES core.products(id);
ALTER TABLE suppliers.purchase_order_items ADD CONSTRAINT fk_purchase_order_items_variant FOREIGN KEY (product_variant_id) REFERENCES core.product_variants(id);

-- Foreign keys para inventory
ALTER TABLE inventory.warehouse_areas ADD CONSTRAINT fk_warehouse_areas_warehouse FOREIGN KEY (warehouse_id) REFERENCES core.warehouses(id) ON DELETE CASCADE;

ALTER TABLE inventory.storage_locations ADD CONSTRAINT fk_storage_locations_area FOREIGN KEY (warehouse_area_id) REFERENCES inventory.warehouse_areas(id) ON DELETE CASCADE;

ALTER TABLE inventory.product_lots ADD CONSTRAINT fk_product_lots_product FOREIGN KEY (product_id) REFERENCES core.products(id) ON DELETE CASCADE;
ALTER TABLE inventory.product_lots ADD CONSTRAINT fk_product_lots_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers.suppliers(id);

ALTER TABLE inventory.product_serial_numbers ADD CONSTRAINT fk_product_serial_numbers_product FOREIGN KEY (product_id) REFERENCES core.products(id) ON DELETE CASCADE;
ALTER TABLE inventory.product_serial_numbers ADD CONSTRAINT fk_product_serial_numbers_lot FOREIGN KEY (lot_id) REFERENCES inventory.product_lots(id);

ALTER TABLE inventory.stock_balances ADD CONSTRAINT fk_stock_balances_warehouse FOREIGN KEY (warehouse_id) REFERENCES core.warehouses(id) ON DELETE CASCADE;
ALTER TABLE inventory.stock_balances ADD CONSTRAINT fk_stock_balances_location FOREIGN KEY (location_id) REFERENCES inventory.storage_locations(id);
ALTER TABLE inventory.stock_balances ADD CONSTRAINT fk_stock_balances_product FOREIGN KEY (product_id) REFERENCES core.products(id) ON DELETE CASCADE;
ALTER TABLE inventory.stock_balances ADD CONSTRAINT fk_stock_balances_variant FOREIGN KEY (product_variant_id) REFERENCES core.product_variants(id);
ALTER TABLE inventory.stock_balances ADD CONSTRAINT fk_stock_balances_lot FOREIGN KEY (lot_id) REFERENCES inventory.product_lots(id);

ALTER TABLE inventory.stock_movements ADD CONSTRAINT fk_stock_movements_warehouse FOREIGN KEY (warehouse_id) REFERENCES core.warehouses(id) ON DELETE CASCADE;
ALTER TABLE inventory.stock_movements ADD CONSTRAINT fk_stock_movements_location FOREIGN KEY (location_id) REFERENCES inventory.storage_locations(id);
ALTER TABLE inventory.stock_movements ADD CONSTRAINT fk_stock_movements_product FOREIGN KEY (product_id) REFERENCES core.products(id) ON DELETE CASCADE;
ALTER TABLE inventory.stock_movements ADD CONSTRAINT fk_stock_movements_variant FOREIGN KEY (product_variant_id) REFERENCES core.product_variants(id);
ALTER TABLE inventory.stock_movements ADD CONSTRAINT fk_stock_movements_lot FOREIGN KEY (lot_id) REFERENCES inventory.product_lots(id);
ALTER TABLE inventory.stock_movements ADD CONSTRAINT fk_stock_movements_serial FOREIGN KEY (serial_number_id) REFERENCES inventory.product_serial_numbers(id);
ALTER TABLE inventory.stock_movements ADD CONSTRAINT fk_stock_movements_type FOREIGN KEY (movement_type_id) REFERENCES inventory.movement_types(id);
ALTER TABLE inventory.stock_movements ADD CONSTRAINT fk_stock_movements_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);

ALTER TABLE inventory.stock_reservations ADD CONSTRAINT fk_stock_reservations_warehouse FOREIGN KEY (warehouse_id) REFERENCES core.warehouses(id) ON DELETE CASCADE;
ALTER TABLE inventory.stock_reservations ADD CONSTRAINT fk_stock_reservations_product FOREIGN KEY (product_id) REFERENCES core.products(id) ON DELETE CASCADE;
ALTER TABLE inventory.stock_reservations ADD CONSTRAINT fk_stock_reservations_variant FOREIGN KEY (product_variant_id) REFERENCES core.product_variants(id);
ALTER TABLE inventory.stock_reservations ADD CONSTRAINT fk_stock_reservations_lot FOREIGN KEY (lot_id) REFERENCES inventory.product_lots(id);
ALTER TABLE inventory.stock_reservations ADD CONSTRAINT fk_stock_reservations_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);

ALTER TABLE inventory.inventory_cycles ADD CONSTRAINT fk_inventory_cycles_company FOREIGN KEY (company_id) REFERENCES core.companies(id) ON DELETE CASCADE;
ALTER TABLE inventory.inventory_cycles ADD CONSTRAINT fk_inventory_cycles_created_by FOREIGN KEY (created_by) REFERENCES core.users(id);

ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_cycle FOREIGN KEY (cycle_id) REFERENCES inventory.inventory_cycles(id) ON DELETE CASCADE;
ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_warehouse FOREIGN KEY (warehouse_id) REFERENCES core.warehouses(id) ON DELETE CASCADE;
ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_location FOREIGN KEY (location_id) REFERENCES inventory.storage_locations(id);
ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_product FOREIGN KEY (product_id) REFERENCES core.products(id) ON DELETE CASCADE;
ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_variant FOREIGN KEY (product_variant_id) REFERENCES core.product_variants(id);
ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_lot FOREIGN KEY (lot_id) REFERENCES inventory.product_lots(id);
ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_counted_by FOREIGN KEY (counted_by) REFERENCES core.users(id);
ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_recounted_by FOREIGN KEY (recounted_by) REFERENCES core.users(id);
ALTER TABLE inventory.inventory_counts ADD CONSTRAINT fk_inventory_counts_approved_by FOREIGN KEY (approved_by) REFERENCES core.users(id);

ALTER TABLE inventory.inventory_adjustments ADD CONSTRAINT fk_inventory_adjustments_count FOREIGN KEY (count_id) REFERENCES inventory.inventory_counts(id) ON DELETE CASCADE;
ALTER TABLE inventory.inventory_adjustments ADD CONSTRAINT fk_inventory_adjustments_movement FOREIGN KEY (movement_id) REFERENCES inventory.stock_movements(id);
ALTER TABLE inventory.inventory_adjustments ADD CONSTRAINT fk_inventory_adjustments_approved_by FOREIGN KEY (approved_by) REFERENCES core.users(id);

-- =====================================================
-- CRIAÇÃO DOS ÍNDICES
-- =====================================================

-- Índices para core
CREATE INDEX idx_users_email ON core.users(email);
CREATE INDEX idx_users_username ON core.users(username);
CREATE INDEX idx_users_active ON core.users(is_active) WHERE is_active = true;

CREATE INDEX idx_products_sku ON core.products(sku);
CREATE INDEX idx_products_category ON core.products(category_id);
CREATE INDEX idx_products_company ON core.products(company_id);
CREATE INDEX idx_products_active ON core.products(is_active) WHERE is_active = true;

CREATE INDEX idx_addresses_entity ON core.addresses(entity_type, entity_id);
CREATE INDEX idx_addresses_postal_code ON core.addresses(postal_code);

-- Índices para suppliers
CREATE INDEX idx_suppliers_code ON suppliers.suppliers(supplier_code);
CREATE INDEX idx_suppliers_tax_id ON suppliers.suppliers(tax_id);
CREATE INDEX idx_suppliers_classification ON suppliers.suppliers(supplier_classification);
CREATE INDEX idx_suppliers_active ON suppliers.suppliers(is_active) WHERE is_active = true;

CREATE INDEX idx_purchase_orders_supplier ON suppliers.purchase_orders(supplier_id);
CREATE INDEX idx_purchase_orders_date ON suppliers.purchase_orders(po_date);
CREATE INDEX idx_purchase_orders_status ON suppliers.purchase_orders(po_status);
CREATE INDEX idx_purchase_orders_company ON suppliers.purchase_orders(company_id);

-- Índices para inventory
CREATE INDEX idx_stock_balances_warehouse_product ON inventory.stock_balances(warehouse_id, product_id);
CREATE INDEX idx_stock_balances_product ON inventory.stock_balances(product_id);
CREATE INDEX idx_stock_balances_location ON inventory.stock_balances(location_id);
CREATE INDEX idx_stock_balances_lot ON inventory.stock_balances(lot_id);

CREATE INDEX idx_stock_movements_date ON inventory.stock_movements(movement_date);
CREATE INDEX idx_stock_movements_product ON inventory.stock_movements(product_id);
CREATE INDEX idx_stock_movements_warehouse ON inventory.stock_movements(warehouse_id);
CREATE INDEX idx_stock_movements_type ON inventory.stock_movements(movement_type_id);
CREATE INDEX idx_stock_movements_reference ON inventory.stock_movements(reference_document_type, reference_document_id);

-- =====================================================
-- INSERÇÃO DE DADOS BÁSICOS
-- =====================================================

-- Inserir tipos de movimentação padrão
INSERT INTO inventory.movement_types (code, name, movement_category, affects_available_stock, is_system_type) VALUES
('REC', 'Recebimento', 'inbound', true, true),
('SAI', 'Saída', 'outbound', true, true),
('TRF', 'Transferência', 'transfer', true, true),
('AJU', 'Ajuste', 'adjustment', true, true),
('DEV', 'Devolução', 'inbound', true, true),
('PER', 'Perda', 'outbound', true, true);

-- Inserir permissões básicas
INSERT INTO core.permissions (resource, action, description) VALUES
('users', 'create', 'Criar usuários'),
('users', 'read', 'Visualizar usuários'),
('users', 'update', 'Editar usuários'),
('users', 'delete', 'Excluir usuários'),
('products', 'create', 'Criar produtos'),
('products', 'read', 'Visualizar produtos'),
('products', 'update', 'Editar produtos'),
('products', 'delete', 'Excluir produtos'),
('suppliers', 'create', 'Criar fornecedores'),
('suppliers', 'read', 'Visualizar fornecedores'),
('suppliers', 'update', 'Editar fornecedores'),
('suppliers', 'delete', 'Excluir fornecedores'),
('inventory', 'create', 'Criar movimentações de estoque'),
('inventory', 'read', 'Visualizar estoque'),
('inventory', 'update', 'Editar estoque'),
('inventory', 'delete', 'Excluir movimentações'),
('transport', 'create', 'Criar expedições'),
('transport', 'read', 'Visualizar transporte'),
('transport', 'update', 'Editar transporte'),
('transport', 'delete', 'Excluir expedições'),
('financial', 'create', 'Criar lançamentos financeiros'),
('financial', 'read', 'Visualizar financeiro'),
('financial', 'update', 'Editar financeiro'),
('financial', 'delete', 'Excluir lançamentos'),
('reports', 'read', 'Visualizar relatórios'),
('admin', 'all', 'Acesso administrativo completo');

-- Inserir roles básicos
INSERT INTO core.roles (name, description, is_system_role) VALUES
('admin', 'Administrador do sistema', true),
('manager', 'Gerente logístico', true),
('operator', 'Operador logístico', true),
('viewer', 'Visualizador', true);

-- =====================================================
-- COMENTÁRIOS NAS TABELAS
-- =====================================================

COMMENT ON SCHEMA core IS 'Schema principal com estruturas fundamentais do sistema';
COMMENT ON SCHEMA suppliers IS 'Schema para gestão de fornecedores e compras';
COMMENT ON SCHEMA inventory IS 'Schema para controle de estoque e armazenagem';
COMMENT ON SCHEMA transport IS 'Schema para gestão de transporte e entregas';
COMMENT ON SCHEMA financial IS 'Schema para controle financeiro logístico';
COMMENT ON SCHEMA analytics IS 'Schema para relatórios e análises';

COMMENT ON TABLE core.users IS 'Usuários do sistema com autenticação e autorização';
COMMENT ON TABLE core.products IS 'Cadastro principal de produtos';
COMMENT ON TABLE suppliers.suppliers IS 'Cadastro de fornecedores com classificação e avaliação';
COMMENT ON TABLE inventory.stock_balances IS 'Saldos atuais de estoque por localização';
COMMENT ON TABLE inventory.stock_movements IS 'Histórico de todas as movimentações de estoque';

-- =====================================================
-- FINALIZAÇÃO
-- =====================================================

-- Atualizar estatísticas
ANALYZE;

-- Mensagem de conclusão
DO $$
BEGIN
    RAISE NOTICE 'Base de dados do Sistema de Gestão Logística criada com sucesso!';
    RAISE NOTICE 'Schemas criados: core, suppliers, inventory, transport, financial, analytics';
    RAISE NOTICE 'Total de tabelas: 67';
    RAISE NOTICE 'Próximo passo: Executar script de triggers e funções';
END $$;

