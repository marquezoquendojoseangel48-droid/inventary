-- ============================================
-- Corregir políticas RLS para permitir escritura
-- ============================================
-- Ejecutar este script en el SQL Editor de Supabase

-- Deshabilitar RLS temporalmente (para desarrollo)
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE purchases DISABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE movements DISABLE ROW LEVEL SECURITY;

-- ============================================
-- Confirmación
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'RLS deshabilitado para todas las tablas';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Ahora la app puede leer y escribir datos';
    RAISE NOTICE '============================================';
END $$;
