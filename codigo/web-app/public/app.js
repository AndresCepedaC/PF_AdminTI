let allProducts = [];
let activeCategory = 'all';

// Elementos del DOM
const productsGrid = document.getElementById('productsGrid');
const searchInput = document.getElementById('searchInput');
const categoryButtons = document.querySelectorAll('.filter-btn');
const statTotal = document.getElementById('stat-total-items');
const statSource = document.getElementById('stat-source');
const dbStatus = document.getElementById('status-db');
const dbLabel = document.getElementById('db-label');
const clockDisplay = document.getElementById('clock-display');

// Modal
const modal = document.getElementById('productModal');
const btnOpenModal = document.getElementById('btnOpenModal');
const btnCloseModal = document.getElementById('btnCloseModal');
const btnCancelModal = document.getElementById('btnCancelModal');
const productForm = document.getElementById('productForm');

// Reloj sincronizado
function updateClock() {
  const now = new Date();
  clockDisplay.textContent = now.toLocaleTimeString('es-CO', { hour12: false }) + ' COT (Stratum 2)';
}
setInterval(updateClock, 1000);
updateClock();

// Formateador de moneda en Pesos Colombianos (COP)
function formatCOP(amount) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0
  }).format(amount);
}

// Cargar estado de salud y conexión a PostgreSQL
async function checkHealth() {
  try {
    const res = await fetch('/api/health');
    const data = await res.json();
    if (data.database_connected) {
      dbStatus.querySelector('.indicator').className = 'indicator live';
      dbLabel.textContent = 'PostgreSQL: Online (5432)';
    } else {
      dbStatus.querySelector('.indicator').className = 'indicator wait';
      dbLabel.textContent = 'PostgreSQL: Local Fallback';
    }
  } catch (err) {
    dbStatus.querySelector('.indicator').className = 'indicator wait';
    dbLabel.textContent = 'Servidor: Sin Conexión';
  }
}

// Cargar catálogo de productos
async function fetchProducts() {
  try {
    const res = await fetch('/api/productos');
    const json = await res.json();
    allProducts = json.data || [];
    statTotal.textContent = allProducts.length;
    statSource.textContent = json.source || 'Base de Datos';
    renderProducts();
  } catch (err) {
    productsGrid.innerHTML = `
      <div style="grid-column: 1/-1; text-align: center; color: #ef4444; padding: 2rem;">
        Error al conectar con la API de TechMarket: ${err.message}
      </div>
    `;
  }
}

// Renderizar tarjetas
function renderProducts() {
  const query = searchInput.value.toLowerCase().trim();
  const filtered = allProducts.filter(item => {
    const matchesCategory = (activeCategory === 'all' || item.category === activeCategory);
    const matchesSearch = item.name.toLowerCase().includes(query) ||
                          item.sku.toLowerCase().includes(query) ||
                          (item.description && item.description.toLowerCase().includes(query));
    return matchesCategory && matchesSearch;
  });

  if (filtered.length === 0) {
    productsGrid.innerHTML = `
      <div style="grid-column: 1/-1; text-align: center; color: #94a3b8; padding: 3rem;">
        No se encontraron productos importados para los criterios seleccionados.
      </div>
    `;
    return;
  }

  productsGrid.innerHTML = filtered.map(item => `
    <article class="product-card">
      <div>
        <div class="card-header">
          <span class="card-category">${item.category}</span>
          <span class="card-origin">${item.origin || 'Importado'}</span>
        </div>
        <h4 class="card-title">${item.name}</h4>
        <div class="card-sku">SKU: ${item.sku}</div>
        <p class="card-desc">${item.description || 'Sin descripción técnica registrada.'}</p>
      </div>
      <div class="card-footer">
        <div class="card-price">${formatCOP(item.price_cop)}</div>
        <div class="card-stock ${item.stock > 10 ? 'stock-in' : 'stock-low'}">
          Stock: ${item.stock} uds
        </div>
      </div>
    </article>
  `).join('');
}

// Event Listeners para Filtros
categoryButtons.forEach(btn => {
  btn.addEventListener('click', () => {
    categoryButtons.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    activeCategory = btn.dataset.category;
    renderProducts();
  });
});

searchInput.addEventListener('input', renderProducts);

// Modal Handlers
btnOpenModal.addEventListener('click', () => modal.classList.add('active'));
const closeModal = () => modal.classList.remove('active');
btnCloseModal.addEventListener('click', closeModal);
btnCancelModal.addEventListener('click', closeModal);
modal.addEventListener('click', (e) => {
  if (e.target === modal) closeModal();
});

// Guardar Producto
productForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const payload = {
    name: document.getElementById('form-name').value,
    category: document.getElementById('form-category').value,
    origin: document.getElementById('form-origin').value,
    price_cop: parseFloat(document.getElementById('form-price').value),
    stock: parseInt(document.getElementById('form-stock').value, 10),
    sku: document.getElementById('form-sku').value,
    description: document.getElementById('form-desc').value
  };

  try {
    const res = await fetch('/api/productos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (res.ok) {
      productForm.reset();
      closeModal();
      await fetchProducts();
    } else {
      const err = await res.json();
      alert('Error al registrar: ' + (err.error || 'Verifique los datos'));
    }
  } catch (err) {
    alert('Fallo de conexión al enviar el producto: ' + err.message);
  }
});

// Inicialización
checkHealth();
fetchProducts();
setInterval(checkHealth, 8000);
