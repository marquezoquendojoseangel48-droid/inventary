import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/payment.dart';
import '../models/inventory_movement.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE ${AppConstants.productsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        purchasePrice REAL NOT NULL,
        salePrice REAL NOT NULL,
        minStock INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Suppliers table
    await db.execute('''
      CREATE TABLE ${AppConstants.suppliersTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Purchases table
    await db.execute('''
      CREATE TABLE ${AppConstants.purchasesTable} (
        id TEXT PRIMARY KEY,
        supplierId TEXT NOT NULL,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (supplierId) REFERENCES ${AppConstants.suppliersTable}(id)
      )
    ''');

    // Purchase items table
    await db.execute('''
      CREATE TABLE ${AppConstants.purchaseItemsTable} (
        id TEXT PRIMARY KEY,
        purchaseId TEXT NOT NULL,
        productId TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (purchaseId) REFERENCES ${AppConstants.purchasesTable}(id),
        FOREIGN KEY (productId) REFERENCES ${AppConstants.productsTable}(id)
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE ${AppConstants.customersTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        pendingBalance REAL NOT NULL DEFAULT 0
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE ${AppConstants.salesTable} (
        id TEXT PRIMARY KEY,
        customerId TEXT,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES ${AppConstants.customersTable}(id)
      )
    ''');

    // Sale items table
    await db.execute('''
      CREATE TABLE ${AppConstants.saleItemsTable} (
        id TEXT PRIMARY KEY,
        saleId TEXT NOT NULL,
        productId TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (saleId) REFERENCES ${AppConstants.salesTable}(id),
        FOREIGN KEY (productId) REFERENCES ${AppConstants.productsTable}(id)
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE ${AppConstants.paymentsTable} (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES ${AppConstants.customersTable}(id)
      )
    ''');

    // Movements table
    await db.execute('''
      CREATE TABLE ${AppConstants.movementsTable} (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        amount REAL,
        relatedId TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_products_name ON ${AppConstants.productsTable}(name)');
    await db.execute('CREATE INDEX idx_customers_name ON ${AppConstants.customersTable}(name)');
    await db.execute('CREATE INDEX idx_suppliers_name ON ${AppConstants.suppliersTable}(name)');
    await db.execute('CREATE INDEX idx_movements_date ON ${AppConstants.movementsTable}(date)');
    await db.execute('CREATE INDEX idx_movements_type ON ${AppConstants.movementsTable}(type)');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(String table, Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<T> executeTransaction<T>(Future<T> Function(Transaction) action) async {
    final db = await database;
    return await db.transaction(action);
  }
}
