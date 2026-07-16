margin-bottom: 1.5rem;
<div style="font-size: 0.65rem; color: var(--text-muted); text-transform: uppercase; font-weight: 600;">Acciones</div>
<div style="font-size: 0.95rem; font-weight: 800; color: var(--text-dark);" id="profileStatActions">0</div>
.charts-grid {
grid-template-columns: 1fr;
if(col==='proveedores')return this._handleProveedores(method,entidadId,subaccion,data,parts);
if(col==='productos'){
if(method==='PATCH'&&subaccion==='stock')return this._patchStock(entidadId,data);
<!-- Fila 3: Caja del Negocio (Credit Card), Transfers (Movimientos) y Keep Safe! (Sincronizacion) -->
<div style="display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 1.25rem; margin-bottom: 1.5rem;">
if(col==='clientes')return this._crud('clientes',method,entidadId,data);
<div class="card" style="padding: 1.5rem; display: flex; justify-content: space-between; align-items: center; gap: 1.5rem;">
if(col==='marcas')return BridgeDB.get('productos').map(function(p){return p.marca;}).filter(function(v,i,a){return v&&a.indexOf(v)===i;});
if(col==='ventas'){
<h3 style="font-size: 1.15rem; font-weight: 800; color: var(--primary); margin: 0;">Caja del Negocio</h3>
<p style="font-size: 0.85rem; color: var(--text-soft); margin: 8px 0 0 0; line-height: 1.4;">Saldo actual en la caja registradora del negocio. Administre los ingresos, egresos y el cuadre de caja diario de forma centralizada y segura.</p>
if(col==='ventas-bar')return this._handleVentasBar(method,entidadId,subaccion,data,parts);
<button class="btn btn-primary" onclick="switchSection('caja')" style="padding: 0.6rem 1.25rem; font-size: 0.85rem; margin-top: 1.5rem; width: fit-content; display: flex; align-items: center; gap: 0.4rem;"><i class="fas fa-cash-register"></i> Administrar Caja</button>
console.log('cargarDashboard: fetching data...');
if(entidadId&&subaccion==='visita')return this._handleVisita(method,entidadId,data);
if(entidadId&&subaccion==='pagar')return this._handlePagarCompra(entidadId);
<div style="background: linear-gradient(135deg, #1b4d3e, #2c5e43); border-radius: 1.25rem; padding: 1.25rem; color: #ffffff; box-shadow: 0 8px 24px rgba(27,77,62,0.2); width: 280px; height: 165px; display: flex; flex-direction: column; justify-content: space-between; flex-shrink: 0;">
<div style="display: flex; justify-content: space-between; align-items: flex-start;">
<div style="font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.1em; opacity: 0.8; font-weight: 700;">Caja Registradora</div>
<i class="fas fa-microchip" style="font-size: 1.4rem; color: #fef9c3; opacity: 0.85;"></i>
document.getElementById('kpiValorInventario').textContent = Helpers.formatMoney(data.valor_inventario || 0);
<div style="font-size: 1.4rem; font-weight: 800; letter-spacing: 0.05em;" id="walletCardBalance">$0</div>
<div style="display: flex; justify-content: space-between; align-items: flex-end;">
document.getElementById('kpiClientesDeuda').textContent = data.clientes_deuda || 0;
<div style="font-size: 0.55rem; text-transform: uppercase; opacity: 0.6; margin-bottom: 2px; font-weight: 600;">Usuario Activo</div>
document.getElementById('kpiVentasMes').textContent = Helpers.formatMoney(data.ventas_mes || 0);
if(col==='reportes')return this._handleReportes(method,subaccion,entidadId,data);
<div style="font-size: 0.95rem; font-weight: 900; font-style: italic; letter-spacing: -0.02em;">Granjero</div>
var vals = [data.ventas_dia, data.ganancias_dia, data.productos_stock, data.valor_inventario, data.stock_bajo, data.productos_agotados, data.clientes_deuda, data.cuentas_bar, data.ventas_mes];
if(col==='log'){
for (var vi = 0; vi < vals.length; vi++) { if (vals[vi] > maxVal) maxVal = vals[vi]; }
for (var bfi = 0; bfi < barFills.length; bfi++) {
barFills[bfi].style.width = ((vals[bfi] || 0) / maxVal * 100) + '%';
<div class="card" style="padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between;">
return Promise.reject(new Error('API no encontrada'));
<h3 style="font-size: 1rem; font-weight: 800; color: var(--primary); margin: 0 0 1rem 0;">Movimientos de Caja</h3>
<div id="dashboardRecentTransfers" style="display: flex; flex-direction: column; gap: 0.75rem;">
<div style="font-size: 0.8rem; color: var(--text-muted); text-align: center; padding: 1.5rem 0;">Cargando...</div>
window._dashboardCategoriasData = data.ventas_por_categoria;
renderTopProductos(data.top_productos);
renderCategorias(data.ventas_por_categoria);
if(method==='GET')return BridgeDB.get(col);
if(method==='POST')return BridgeDB.create(col,data);
<div class="card" style="padding: 1.5rem; display: flex; flex-direction: column; align-items: center; justify-content: space-between; text-align: center;">
<div style="width: 48px; height: 48px; border-radius: 50%; background: #e2efe0; display: flex; align-items: center; justify-content: center; color: var(--primary); font-size: 1.4rem; margin-top: 0.5rem;"><i class="fas fa-fingerprint"></i></div>
if(method==='DEL'&&id)return BridgeDB.delete(col,id);
return null;
<h4 style="font-size: 1rem; font-weight: 800; color: var(--text-dark); margin: 0.75rem 0 0.25rem 0;">�Datos Seguros!</h4>
<p style="font-size: 0.8rem; color: var(--text-soft); line-height: 1.4; margin: 0;">Respalda tus ventas y productos en la nube de Firebase con un clic.</p>
if (!window.myCharts) { window.myCharts = {}; }
if(!prod)throw new Error('Producto no encontrado');
<button class="btn btn-primary" onclick="subirBackup()" style="width: 100%; padding: 0.6rem; font-size: 0.85rem; display: flex; align-items: center; justify-content: center; gap: 0.4rem;"><i class="fas fa-cloud-upload-alt"></i> Respaldar Ahora</button>
var ctx = document.getElementById('chartCanvasVentasHora');
if (!ctx) return;
if (window.myCharts.ventasHora) { window.myCharts.ventasHora.destroy(); }
<!-- Fila 4: Grafico de ventas por mes, stock bajo y demas reportes consolidados -->
<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.25rem;">
<!-- Ventas por Mes -->
<div class="card" style="padding: 1.5rem;">
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
<span style="font-size: 1.15rem; font-weight: 800; color: var(--primary);">Ventas del A�o por Mes</span>
<span style="font-size: 0.8rem; color: var(--text-soft); font-weight: 600;">Mensual</span>
labels.push(h + ':00');
<div style="height: 220px; position: relative;">
<canvas id="chartCanvasVentasMes"></canvas>
width: 0;
padding: 0;
if (!data || !data.length) {
labels = ['Sin datos'];
<div class="card" style="padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between;">
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
<span style="font-size: 1.15rem; font-weight: 800; color: var(--primary);">Inventario en Alerta</span>
<span class="badge badge-red" id="kpiStockBajoCount" style="font-weight: 700;">0 productos</span>
grad.addColorStop(0, '#073155');
<div style="flex: 1; overflow-y: auto; max-height: 220px;" class="custom-scrollbar">
<table class="w-full">
window.myCharts.ventasHora = new Chart(ctx, {
type: 'bar',
<th style="text-align: left; padding: 0.5rem 0.75rem;">Producto</th>
<th style="text-align: center; padding: 0.5rem 0.75rem;">Stock</th>
<th style="text-align: center; padding: 0.5rem 0.75rem;">M�nimo</th>
label: 'Ventas por Hora ($)',
.sidebar-toggle-btn {
<tbody id="tblLowStock">
<!-- Dynamic low stock list -->
borderWidth: 0,
borderRadius: 8,
barPercentage: 0.7
}]
},
options: {
responsive: true,
maintainAspectRatio: false,
plugins: {
legend: { display: false },
tooltip: {
backgroundColor: '#073155',
titleColor: '#fff',
bodyColor: '#fff',
.sidebar-toggle-btn:hover {
color: #fff;
callbacks: { label: function(context) { return ' ' + Helpers.formatMoney(context.raw); } }
}
},
/* Always show toggle button when sidebar is visible */
y: { beginAtZero: true, grid: { color: '#e0e0e0', drawBorder: false }, ticks: { callback: function(value) { return '$' + value; }, color: '#616161' } },
x: { grid: { display: false }, ticks: { color: '#616161' } }
}
}
.sidebar-logo {
width: 35px;
height: 35px;
function renderVentasMes(data) {
var ctx = document.getElementById('chartCanvasVentasMes');
if (!ctx) return;
if (window.myCharts.ventasMes) { window.myCharts.ventasMes.destroy(); }

var meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
var labels = [];
flex-direction: column;
if (data && data.length) {
for (var vi = 0; vi < data.length; vi++) {
labels.push(meses[(data[vi].mes || 1) - 1]);
dataset.push(data[vi].total);
}
}
.sidebar:hover .sidebar-brand {
if (!data || !data.length) {
labels = ['Sin datos'];
dataset = [0];
}
.sidebar-title {
var colors = ['#073155', '#1a7a2e', '#e65100', '#f9a825', '#c62828', '#00796b'];
font-size: 0.95rem;
window.myCharts.ventasMes = new Chart(ctx, {
type: 'bar',
data: {
labels: labels,
datasets: [{
label: 'Ventas por Mes ($)',
font-size: 0.7rem;
backgroundColor: colors,
borderWidth: 0,
borderRadius: 6,
barPercentage: 0.65
flex: 1;
overflow-y: auto;
options: {
responsive: true,
maintainAspectRatio: false,
plugins: {
legend: { display: false },
.sidebar-nav::-webkit-scrollbar {
backgroundColor: '#1a7a2e',
titleColor: '#fff',
bodyColor: '#fff',
cornerRadius: 8,
display: flex;
callbacks: { label: function(context) { return ' ' + Helpers.formatMoney(context.raw); } }
}
},
scales: {
y: { beginAtZero: true, grid: { color: '#e0e0e0', drawBorder: false }, ticks: { callback: function(value) { return '$' + value; }, color: '#616161' } },
x: { grid: { display: false }, ticks: { color: '#616161' } }
}
}
});
}

function renderTopProductos(data) {
var ctx = document.getElementById('chartCanvasTopProductos');
if (!ctx) return;
if (window.myCharts.topProductos) { window.myCharts.topProductos.destroy(); }

var labels = [];
var dataset = [];
if (data && data.length) {
for (var vi = 0; vi < data.length; vi++) {
labels.push(data[vi].producto || '');
var val = data[vi].cantidad != null ? data[vi].cantidad : (data[vi].total != null ? data[vi].total : 0);
dataset.push(val);
}
}

if (!data || !data.length) {
background: #0b4270; /* Solid Hover Color */
dataset = [0];
}

var typeSelect = document.getElementById('chartTypeTop');
var chartType = typeSelect ? typeSelect.value : 'bar';
}
var chartColors = ['#073155', '#1a7a2e', '#e65100', '#f9a825', '#c62828', '#00796b', '#1565c0', '#6a1b9a', '#2e7d32', '#e65100'];
.sidebar-link.active {
background: #278e34; /* Solid Success Green */
window.myCharts.topProductos = new Chart(ctx, {
type: 'bar',
data: {
labels: labels,
.sidebar-link.active svg {
label: 'Cantidad vendida',
data: dataset,
backgroundColor: '#e65100',
.sidebar-divider {
font-size: 0.65rem;
text-transform: uppercase;
}]
},
options: {
indexAxis: 'y',
responsive: true,
maintainAspectRatio: false,
plugins: {
legend: { display: false },
tooltip: { backgroundColor: '#e65100', titleColor: '#fff', bodyColor: '#fff', cornerRadius: 8, padding: 10 }
},
.sidebar.hover-open .sidebar-divider,
x: { beginAtZero: true, grid: { color: '#e0e0e0', drawBorder: false }, ticks: { color: '#616161' } },
y: { grid: { display: false }, ticks: { color: '#616161' } }
}
}
});
} else {
window.myCharts.topProductos = new Chart(ctx, {
type: chartType,
data: {
labels: labels,
datasets: [{
data: dataset,
backgroundColor: chartColors,
borderWidth: 3,
borderColor: '#ffffff',
hoverOffset: 8
/* Hide React app's own nav tabs - sidebar is the only navigation */
#root .app > nav,
#react-root .app > nav {
responsive: true,
maintainAspectRatio: false,
cutout: chartType === 'doughnut' ? '45%' : 0,
plugins: {
legend: { position: 'bottom', labels: { boxWidth: 14, padding: 10, font: { size: 11, weight: 'bold' }, color: '#424242' } },
tooltip: { backgroundColor: '#424242', titleColor: '#fff', bodyColor: '#fff', cornerRadius: 8, padding: 10 }
height: 3cm;
}
});
}
}

function renderCategorias(data) {
var ctx = document.getElementById('chartCanvasCategorias');
if (!ctx) return;
if (window.myCharts.categorias) { window.myCharts.categorias.destroy(); }

var labels = [];
var dataset = [];
if (data && data.length) {
for (var vi = 0; vi < data.length; vi++) {
.sidebar.locked-open .sidebar-calendar {
dataset.push(data[vi].total || 0);
pointer-events: auto;
}

if (!data || !data.length) {
.sidebar-calendar .cal-month {
text-align: center;
font-size: 0.6rem;

var typeSelect = document.getElementById('chartTypeCategorias');
var chartType = typeSelect ? typeSelect.value : 'doughnut';

var chartColors = ['#073155', '#1a7a2e', '#e65100', '#f9a825', '#c62828', '#00796b', '#1565c0', '#6a1b9a'];

.sidebar-calendar .cal-weekdays {
window.myCharts.categorias = new Chart(ctx, {
grid-template-columns: repeat(7, 1fr);
data: {
labels: labels,
datasets: [{
label: 'Ventas ($)',
data: dataset,
backgroundColor: '#073155',
.sidebar-calendar .cal-days {
borderRadius: 8,
grid-template-columns: repeat(7, 1fr);
}]
},
.sidebar-calendar .cal-day {
font-size: 0.55rem;
responsive: true,
maintainAspectRatio: false,
plugins: {
legend: { display: false },
tooltip: { backgroundColor: '#073155', titleColor: '#fff', bodyColor: '#fff', cornerRadius: 8, padding: 10 }
background: #278e34; /* Solid green */
border-radius: 50%;
x: { beginAtZero: true, grid: { color: '#e0e0e0', drawBorder: false }, ticks: { color: '#616161' } },
y: { grid: { display: false }, ticks: { color: '#616161' } }
}
.sidebar-calendar .cal-day.other {
color: #0b4270; /* match calendar bg to hide */
visibility: hidden;
window.myCharts.categorias = new Chart(ctx, {
type: chartType,
data: {
labels: labels,
datasets: [{
.sidebar {
position: fixed;
top: 56px;
.sidebar.open {
left: 0;
}
.sidebar-brand,
.sidebar-divider,
.sidebar-calendar {
opacity: 1 !important;
pointer-events: auto !important;
#desktop-sidebar-toggle {
display: none;
}

