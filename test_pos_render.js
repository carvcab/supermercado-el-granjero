// Mock the DOM environment
const bridgeData = {
  "categorias":[{"orden":0,"color":"#059669","productos_count":1,"nombre":"holaf","id":2,"descripcion":"","created_at":"2026-06-29T03:30:16.500Z"}],
  "productos":[{"updated_at":"2026-06-29T03:06:19.202Z","nombre":"joder","categoria_id":2,"precio_compra":120,"es_alcohol":false,"precio_venta":1000,"created_at":"2026-06-29T03:05:13.516Z","id":1,"stock_minimo":2,"codigo_barras":"","stock_actual":12,"codigo":"P0001","marca_id":null,"unidad_medida":"und","categoria_nombre":"holaf"}],
  "clientes":[],
  "proveedores":[],
  "ventas":[],
  "cajas":[]
};

global.localStorage = {
  getItem: () => JSON.stringify(bridgeData),
  setItem: () => {}
};

global.window = {};
global.firebase = {
  auth: () => ({ onAuthStateChanged: () => {} })
};

// Load api-bridge
require('./js/api-bridge.js');

// Mock DOM elements
const searchInput = { value: '' };
const filterSelect = { value: '' };
const gridDiv = { innerHTML: '' };

global.document = {
  getElementById: (id) => {
    if (id === 'searchProducto' || id === 'barSearchProducto') return searchInput;
    if (id === 'filterCategoria') return filterSelect;
    if (id === 'productGrid' || id === 'barProductGrid') return gridDiv;
    return null;
  }
};

// Mock global variables for index.html
global.productos = bridgeData.productos;
global.categorias = bridgeData.categorias;
global.carrito = [];

// Helper functions from index.html
global.getUnidadProd = function(p) {
  return p.unidad_medida || p.unidad || 'und';
};

// Mock Helpers.escapeHtml and formatMoney
global.Helpers = global.window.Helpers;

// Define renderProductos and filtrarProductos
global.renderProductos = function(lista) {
  var grid = document.getElementById('productGrid');
  if (!lista.length) { grid.innerHTML = 'empty'; return; }
  var htmlProd = '';
  for (var pi = 0; pi < lista.length; pi++) {
    var p = lista[pi];
    var enCarrito = null;
    var stockReal = p.stock_actual != null ? p.stock_actual : (p.stock != null ? p.stock : 0);
    var stockEnCarrito = 0;
    var stock = stockReal - stockEnCarrito;
    var minStock = p.stock_minimo || 5;
    var agotado = stockReal <= 0 || stock <= 0;
    var cardStockClass = agotado ? 'stock-empty' : (stockReal <= minStock ? 'stock-alert' : 'stock-normal');
    
    // Check safeName replacement
    var safeName = Helpers.escapeHtml(p.nombre).replace(/'/g, "\\'");
    var unidad = getUnidadProd(p);
    var unidadLabel = unidad;
    
    htmlProd += '<div class="pos-product-btn ' + cardStockClass + '">';
    htmlProd += '<div class="name">' + Helpers.escapeHtml(p.nombre) + '</div>';
    htmlProd += '<div class="price">' + Helpers.formatMoney(p.precio_venta) + '</div>';
    htmlProd += '</div>';
  }
  grid.innerHTML = htmlProd;
};

global.filtrarProductos = function() {
  var q = document.getElementById('searchProducto').value.toLowerCase();
  var catId = document.getElementById('filterCategoria').value;
  var filtrados = [];
  for (var pi = 0; pi < productos.length; pi++) {
    var p = productos[pi];
    if (q && (p.nombre || '').toLowerCase().indexOf(q) === -1 && (p.codigo || '').toLowerCase().indexOf(q) === -1) continue;
    if (catId && String(p.categoria_id) !== catId) continue;
    filtrados.push(p);
  }
  renderProductos(filtrados);
};

try {
  console.log("Running filtrarProductos...");
  global.filtrarProductos();
  console.log("HTML Output:", gridDiv.innerHTML);
} catch(e) {
  console.log("CRASH ERROR:", e);
}
