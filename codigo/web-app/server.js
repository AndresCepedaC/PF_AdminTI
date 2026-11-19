const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Configuración de la base de datos PostgreSQL
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  user: process.env.DB_USER || 'techmarket_admin',
  password: process.env.DB_PASSWORD || 'TechMarket2026Secure!',
  database: process.env.DB_NAME || 'techmarket_db',
  connectionTimeoutMillis: 3000,
};

const pool = new Pool(dbConfig);
let isDbConnected = false;

// Datos de catálogo semilla
const initialProducts = [
  {
    name: "MacBook Pro 14' M3 Pro (18GB / 512GB SSD)",
    category: "Laptops & Equipos",
    origin: "USA (Miami)",
    price_cop: 9450000,
    stock: 14,
    sku: "USA-APL-MBP14M3",
    description: "Importación directa de distribuidor autorizado en Florida. Teclado en inglés, garantía global de 1 año."
  },
  {
    name: "ThinkPad T14s Gen 4 AMD Ryzen 7 PRO",
    category: "Laptops & Equipos",
    origin: "USA (Los Ángeles)",
    price_cop: 5200000,
    stock: 22,
    sku: "USA-LNV-T14SG4",
    description: "Portátil corporativo de alta durabilidad militar, 32GB LPDDR5x, 1TB NVMe, chasis de magnesio y carbono."
  },
  {
    name: "Tarjeta de Video NVIDIA GeForce RTX 4070 Ti Super 16GB",
    category: "Componentes & GPU",
    origin: "China (Shenzhen)",
    price_cop: 4350000,
    stock: 18,
    sku: "CHN-NV-4070TIS",
    description: "Edición triple ventilador, arquitectura Ada Lovelace, DLSS 3.5, ideal para render 3D e inteligencia artificial."
  },
  {
    name: "Procesador AMD Ryzen 9 7950X3D (16 Núcleos / 32 Hilos)",
    category: "Componentes & GPU",
    origin: "USA (Miami)",
    price_cop: 2850000,
    stock: 12,
    sku: "USA-AMD-7950X3D",
    description: "Tecnología 3D V-Cache de 128MB, socket AM5, soporte PCIe Gen 5."
  },
  {
    name: "Teclado Mecánico Custom Keychron Q1 Pro QMK/VIA",
    category: "Periféricos & Accesorios",
    origin: "China (Guangzhou)",
    price_cop: 890000,
    stock: 35,
    sku: "CHN-KCH-Q1PRO",
    description: "Cuerpo de aluminio CNC anodizado, switches Gateron Jupiter Banana, conectividad Bluetooth 5.1 y cable tipo C."
  },
  {
    name: "Smartphone Xiaomi 14 Ultra 5G (16GB RAM / 512GB)",
    category: "Móviles & Gadgets",
    origin: "China (Shenzhen)",
    price_cop: 4600000,
    stock: 16,
    sku: "CHN-XMI-14U512",
    description: "Óptica Leica Summilux de 1 pulgada, sensor LYT-900, Snapdragon 8 Gen 3, carga ultra rápida 90W."
  },
  {
    name: "SSD Samsung 990 PRO 2TB NVMe M.2 con Heatsink",
    category: "Almacenamiento",
    origin: "USA (Miami)",
    price_cop: 890000,
    stock: 45,
    sku: "USA-SAM-990P2TB",
    description: "Velocidades secuenciales de lectura hasta 7450 MB/s, compatible con PC y PlayStation 5."
  },
  {
    name: "Sistema Mesh WiFi 7 TP-Link Deco BE85 (Pack x2)",
    category: "Redes & Conectividad",
    origin: "China (Shenzhen)",
    price_cop: 3200000,
    stock: 8,
    sku: "CHN-TPL-DECBE85",
    description: "Velocidades tri-banda hasta 22 Gbps, puertos 10Gbps Ethernet/SFP+, cobertura de hasta 650 m²."
  }
];

// Inicializar tabla y datos en PostgreSQL
async function initDatabase() {
  try {
    const client = await pool.connect();
    isDbConnected = true;
    console.log('[DB] Conectado exitosamente a PostgreSQL (TechMarket DB).');

    await client.query(`
      CREATE TABLE IF NOT EXISTS productos (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        category VARCHAR(100) NOT NULL,
        origin VARCHAR(100) NOT NULL,
        price_cop NUMERIC(12, 2) NOT NULL,
        stock INT NOT NULL DEFAULT 0,
        sku VARCHAR(50) UNIQUE NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    const countRes = await client.query('SELECT COUNT(*) FROM productos;');
    if (parseInt(countRes.rows[0].count, 10) === 0) {
      console.log('[DB] Poblando catálogo inicial de TechMarket...');
      for (const prod of initialProducts) {
        await client.query(`
          INSERT INTO productos (name, category, origin, price_cop, stock, sku, description)
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          ON CONFLICT (sku) DO NOTHING;
        `, [prod.name, prod.category, prod.origin, prod.price_cop, prod.stock, prod.sku, prod.description]);
      }
      console.log('[DB] Catálogo inicial sembrado correctamente.');
    }
    client.release();
  } catch (err) {
    isDbConnected = false;
    console.warn('[DB Advertencia] No se pudo conectar inmediatamente a PostgreSQL:', err.message);
    console.warn('[DB Advertencia] La aplicación operará en modo de catálogo en memoria.');
  }
}

initDatabase();

// Rutas de API
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    app: 'TechMarket S.A.S. - Portal Corporativo',
    database_connected: isDbConnected,
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'production'
  });
});

app.get('/api/productos', async (req, res) => {
  if (isDbConnected) {
    try {
      const result = await pool.query('SELECT * FROM productos ORDER BY id ASC;');
      return res.json({ source: 'PostgreSQL Database', count: result.rows.length, data: result.rows });
    } catch (err) {
      console.error('[Error SQL]', err.message);
    }
  }
  // Fallback si la DB está arrancando
  res.json({ source: 'Memoria Local (Fallback)', count: initialProducts.length, data: initialProducts });
});

app.post('/api/productos', async (req, res) => {
  const { name, category, origin, price_cop, stock, sku, description } = req.body;
  if (!name || !price_cop || !sku) {
    return res.status(400).json({ error: 'Campos requeridos faltantes (name, price_cop, sku)' });
  }

  if (isDbConnected) {
    try {
      const result = await pool.query(`
        INSERT INTO productos (name, category, origin, price_cop, stock, sku, description)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *;
      `, [name, category || 'Tecnología General', origin || 'USA/China', price_cop, stock || 0, sku, description || '']);
      return res.status(201).json({ message: 'Producto registrado en PostgreSQL', data: result.rows[0] });
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  } else {
    const newProd = { id: initialProducts.length + 1, name, category, origin, price_cop, stock, sku, description };
    initialProducts.push(newProd);
    return res.status(201).json({ message: 'Producto registrado en memoria', data: newProd });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[TechMarket Web] Servidor en ejecución en http://0.0.0.0:${PORT}`);
});
