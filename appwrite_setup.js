/**
 * Script de configuración para Appwrite
 * Ejecutar con: node appwrite_setup.js
 * 
 * Requiere: npm install node-appwrite
 * 
 * Variables de entorno necesarias:
 * APPWRITE_ENDPOINT=https://nyc.cloud.appwrite.io/v1
 * APPWRITE_PROJECT_ID=6a9c5bf90011def035f4
 * APPWRITE_API_KEY=YOUR_API_KEY
 */

const { Client, Databases, ID } = require('node-appwrite');

// Configuración
const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://nyc.cloud.appwrite.io/v1')
    .setProject(process.env.APPWRITE_PROJECT_ID || '6a9c5bf90011def035f4')
    .setKey(process.env.APPWRITE_API_KEY);

const databases = new Databases(client);

const DATABASE_ID = 'inventario';

// Definición de collections
const collections = [
    {
        name: 'products',
        id: 'products',
        attributes: [
            { key: 'name', type: 'string', size: 255, required: true },
            { key: 'description', type: 'string', size: 1000, required: false },
            { key: 'quantity', type: 'integer', required: true, default: 0 },
            { key: 'purchasePrice', type: 'double', required: true, default: 0 },
            { key: 'salePrice', type: 'double', required: true, default: 0 },
            { key: 'minStock', type: 'integer', required: true, default: 0 },
        ],
        indexes: [
            { key: 'idx_name', type: 'key', attributes: ['name'], orders: ['ASC'] },
            { key: 'idx_quantity', type: 'key', attributes: ['quantity'], orders: ['ASC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    },
    {
        name: 'customers',
        id: 'customers',
        attributes: [
            { key: 'name', type: 'string', size: 255, required: true },
            { key: 'phone', type: 'string', size: 50, required: false },
            { key: 'pendingBalance', type: 'double', required: true, default: 0 },
        ],
        indexes: [
            { key: 'idx_name', type: 'key', attributes: ['name'], orders: ['ASC'] },
            { key: 'idx_pendingBalance', type: 'key', attributes: ['pendingBalance'], orders: ['DESC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    },
    {
        name: 'suppliers',
        id: 'suppliers',
        attributes: [
            { key: 'name', type: 'string', size: 255, required: true },
            { key: 'phone', type: 'string', size: 50, required: false },
            { key: 'address', type: 'string', size: 500, required: false },
        ],
        indexes: [
            { key: 'idx_name', type: 'key', attributes: ['name'], orders: ['ASC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    },
    {
        name: 'sales',
        id: 'sales',
        attributes: [
            { key: 'customerId', type: 'string', size: 255, required: false },
            { key: 'date', type: 'datetime', required: true },
            { key: 'subtotal', type: 'double', required: true, default: 0 },
            { key: 'total', type: 'double', required: true, default: 0 },
            { key: 'notes', type: 'string', size: 1000, required: false },
        ],
        indexes: [
            { key: 'idx_date', type: 'key', attributes: ['date'], orders: ['DESC'] },
            { key: 'idx_customerId', type: 'key', attributes: ['customerId'], orders: ['ASC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    },
    {
        name: 'sale_items',
        id: 'sale_items',
        attributes: [
            { key: 'saleId', type: 'string', size: 255, required: true },
            { key: 'productId', type: 'string', size: 255, required: true },
            { key: 'quantity', type: 'integer', required: true },
            { key: 'unitPrice', type: 'double', required: true },
            { key: 'total', type: 'double', required: true },
        ],
        indexes: [
            { key: 'idx_saleId', type: 'key', attributes: ['saleId'], orders: ['ASC'] },
            { key: 'idx_productId', type: 'key', attributes: ['productId'], orders: ['ASC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    },
    {
        name: 'purchases',
        id: 'purchases',
        attributes: [
            { key: 'supplierId', type: 'string', size: 255, required: true },
            { key: 'date', type: 'datetime', required: true },
            { key: 'total', type: 'double', required: true, default: 0 },
            { key: 'notes', type: 'string', size: 1000, required: false },
        ],
        indexes: [
            { key: 'idx_date', type: 'key', attributes: ['date'], orders: ['DESC'] },
            { key: 'idx_supplierId', type: 'key', attributes: ['supplierId'], orders: ['ASC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    },
    {
        name: 'purchase_items',
        id: 'purchase_items',
        attributes: [
            { key: 'purchaseId', type: 'string', size: 255, required: true },
            { key: 'productId', type: 'string', size: 255, required: true },
            { key: 'quantity', type: 'integer', required: true },
            { key: 'unitPrice', type: 'double', required: true },
            { key: 'total', type: 'double', required: true },
        ],
        indexes: [
            { key: 'idx_purchaseId', type: 'key', attributes: ['purchaseId'], orders: ['ASC'] },
            { key: 'idx_productId', type: 'key', attributes: ['productId'], orders: ['ASC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    },
    {
        name: 'payments',
        id: 'payments',
        attributes: [
            { key: 'customerId', type: 'string', size: 255, required: true },
            { key: 'amount', type: 'double', required: true },
            { key: 'date', type: 'datetime', required: true },
            { key: 'notes', type: 'string', size: 1000, required: false },
        ],
        indexes: [
            { key: 'idx_date', type: 'key', attributes: ['date'], orders: ['DESC'] },
            { key: 'idx_customerId', type: 'key', attributes: ['customerId'], orders: ['ASC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    },
    {
        name: 'movements',
        id: 'movements',
        attributes: [
            { key: 'type', type: 'string', size: 50, required: true },
            { key: 'description', type: 'string', size: 500, required: true },
            { key: 'date', type: 'datetime', required: true },
            { key: 'amount', type: 'double', required: false },
            { key: 'relatedId', type: 'string', size: 255, required: false },
        ],
        indexes: [
            { key: 'idx_date', type: 'key', attributes: ['date'], orders: ['DESC'] },
            { key: 'idx_type', type: 'key', attributes: ['type'], orders: ['ASC'] },
        ],
        permissions: [
            'read("any")',
            'create("any")',
            'update("any")',
            'delete("any")',
        ]
    }
];

async function setupDatabase() {
    try {
        console.log('🚀 Iniciando configuración de Appwrite...');
        console.log(`📦 Database ID: ${DATABASE_ID}`);
        console.log(`🔗 Endpoint: ${process.env.APPWRITE_ENDPOINT}`);
        console.log(`🆔 Project ID: ${process.env.APPWRITE_PROJECT_ID}\n`);

        // Eliminar database si existe
        try {
            await databases.get(DATABASE_ID);
            console.log(`🗑️  Database '${DATABASE_ID}' existe, eliminando...`);
            await databases.delete(DATABASE_ID);
            console.log(`✅ Database '${DATABASE_ID}' eliminada\n`);
        } catch (error) {
            if (error.code !== 404) {
                console.log(`⚠️  Error verificando database: ${error.message}`);
            }
        }

        // Crear database
        await databases.create(DATABASE_ID, DATABASE_ID);
        console.log(`✅ Database '${DATABASE_ID}' creada\n`);

        // Crear collections
        for (const collection of collections) {
            try {
                await databases.get(DATABASE_ID, collection.id);
                console.log(`⚠️  Collection '${collection.id}' ya existe, omitiendo...\n`);
            } catch (error) {
                if (error.code === 404) {
                    try {
                        // Crear collection
                        await databases.create(
                            DATABASE_ID,
                            collection.id,
                            collection.name,
                            collection.permissions
                        );
                        console.log(`✅ Collection '${collection.id}' creada`);

                        // Crear atributos
                        for (const attr of collection.attributes) {
                            try {
                                await databases.createAttribute(
                                    DATABASE_ID,
                                    collection.id,
                                    attr.key,
                                    attr.type,
                                    attr.size,
                                    attr.required,
                                    attr.default,
                                    null, // array (no usado)
                                    null, // format (no usado)
                                    null  // defaultValue (no usado)
                                );
                                console.log(`   ✅ Atributo '${attr.key}' (${attr.type}) creado`);
                            } catch (attrError) {
                                console.log(`   ⚠️  Error creando atributo '${attr.key}': ${attrError.message}`);
                            }
                        }

                        // Crear índices
                        for (const index of collection.indexes) {
                            try {
                                await databases.createIndex(
                                    DATABASE_ID,
                                    collection.id,
                                    index.key,
                                    index.type,
                                    index.attributes,
                                    index.orders
                                );
                                console.log(`   ✅ Índice '${index.key}' creado`);
                            } catch (indexError) {
                                console.log(`   ⚠️  Error creando índice '${index.key}': ${indexError.message}`);
                            }
                        }

                        console.log('');
                    } catch (createError) {
                        console.error(`❌ Error creando collection '${collection.id}':`, createError);
                    }
                } else {
                    throw error;
                }
            }
        }

        console.log('🎉 Configuración completada exitosamente!');
        console.log('\n📊 Resumen:');
        console.log(`   - Database: ${DATABASE_ID}`);
        console.log(`   - Collections: ${collections.length}`);
        console.log('\n🔒 Permisos configurados para acceso desde cualquier dispositivo (any)');
        console.log('⚠️  Para producción, considera restringir permisos según tus necesidades de seguridad.\n');

    } catch (error) {
        console.error('❌ Error durante la configuración:', error);
        process.exit(1);
    }
}

// Ejecutar
setupDatabase();
