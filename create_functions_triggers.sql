-- =====================================================
-- SISTEMA DE GESTÃO LOGÍSTICA - FUNÇÕES E TRIGGERS
-- =====================================================
-- Autor: Manus AI
-- Data: 14 de julho de 2025
-- Versão: 1.0
-- 
-- Este script cria todas as funções, triggers e procedures
-- necessárias para o funcionamento do sistema de gestão
-- logística, incluindo automações e controles de negócio.
-- =====================================================

-- =====================================================
-- FUNÇÕES UTILITÁRIAS
-- =====================================================

-- Função para atualizar timestamps automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Função para definir contexto da empresa (multi-tenancy)
CREATE OR REPLACE FUNCTION set_current_company(company_uuid UUID)
RETURNS void AS $$
BEGIN
    PERFORM set_config('app.current_company_id', company_uuid::TEXT, false);
END;
$$ language 'plpgsql';

-- Função para definir contexto do usuário
CREATE OR REPLACE FUNCTION set_current_user_context(user_uuid UUID, user_ip INET DEFAULT NULL, user_agent TEXT DEFAULT NULL)
RETURNS void AS $$
BEGIN
    PERFORM set_config('app.current_user_id', user_uuid::TEXT, false);
    IF user_ip IS NOT NULL THEN
        PERFORM set_config('app.client_ip', user_ip::TEXT, false);
    END IF;
    IF user_agent IS NOT NULL THEN
        PERFORM set_config('app.user_agent', user_agent, false);
    END IF;
END;
$$ language 'plpgsql';

-- =====================================================
-- TRIGGERS PARA UPDATED_AT
-- =====================================================

-- Triggers para atualização automática de updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON core.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at 
    BEFORE UPDATE ON core.companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON core.products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_warehouses_updated_at 
    BEFORE UPDATE ON core.warehouses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at 
    BEFORE UPDATE ON suppliers.suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchase_orders_updated_at 
    BEFORE UPDATE ON suppliers.purchase_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stock_balances_updated_at 
    BEFORE UPDATE ON inventory.stock_balances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNÇÕES DE CONTROLE DE ESTOQUE
-- =====================================================

-- Função para atualizar saldos de estoque após movimentação
CREATE OR REPLACE FUNCTION update_stock_balance()
RETURNS TRIGGER AS $$
DECLARE
    movement_type_rec RECORD;
BEGIN
    -- Buscar informações do tipo de movimentação
    SELECT affects_available_stock, affects_reserved_stock
    INTO movement_type_rec
    FROM inventory.movement_types
    WHERE id = NEW.movement_type_id;
    
    -- Se o tipo de movimentação afeta estoque disponível
    IF movement_type_rec.affects_available_stock THEN
        -- Inserir ou atualizar saldo
        INSERT INTO inventory.stock_balances (
            warehouse_id, location_id, product_id, product_variant_id, lot_id,
            available_quantity, last_movement_date
        )
        VALUES (
            NEW.warehouse_id, NEW.location_id, NEW.product_id, NEW.product_variant_id, NEW.lot_id,
            NEW.quantity, NEW.movement_date
        )
        ON CONFLICT (warehouse_id, location_id, product_id, product_variant_id, lot_id)
        DO UPDATE SET
            available_quantity = inventory.stock_balances.available_quantity + NEW.quantity,
            last_movement_date = NEW.movement_date,
            updated_at = CURRENT_TIMESTAMP;
    END IF;
    
    -- Se o tipo de movimentação afeta estoque reservado
    IF movement_type_rec.affects_reserved_stock THEN
        UPDATE inventory.stock_balances
        SET reserved_quantity = reserved_quantity + NEW.quantity,
            updated_at = CURRENT_TIMESTAMP
        WHERE warehouse_id = NEW.warehouse_id
          AND location_id = NEW.location_id
          AND product_id = NEW.product_id
          AND (product_variant_id = NEW.product_variant_id OR (product_variant_id IS NULL AND NEW.product_variant_id IS NULL))
          AND (lot_id = NEW.lot_id OR (lot_id IS NULL AND NEW.lot_id IS NULL));
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualização automática de saldos
CREATE TRIGGER update_stock_balance_trigger
    AFTER INSERT ON inventory.stock_movements
    FOR EACH ROW EXECUTE FUNCTION update_stock_balance();

-- Função para validar movimentação de estoque
CREATE OR REPLACE FUNCTION validate_stock_movement()
RETURNS TRIGGER AS $$
DECLARE
    current_balance DECIMAL(15,3);
    movement_type_rec RECORD;
BEGIN
    -- Buscar informações do tipo de movimentação
    SELECT affects_available_stock, movement_category
    INTO movement_type_rec
    FROM inventory.movement_types
    WHERE id = NEW.movement_type_id;
    
    -- Para saídas, verificar se há saldo suficiente
    IF movement_type_rec.affects_available_stock AND NEW.quantity < 0 THEN
        SELECT COALESCE(available_quantity, 0)
        INTO current_balance
        FROM inventory.stock_balances
        WHERE warehouse_id = NEW.warehouse_id
          AND location_id = NEW.location_id
          AND product_id = NEW.product_id
          AND (product_variant_id = NEW.product_variant_id OR (product_variant_id IS NULL AND NEW.product_variant_id IS NULL))
          AND (lot_id = NEW.lot_id OR (lot_id IS NULL AND NEW.lot_id IS NULL));
        
        IF current_balance + NEW.quantity < 0 THEN
            RAISE EXCEPTION 'Saldo insuficiente. Saldo atual: %, Quantidade solicitada: %', 
                current_balance, ABS(NEW.quantity);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para validação de movimentações
CREATE TRIGGER validate_stock_movement_trigger
    BEFORE INSERT ON inventory.stock_movements
    FOR EACH ROW EXECUTE FUNCTION validate_stock_movement();

-- =====================================================
-- FUNÇÕES DE AUDITORIA
-- =====================================================

-- Tabela de auditoria
CREATE TABLE IF NOT EXISTS audit.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    user_id UUID,
    user_ip INET,
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Função genérica de auditoria
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    old_data JSONB;
    new_data JSONB;
    changed_fields TEXT[];
    current_user_id UUID;
    current_user_ip INET;
    current_user_agent TEXT;
BEGIN
    -- Obter contexto do usuário atual
    BEGIN
        current_user_id := current_setting('app.current_user_id', true)::UUID;
        current_user_ip := current_setting('app.client_ip', true)::INET;
        current_user_agent := current_setting('app.user_agent', true);
    EXCEPTION WHEN OTHERS THEN
        current_user_id := NULL;
        current_user_ip := NULL;
        current_user_agent := NULL;
    END;
    
    IF TG_OP = 'DELETE' THEN
        old_data := to_jsonb(OLD);
        new_data := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);
        -- Identificar campos alterados
        SELECT array_agg(key) INTO changed_fields
        FROM jsonb_each(old_data) o
        JOIN jsonb_each(new_data) n ON o.key = n.key
        WHERE o.value IS DISTINCT FROM n.value;
    ELSIF TG_OP = 'INSERT' THEN
        old_data := NULL;
        new_data := to_jsonb(NEW);
    END IF;
    
    INSERT INTO audit.audit_log (
        table_name, record_id, operation, old_values, new_values, changed_fields,
        user_id, user_ip, user_agent
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        TG_OP,
        old_data,
        new_data,
        changed_fields,
        current_user_id,
        current_user_ip,
        current_user_agent
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Aplicar auditoria em tabelas críticas
CREATE TRIGGER audit_users_trigger
    AFTER INSERT OR UPDATE OR DELETE ON core.users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_companies_trigger
    AFTER INSERT OR UPDATE OR DELETE ON core.companies
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_products_trigger
    AFTER INSERT OR UPDATE OR DELETE ON core.products
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_suppliers_trigger
    AFTER INSERT OR UPDATE OR DELETE ON suppliers.suppliers
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_stock_movements_trigger
    AFTER INSERT OR UPDATE OR DELETE ON inventory.stock_movements
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- =====================================================
-- FUNÇÕES DE CÁLCULO DE KPIs
-- =====================================================

-- Criar tabela de dimensão de tempo se não existir
CREATE TABLE IF NOT EXISTS analytics.dim_time (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week INTEGER NOT NULL,
    day_of_year INTEGER NOT NULL,
    day_of_month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT false,
    holiday_name VARCHAR(100)
);

-- Criar tabelas de fatos se não existirem
CREATE TABLE IF NOT EXISTS analytics.fact_supplier_performance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date_key INTEGER,
    supplier_id UUID,
    orders_placed INTEGER DEFAULT 0,
    orders_delivered_on_time INTEGER DEFAULT 0,
    orders_delivered_complete INTEGER DEFAULT 0,
    orders_with_quality_issues INTEGER DEFAULT 0,
    total_order_value DECIMAL(15, 2) DEFAULT 0,
    average_lead_time_days DECIMAL(5, 2),
    otif_rate DECIMAL(5, 4),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date_key, supplier_id)
);

CREATE TABLE IF NOT EXISTS analytics.kpi_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date_key INTEGER,
    company_id UUID,
    kpi_category VARCHAR(50) NOT NULL,
    kpi_name VARCHAR(100) NOT NULL,
    kpi_value DECIMAL(15, 4) NOT NULL,
    kpi_unit VARCHAR(20),
    target_value DECIMAL(15, 4),
    variance_percentage DECIMAL(5, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date_key, company_id, kpi_category, kpi_name)
);

-- Função para popular dimensão de tempo
CREATE OR REPLACE FUNCTION populate_dim_time(start_date DATE, end_date DATE)
RETURNS void AS $$
DECLARE
    current_date DATE;
BEGIN
    current_date := start_date;
    
    WHILE current_date <= end_date LOOP
        INSERT INTO analytics.dim_time (
            date_key, full_date, year, quarter, month, month_name,
            week, day_of_year, day_of_month, day_of_week, day_name, is_weekend
        ) VALUES (
            TO_CHAR(current_date, 'YYYYMMDD')::INTEGER,
            current_date,
            EXTRACT(YEAR FROM current_date)::INTEGER,
            EXTRACT(QUARTER FROM current_date)::INTEGER,
            EXTRACT(MONTH FROM current_date)::INTEGER,
            TO_CHAR(current_date, 'Month'),
            EXTRACT(WEEK FROM current_date)::INTEGER,
            EXTRACT(DOY FROM current_date)::INTEGER,
            EXTRACT(DAY FROM current_date)::INTEGER,
            EXTRACT(DOW FROM current_date)::INTEGER,
            TO_CHAR(current_date, 'Day'),
            EXTRACT(DOW FROM current_date) IN (0, 6)
        )
        ON CONFLICT (date_key) DO NOTHING;
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
    
    RAISE NOTICE 'Dimensão de tempo populada de % até %', start_date, end_date;
END;
$$ language 'plpgsql';

-- Função para calcular KPIs diários
CREATE OR REPLACE FUNCTION calculate_daily_kpis(target_date DATE DEFAULT CURRENT_DATE)
RETURNS void AS $$
DECLARE
    current_date_key INTEGER;
BEGIN
    current_date_key := TO_CHAR(target_date, 'YYYYMMDD')::INTEGER;
    
    -- Calcular OTIF por fornecedor
    INSERT INTO analytics.kpi_summary (date_key, company_id, kpi_category, kpi_name, kpi_value, kpi_unit)
    SELECT 
        current_date_key,
        s.company_id,
        'supplier',
        'otif_rate',
        COALESCE(
            (COUNT(CASE WHEN po.po_status = 'completed' AND po.updated_at <= po.expected_delivery_date THEN 1 END) * 100.0) / 
            NULLIF(COUNT(CASE WHEN po.po_status = 'completed' THEN 1 END), 0),
            0
        ),
        '%'
    FROM suppliers.suppliers s
    LEFT JOIN suppliers.purchase_orders po ON s.id = po.supplier_id 
        AND po.po_date >= target_date - INTERVAL '30 days'
        AND po.po_date <= target_date
    WHERE s.is_active = true
    GROUP BY s.company_id, s.id
    HAVING COUNT(po.id) > 0
    ON CONFLICT (date_key, company_id, kpi_category, kpi_name) 
    DO UPDATE SET kpi_value = EXCLUDED.kpi_value;
    
    -- Calcular giro de estoque por armazém
    INSERT INTO analytics.kpi_summary (date_key, company_id, kpi_category, kpi_name, kpi_value, kpi_unit)
    SELECT 
        current_date_key,
        w.company_id,
        'inventory',
        'inventory_turnover',
        CASE 
            WHEN AVG(sb.available_quantity) > 0 
            THEN SUM(ABS(sm.quantity)) / AVG(sb.available_quantity)
            ELSE 0 
        END,
        'times'
    FROM core.warehouses w
    JOIN inventory.stock_balances sb ON w.id = sb.warehouse_id
    LEFT JOIN inventory.stock_movements sm ON sb.product_id = sm.product_id 
        AND sm.warehouse_id = sb.warehouse_id
        AND sm.movement_date >= target_date - INTERVAL '30 days'
        AND sm.movement_date <= target_date
    WHERE w.is_active = true
    GROUP BY w.company_id, w.id
    ON CONFLICT (date_key, company_id, kpi_category, kpi_name) 
    DO UPDATE SET kpi_value = EXCLUDED.kpi_value;
    
    -- Calcular acuracidade de inventário
    INSERT INTO analytics.kpi_summary (date_key, company_id, kpi_category, kpi_name, kpi_value, kpi_unit)
    SELECT 
        current_date_key,
        w.company_id,
        'inventory',
        'inventory_accuracy',
        CASE 
            WHEN COUNT(ic.id) > 0
            THEN (COUNT(CASE WHEN ABS(ic.variance_percentage) <= 2 THEN 1 END) * 100.0) / COUNT(ic.id)
            ELSE 100
        END,
        '%'
    FROM core.warehouses w
    LEFT JOIN inventory.inventory_counts ic ON w.id = ic.warehouse_id
        AND ic.count_date >= target_date - INTERVAL '7 days'
        AND ic.count_date <= target_date
        AND ic.count_status = 'approved'
    WHERE w.is_active = true
    GROUP BY w.company_id, w.id
    ON CONFLICT (date_key, company_id, kpi_category, kpi_name) 
    DO UPDATE SET kpi_value = EXCLUDED.kpi_value;
    
    RAISE NOTICE 'KPIs calculados para a data %', target_date;
END;
$$ language 'plpgsql';

-- =====================================================
-- FUNÇÕES DE MANUTENÇÃO
-- =====================================================

-- Função para limpeza de dados antigos
CREATE OR REPLACE FUNCTION maintenance_cleanup_old_data()
RETURNS void AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Limpar logs de auditoria antigos (manter 2 anos)
    DELETE FROM audit.audit_log 
    WHERE timestamp < CURRENT_DATE - INTERVAL '2 years';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Removidos % registros de auditoria antigos', deleted_count;
    
    -- Limpar KPIs antigos (manter 3 anos)
    DELETE FROM analytics.kpi_summary 
    WHERE date_key < TO_CHAR(CURRENT_DATE - INTERVAL '3 years', 'YYYYMMDD')::INTEGER;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Removidos % registros de KPIs antigos', deleted_count;
    
    -- Atualizar estatísticas das tabelas
    ANALYZE;
    
    RAISE NOTICE 'Limpeza de dados concluída em %', CURRENT_TIMESTAMP;
END;
$$ language 'plpgsql';

-- Função para recalcular KPIs em período
CREATE OR REPLACE FUNCTION maintenance_recalculate_kpis(start_date DATE, end_date DATE)
RETURNS void AS $$
DECLARE
    current_date DATE;
    date_key_to_delete INTEGER;
BEGIN
    current_date := start_date;
    
    WHILE current_date <= end_date LOOP
        date_key_to_delete := TO_CHAR(current_date, 'YYYYMMDD')::INTEGER;
        
        -- Limpar KPIs existentes para a data
        DELETE FROM analytics.kpi_summary 
        WHERE date_key = date_key_to_delete;
        
        -- Recalcular KPIs para a data
        PERFORM calculate_daily_kpis(current_date);
        
        current_date := current_date + INTERVAL '1 day';
    END LOOP;
    
    RAISE NOTICE 'Recálculo de KPIs concluído para período % a %', start_date, end_date;
END;
$$ language 'plpgsql';

-- =====================================================
-- FUNÇÕES DE VALIDAÇÃO DE NEGÓCIO
-- =====================================================

-- Função para validar CNPJ
CREATE OR REPLACE FUNCTION validate_cnpj(cnpj_input TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    cnpj TEXT;
    digits INTEGER[];
    sum1 INTEGER := 0;
    sum2 INTEGER := 0;
    digit1 INTEGER;
    digit2 INTEGER;
    i INTEGER;
BEGIN
    -- Remover caracteres não numéricos
    cnpj := regexp_replace(cnpj_input, '[^0-9]', '', 'g');
    
    -- Verificar se tem 14 dígitos
    IF length(cnpj) != 14 THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar se não são todos iguais
    IF cnpj ~ '^(.)\1*$' THEN
        RETURN FALSE;
    END IF;
    
    -- Converter para array de inteiros
    FOR i IN 1..14 LOOP
        digits[i] := substring(cnpj, i, 1)::INTEGER;
    END LOOP;
    
    -- Calcular primeiro dígito verificador
    FOR i IN 1..12 LOOP
        sum1 := sum1 + digits[i] * (CASE WHEN i <= 4 THEN 5 - i + 1 ELSE 13 - i + 1 END);
    END LOOP;
    
    digit1 := CASE WHEN sum1 % 11 < 2 THEN 0 ELSE 11 - (sum1 % 11) END;
    
    -- Calcular segundo dígito verificador
    FOR i IN 1..13 LOOP
        sum2 := sum2 + digits[i] * (CASE WHEN i <= 5 THEN 6 - i + 1 ELSE 14 - i + 1 END);
    END LOOP;
    
    digit2 := CASE WHEN sum2 % 11 < 2 THEN 0 ELSE 11 - (sum2 % 11) END;
    
    -- Verificar dígitos
    RETURN digits[13] = digit1 AND digits[14] = digit2;
END;
$$ language 'plpgsql';

-- Função para validar CPF
CREATE OR REPLACE FUNCTION validate_cpf(cpf_input TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    cpf TEXT;
    digits INTEGER[];
    sum1 INTEGER := 0;
    sum2 INTEGER := 0;
    digit1 INTEGER;
    digit2 INTEGER;
    i INTEGER;
BEGIN
    -- Remover caracteres não numéricos
    cpf := regexp_replace(cpf_input, '[^0-9]', '', 'g');
    
    -- Verificar se tem 11 dígitos
    IF length(cpf) != 11 THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar se não são todos iguais
    IF cpf ~ '^(.)\1*$' THEN
        RETURN FALSE;
    END IF;
    
    -- Converter para array de inteiros
    FOR i IN 1..11 LOOP
        digits[i] := substring(cpf, i, 1)::INTEGER;
    END LOOP;
    
    -- Calcular primeiro dígito verificador
    FOR i IN 1..9 LOOP
        sum1 := sum1 + digits[i] * (10 - i + 1);
    END LOOP;
    
    digit1 := CASE WHEN sum1 % 11 < 2 THEN 0 ELSE 11 - (sum1 % 11) END;
    
    -- Calcular segundo dígito verificador
    FOR i IN 1..10 LOOP
        sum2 := sum2 + digits[i] * (11 - i + 1);
    END LOOP;
    
    digit2 := CASE WHEN sum2 % 11 < 2 THEN 0 ELSE 11 - (sum2 % 11) END;
    
    -- Verificar dígitos
    RETURN digits[10] = digit1 AND digits[11] = digit2;
END;
$$ language 'plpgsql';

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO
-- =====================================================

-- Trigger para validar CNPJ de empresas
CREATE OR REPLACE FUNCTION validate_company_cnpj()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT validate_cnpj(NEW.tax_id) THEN
        RAISE EXCEPTION 'CNPJ inválido: %', NEW.tax_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER validate_company_cnpj_trigger
    BEFORE INSERT OR UPDATE ON core.companies
    FOR EACH ROW EXECUTE FUNCTION validate_company_cnpj();

-- Trigger para validar CNPJ de fornecedores
CREATE TRIGGER validate_supplier_cnpj_trigger
    BEFORE INSERT OR UPDATE ON suppliers.suppliers
    FOR EACH ROW EXECUTE FUNCTION validate_company_cnpj();

-- =====================================================
-- VIEWS MATERIALIZADAS
-- =====================================================

-- View materializada para saldos de estoque atuais
CREATE MATERIALIZED VIEW analytics.mv_current_stock_balances AS
SELECT 
    sb.warehouse_id,
    w.name as warehouse_name,
    sb.product_id,
    p.sku,
    p.name as product_name,
    pc.name as category_name,
    SUM(sb.available_quantity) as total_available,
    SUM(sb.reserved_quantity) as total_reserved,
    SUM(sb.quarantine_quantity) as total_quarantine,
    MAX(sb.last_movement_date) as last_movement_date,
    COUNT(*) as location_count
FROM inventory.stock_balances sb
JOIN core.warehouses w ON sb.warehouse_id = w.id
JOIN core.products p ON sb.product_id = p.id
LEFT JOIN core.product_categories pc ON p.category_id = pc.id
WHERE sb.available_quantity > 0 OR sb.reserved_quantity > 0 OR sb.quarantine_quantity > 0
GROUP BY sb.warehouse_id, w.name, sb.product_id, p.sku, p.name, pc.name;

-- Índices para a view materializada
CREATE UNIQUE INDEX idx_mv_stock_balances_unique ON analytics.mv_current_stock_balances(warehouse_id, product_id);
CREATE INDEX idx_mv_stock_balances_sku ON analytics.mv_current_stock_balances(sku);
CREATE INDEX idx_mv_stock_balances_warehouse ON analytics.mv_current_stock_balances(warehouse_id);

-- View materializada para performance de fornecedores
CREATE MATERIALIZED VIEW analytics.mv_supplier_performance_summary AS
SELECT 
    s.id as supplier_id,
    s.legal_name,
    s.supplier_classification,
    COUNT(po.id) as total_orders,
    COUNT(CASE WHEN po.po_status = 'completed' THEN 1 END) as completed_orders,
    ROUND(AVG(EXTRACT(days FROM po.updated_at - po.po_date)), 2) as avg_lead_time_days,
    ROUND(AVG(se.overall_score), 2) as avg_evaluation_score,
    SUM(po.total_amount) as total_order_value,
    MAX(po.po_date) as last_order_date,
    COUNT(CASE WHEN po.po_status = 'completed' AND po.updated_at <= po.expected_delivery_date THEN 1 END) as on_time_deliveries,
    ROUND(
        (COUNT(CASE WHEN po.po_status = 'completed' AND po.updated_at <= po.expected_delivery_date THEN 1 END) * 100.0) / 
        NULLIF(COUNT(CASE WHEN po.po_status = 'completed' THEN 1 END), 0),
        2
    ) as otif_percentage
FROM suppliers.suppliers s
LEFT JOIN suppliers.purchase_orders po ON s.id = po.supplier_id
LEFT JOIN suppliers.supplier_evaluations se ON s.id = se.supplier_id 
    AND se.status = 'approved'
WHERE s.is_active = true
GROUP BY s.id, s.legal_name, s.supplier_classification;

-- Índices para a view materializada
CREATE UNIQUE INDEX idx_mv_supplier_performance_unique ON analytics.mv_supplier_performance_summary(supplier_id);
CREATE INDEX idx_mv_supplier_performance_classification ON analytics.mv_supplier_performance_summary(supplier_classification);

-- =====================================================
-- FUNÇÃO PARA REFRESH DAS VIEWS MATERIALIZADAS
-- =====================================================

CREATE OR REPLACE FUNCTION maintenance_refresh_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_current_stock_balances;
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_supplier_performance_summary;
    
    RAISE NOTICE 'Views materializadas atualizadas em %', CURRENT_TIMESTAMP;
END;
$$ language 'plpgsql';

-- =====================================================
-- INICIALIZAÇÃO
-- =====================================================

-- Popular dimensão de tempo para os próximos 3 anos
SELECT populate_dim_time(CURRENT_DATE - INTERVAL '1 year', CURRENT_DATE + INTERVAL '2 years');

-- Calcular KPIs iniciais
SELECT calculate_daily_kpis();

-- Refresh inicial das views materializadas
SELECT maintenance_refresh_materialized_views();

-- =====================================================
-- FINALIZAÇÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Funções e triggers do Sistema de Gestão Logística criados com sucesso!';
    RAISE NOTICE 'Funcionalidades implementadas:';
    RAISE NOTICE '- Triggers de auditoria automática';
    RAISE NOTICE '- Controle automático de saldos de estoque';
    RAISE NOTICE '- Validação de documentos (CPF/CNPJ)';
    RAISE NOTICE '- Cálculo automático de KPIs';
    RAISE NOTICE '- Views materializadas para performance';
    RAISE NOTICE '- Funções de manutenção e limpeza';
    RAISE NOTICE 'Sistema pronto para uso!';
END $$;

