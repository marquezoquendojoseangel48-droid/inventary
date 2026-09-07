-- ============================================
-- STOCKIA - Script SQL para Supabase
-- ============================================
-- Ejecutar este script en el SQL Editor de Supabase
-- ============================================

-- Habilitar UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Tablas
-- ============================================

-- Products
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    quantity INTEGER NOT NULL DEFAULT 0,
    purchasePrice DECIMAL(10, 2) NOT NULL DEFAULT 0,
    salePrice DECIMAL(10, 2) NOT NULL DEFAULT 0,
    minStock INTEGER NOT NULL DEFAULT 0,
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updatedAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_quantity ON products(quantity);

-- Customers
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    pendingBalance DECIMAL(10, 2) NOT NULL DEFAULT 0,
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updatedAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_customers_pendingBalance ON customers(pendingBalance DESC);

-- Suppliers
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    address VARCHAR(500),
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updatedAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_suppliers_name ON suppliers(name);

-- Sales
CREATE TABLE sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customerId UUID REFERENCES customers(id) ON DELETE SET NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0,
    notes TEXT,
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updatedAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_sales_date ON sales(date DESC);
CREATE INDEX idx_sales_customerId ON sales(customerId);

-- Sale Items
CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    saleId UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    productId UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    unitPrice DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_sale_items_saleId ON sale_items(saleId);
CREATE INDEX idx_sale_items_productId ON sale_items(productId);

-- Purchases
CREATE TABLE purchases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplierId UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    total DECIMAL(10, 2) NOT NULL DEFAULT 0,
    notes TEXT,
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updatedAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_purchases_date ON purchases(date DESC);
CREATE INDEX idx_purchases_supplierId ON purchases(supplierId);

-- Purchase Items
CREATE TABLE purchase_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchaseId UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
    productId UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    unitPrice DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_purchase_items_purchaseId ON purchase_items(purchaseId);
CREATE INDEX idx_purchase_items_productId ON purchase_items(productId);

-- Payments
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customerId UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    notes TEXT,
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payments_date ON payments(date DESC);
CREATE INDEX idx_payments_customerId ON payments(customerId);

-- Inventory Movements
CREATE TABLE movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL,
    description VARCHAR(500) NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    amount DECIMAL(10, 2),
    relatedId UUID,
    createdAt TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_movements_date ON movements(date DESC);
CREATE INDEX idx_movements_type ON movements(type);

-- ============================================
-- Triggers para updatedAt automático
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updatedAt = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_updated_at BEFORE UPDATE ON sales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchases_updated_at BEFORE UPDATE ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Row Level Security (RLS)
-- ============================================

-- Habilitar RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE movements ENABLE ROW LEVEL SECURITY;

-- Políticas para permitir acceso público (para desarrollo)
-- NOTA: En producción, restringir según tus necesidades de seguridad

CREATE POLICY "Enable all access for products" ON products
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for customers" ON customers
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for suppliers" ON suppliers
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for sales" ON sales
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for sale_items" ON sale_items
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for purchases" ON purchases
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for purchase_items" ON purchase_items
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for payments" ON payments
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for movements" ON movements
    FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- Funciones útiles
-- ============================================

-- Función para obtener productos con bajo stock
CREATE OR REPLACE FUNCTION get_low_stock_products()
RETURNS TABLE (
    id UUID,
    name VARCHAR(255),
    quantity INTEGER,
    minStock INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, p.quantity, p.minStock
    FROM products p
    WHERE p.quantity <= p.minStock
    ORDER BY p.quantity ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Finalización
-- ============================================

-- Confirmación
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'STOCKIA - Setup completado exitosamente';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Tablas creadas: 9';
    RAISE NOTICE '- products';
    RAISE NOTICE '- customers';
    RAISE NOTICE '- suppliers';
    RAISE NOTICE '- sales';
    RAISE NOTICE '- sale_items';
    RAISE NOTICE '- purchases';
    RAISE NOTICE '- purchase_items';
    RAISE NOTICE '- payments';
    RAISE NOTICE '- movements';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'RLS habilitado con acceso público (desarrollo)';
    RAISE NOTICE '============================================';
END $$;
