/// Configuración centralizada de Supabase
/// 
/// Este archivo contiene todas las constantes de configuración
/// para conectarse a Supabase.
class SupabaseConfig {
  /// URL de Supabase
  static const String url = 'https://ggnarccdneorkhyrlniq.supabase.co';
  
  /// Anon Key de Supabase
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdnbmFyY2NkbmVvcmtoeXJsbmlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MDg2NDEsImV4cCI6MjEwNDI4NDY0MX0.xhqAtIA4WjH1jfmodv5YKNdRRvAcUfLABqN6Ur1Anro';
  
  /// Nombres de tablas
  static const String productsTable = 'products';
  static const String customersTable = 'customers';
  static const String suppliersTable = 'suppliers';
  static const String salesTable = 'sales';
  static const String saleItemsTable = 'sale_items';
  static const String purchasesTable = 'purchases';
  static const String purchaseItemsTable = 'purchase_items';
  static const String paymentsTable = 'payments';
  static const String movementsTable = 'movements';
}
