// ============================================================
// SUPERMERCADO EL GRANJERO - SISTEMA DE GESTIÓN
// ============================================================

// ==================== DATOS SEMILLA ====================

const PRODUCTOS_SEMILLA = [];

const PROVEEDORES_SEMILLA = [];

const GASTOS_SEMILLA = [];

const AUTOCONSUMOS_SEMILLA = [];

const VENTAS_SEMILLA = [];

const HISTORIAL_ARQUEOS_SEMILLA = [];

const CLIENTES_SEMILLA = [];

// ==================== ICONOS SVG ====================

function Icon({ name, className }) {
  var icons = {
    store: [['path',{d:'M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z'}],['polyline',{points:'9 22 9 12 15 12 15 22'}]],
    'chart-bar': [['line',{x1:'12',y1:'20',x2:'12',y2:'10'}],['line',{x1:'18',y1:'20',x2:'18',y2:'4'}],['line',{x1:'6',y1:'20',x2:'6',y2:'16'}]],
    'dollar-sign': [['line',{x1:'12',y1:'1',x2:'12',y2:'23'}],['path',{d:'M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6'}]],
    'trending-up': [['polyline',{points:'23 6 13.5 15.5 8.5 10.5 1 18'}],['polyline',{points:'17 6 23 6 23 12'}]],
    'trending-down': [['polyline',{points:'23 18 13.5 8.5 8.5 13.5 1 6'}],['polyline',{points:'17 18 23 18 23 12'}]],
    wallet: [['path',{d:'M4 10s-1 3 1 6c2 3 6 5 8 5s6-2 8-5c2-3 1-6 1-6'}],['path',{d:'M12 7V3'}],['path',{d:'M9 5h6'}],['path',{d:'M9 15h6'}]],
    package: [['path',{d:'M16.5 9.4 7.55 4.24'}],['path',{d:'M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z'}],['polyline',{points:'3.29 7 12 12 20.71 7'}],['line',{x1:'12',y1:'22',x2:'12',y2:'12'}]],
    'alert-triangle': [['path',{d:'M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z'}],['line',{x1:'12',y1:'9',x2:'12',y2:'13'}],['line',{x1:'12',y1:'17',x2:'12.01',y2:'17'}]],
    users: [['path',{d:'M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2'}],['circle',{cx:'9',cy:'7',r:'4'}],['path',{d:'M23 21v-2a4 4 0 0 0-3-3.87'}],['path',{d:'M16 3.13a4 4 0 0 1 0 7.75'}]],
    user: [['path',{d:'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2'}],['circle',{cx:'12',cy:'7',r:'4'}]],
    calendar: [['rect',{x:'3',y:'4',width:'18',height:'18',rx:'2',ry:'2'}],['line',{x1:'16',y1:'2',x2:'16',y2:'6'}],['line',{x1:'8',y1:'2',x2:'8',y2:'6'}],['line',{x1:'3',y1:'10',x2:'21',y2:'10'}]],
    thumbtack: [['line',{x1:'3',y1:'21',x2:'21',y2:'3'}],['path',{d:'M9 3l12 12'}],['path',{d:'M14 3l7 7'}]],
    'credit-card': [['rect',{x:'1',y:'4',width:'22',height:'16',rx:'2',ry:'2'}],['line',{x1:'1',y1:'10',x2:'23',y2:'10'}]],
    receipt: [['path',{d:'M4 2h16v20l-4-2-4 2-4-2-4 2V2z'}],['line',{x1:'8',y1:'8',x2:'16',y2:'8'}],['line',{x1:'8',y1:'12',x2:'14',y2:'12'}]],
    truck: [['rect',{x:'1',y:'3',width:'15',height:'13'}],['polygon',{points:'16 8 20 8 23 11 23 16 16 16 16 8'}],['circle',{cx:'5.5',cy:'18.5',r:'2.5'}],['circle',{cx:'18.5',cy:'18.5',r:'2.5'}]],
    factory: [['path',{d:'M2 22V2l8 6V2l8 6V2l4 2v18H2z'}],['line',{x1:'2',y1:'12',x2:'22',y2:'12'}]],
    sparkles: [['path',{d:'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z'}],['path',{d:'M9 12l2 2 4-4'}]],
    'check-circle': [['circle',{cx:'12',cy:'12',r:'10'}],['polyline',{points:'9 12 11 14 15 10'}]],
    'x-circle': [['circle',{cx:'12',cy:'12',r:'10'}],['line',{x1:'15',y1:'9',x2:'9',y2:'15'}],['line',{x1:'9',y1:'9',x2:'15',y2:'15'}]],
    info: [['circle',{cx:'12',cy:'12',r:'10'}],['line',{x1:'12',y1:'16',x2:'12',y2:'12'}],['line',{x1:'12',y1:'8',x2:'12.01',y2:'8'}]],
    x: [['line',{x1:'18',y1:'6',x2:'6',y2:'18'}],['line',{x1:'6',y1:'6',x2:'18',y2:'18'}]],
    plus: [['line',{x1:'12',y1:'5',x2:'12',y2:'19'}],['line',{x1:'5',y1:'12',x2:'19',y2:'12'}]],
    minus: [['line',{x1:'5',y1:'12',x2:'19',y2:'12'}]],
    search: [['circle',{cx:'11',cy:'11',r:'8'}],['line',{x1:'21',y1:'21',x2:'16.65',y2:'16.65'}]],
    'shopping-cart': [['circle',{cx:'9',cy:'21',r:'1'}],['circle',{cx:'20',cy:'21',r:'1'}],['path',{d:'M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6'}]]
  };
  var paths = icons[name] || icons.x;
  var children = paths.map(function(p, i) {
    var props = Object.assign({ key: i }, p[1]);
    return React.createElement(p[0], props);
  });
  return React.createElement('svg', {
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: 'currentColor',
    strokeWidth: '2',
    strokeLinecap: 'round',
    strokeLinejoin: 'round',
    className: className || '',
    style: { width: '1em', height: '1em', verticalAlign: 'middle' }
  }, ...children);
}

// ==================== COMPONENTE PRINCIPAL ====================

function App() {
  // -------------------- ESTADOS PRINCIPALES --------------------
  var safeJSON = function(key, fallback) {
    try {
      var saved = localStorage.getItem(key);
      return saved ? JSON.parse(saved) : fallback;
    } catch (e) {
      console.warn('Error leyendo localStorage[' + key + ']:', e);
      localStorage.removeItem(key);
      return fallback;
    }
  };
  const [tabActiva, setTabActiva] = React.useState('cantina');
  const [productos, setProductos] = React.useState(function() { return safeJSON('app_productos', PRODUCTOS_SEMILLA); });
  const [proveedores, setProveedores] = React.useState(function() { return safeJSON('app_proveedores', PROVEEDORES_SEMILLA); });
  const [gastos, setGastos] = React.useState(function() { return safeJSON('app_gastos', GASTOS_SEMILLA); });
  const [autoconsumos, setAutoconsumos] = React.useState(function() { return safeJSON('app_autoconsumos', AUTOCONSUMOS_SEMILLA); });
  const [ventas, setVentas] = React.useState(function() { return safeJSON('app_ventas', VENTAS_SEMILLA); });
  const [arqueos, setArqueos] = React.useState(function() { return safeJSON('app_arqueos', HISTORIAL_ARQUEOS_SEMILLA); });
  const [clientes, setClientes] = React.useState(function() { return safeJSON('app_clientes', CLIENTES_SEMILLA); });
  const [compras, setCompras] = React.useState(function() { return safeJSON('app_compras', []); });
  const [cargadoDesdeFirestore, setCargadoDesdeFirestore] = React.useState(false);
  const [firestoreDisponible, setFirestoreDisponible] = React.useState(false);

  // -------------------- CARGA INICIAL DESDE FIRESTORE --------------------
  React.useEffect(() => {
    if (window.db) {
      const db = window.db;
      const colecciones = ['productos', 'proveedores', 'gastos', 'autoconsumos', 'ventas', 'arqueos', 'clientes', 'compras'];
      var promesas = colecciones.map(function(col) {
        return db.collection('datos').doc(col).get().then(function(doc) {
          return { col: col, exist: doc.exists, data: doc.exists ? doc.data().lista : null };
        });
      });

      Promise.all(promesas).then(function(resultados) {
        var tieneDatos = resultados.some(function(r) { return r.exist && Array.isArray(r.data); });

        if (!tieneDatos) {
          // Si Firestore está vacío, subimos los datos semilla iniciales
          var batch = db.batch();
          batch.set(db.collection('datos').doc('productos'), { lista: productos });
          batch.set(db.collection('datos').doc('proveedores'), { lista: proveedores });
          batch.set(db.collection('datos').doc('gastos'), { lista: gastos });
          batch.set(db.collection('datos').doc('autoconsumos'), { lista: autoconsumos });
          batch.set(db.collection('datos').doc('ventas'), { lista: ventas });
          batch.set(db.collection('datos').doc('arqueos'), { lista: arqueos });
          batch.set(db.collection('datos').doc('clientes'), { lista: clientes });
          batch.set(db.collection('datos').doc('compras'), { lista: compras });
          
          return batch.commit().then(function() {
            console.log('Firestore inicializado con datos semilla.');
            setCargadoDesdeFirestore(true);
            setFirestoreDisponible(true);
          });
        } else {
          // Si ya hay datos en Firestore, actualizamos el estado de React
          resultados.forEach(function(r) {
            if (r.exist && Array.isArray(r.data)) {
              if (r.col === 'productos') setProductos(r.data);
              else if (r.col === 'proveedores') setProveedores(r.data);
              else if (r.col === 'gastos') setGastos(r.data);
              else if (r.col === 'autoconsumos') setAutoconsumos(r.data);
              else if (r.col === 'ventas') setVentas(r.data);
              else if (r.col === 'arqueos') setArqueos(r.data);
              else if (r.col === 'clientes') setClientes(r.data);
              else if (r.col === 'compras') setCompras(r.data);
            }
          });
          console.log('Datos cargados correctamente desde Firestore.');
          setCargadoDesdeFirestore(true);
          setFirestoreDisponible(true);
        }
      }).catch(function(err) {
        console.warn('Firestore no disponible, usando datos locales.');
        setCargadoDesdeFirestore(true);
      });
    } else {
      setCargadoDesdeFirestore(true);
    }
  }, []);

  // -------------------- PERSISTENCIA LOCALSTORAGE Y FIRESTORE --------------------
  var guardarLocal = function(key, data) {
    try { localStorage.setItem(key, JSON.stringify(data)); }
    catch (e) { console.warn('Error guardando ' + key + ' en localStorage:', e); }
  };
  var guardarFirestore = function(col, data) {
    if (firestoreDisponible && window.db) {
      try {
        window.db.collection('datos').doc(col).set({ lista: data }).catch(function(e) { console.warn('Error guardando ' + col + ' en Firestore:', e); });
      } catch (e) { console.warn('Error guardando ' + col + ' en Firestore:', e); }
    }
  };
  React.useEffect(function() { guardarLocal('app_productos', productos); guardarFirestore('productos', productos); }, [productos, cargadoDesdeFirestore]);
  React.useEffect(function() { guardarLocal('app_proveedores', proveedores); guardarFirestore('proveedores', proveedores); }, [proveedores, cargadoDesdeFirestore]);
  React.useEffect(function() { guardarLocal('app_gastos', gastos); guardarFirestore('gastos', gastos); }, [gastos, cargadoDesdeFirestore]);
  React.useEffect(function() { guardarLocal('app_autoconsumos', autoconsumos); guardarFirestore('autoconsumos', autoconsumos); }, [autoconsumos, cargadoDesdeFirestore]);
  React.useEffect(function() { guardarLocal('app_ventas', ventas); guardarFirestore('ventas', ventas); }, [ventas, cargadoDesdeFirestore]);
  React.useEffect(function() { guardarLocal('app_arqueos', arqueos); guardarFirestore('arqueos', arqueos); }, [arqueos, cargadoDesdeFirestore]);
  React.useEffect(function() { guardarLocal('app_clientes', clientes); guardarFirestore('clientes', clientes); }, [clientes, cargadoDesdeFirestore]);
  React.useEffect(function() { guardarLocal('app_compras', compras); guardarFirestore('compras', compras); }, [compras, cargadoDesdeFirestore]);

  // -------------------- ESTADOS DE MODALES --------------------
  const [modalPago, setModalPago] = React.useState({ abierto: false, venta: null });
  const [modalArqueo, setModalArqueo] = React.useState({ abierto: false });
  const [modalRecibo, setModalRecibo] = React.useState({ abierto: false, datos: null });
  const [modalNotificacion, setModalNotificacion] = React.useState({ abierto: false, mensaje: '', tipo: 'info' });
  const [modalDialogo, setModalDialogo] = React.useState({ abierto: false, titulo: '', mensaje: '', onConfirm: null });

  // -------------------- ESTADOS DE FORMULARIOS --------------------
  const [formProducto, setFormProducto] = React.useState({ id: null, codigo: '', nombre: '', categoria: '', precioCompra: '', precioVenta: '', stock: '', stockMinimo: '', unidad: 'und' });
  const [formProveedor, setFormProveedor] = React.useState({ id: null, nombre: '', contacto: '', telefono: '', email: '', direccion: '', tipo: '' });
  const [formGasto, setFormGasto] = React.useState({ id: null, descripcion: '', categoria: '', monto: '', fecha: new Date().toISOString().split('T')[0], tipo: 'Variable' });
  const [formAutoconsumo, setFormAutoconsumo] = React.useState({ id: null, productoId: '', cantidad: '', fecha: new Date().toISOString().split('T')[0], motivo: '' });
  const [formCliente, setFormCliente] = React.useState({ id: null, nombre: '', telefono: '', direccion: '', tipo: 'Ocasional', creditoMaximo: '', saldoPendiente: 0 });
  const [formCompra, setFormCompra] = React.useState({ id: null, proveedorId: '', fecha: new Date().toISOString().split('T')[0], items: [], total: 0, estado: 'Pendiente' });

  // -------------------- ESTADOS DE POS --------------------
  const [carrito, setCarrito] = React.useState([]);
  const [busquedaProducto, setBusquedaProducto] = React.useState('');
  const [clienteFiado, setClienteFiado] = React.useState(null);
  const [montoPago, setMontoPago] = React.useState('');
  const [diasCredito, setDiasCredito] = React.useState(30);
  const [descuentoMonto, setDescuentoMonto] = React.useState('');
  const [descuentoPorcentaje, setDescuentoPorcentaje] = React.useState('');
  const [montoRecibido, setMontoRecibido] = React.useState('');

  // -------------------- ESTADOS DE FILTROS --------------------
  const [filtroProducto, setFiltroProducto] = React.useState('');
  const [filtroCategoria, setFiltroCategoria] = React.useState('');
  const [filtroProveedor, setFiltroProveedor] = React.useState('');
  const [filtroGasto, setFiltroGasto] = React.useState('');
  const [filtroVenta, setFiltroVenta] = React.useState('');

  // -------------------- ESTADOS DE CAJA --------------------
  const [montoInicialArqueo, setMontoInicialArqueo] = React.useState('');
  const [arqueoObservaciones, setArqueoObservaciones] = React.useState('');

  // -------------------- HELPERS: IDs --------------------
  const nextId = (arr) => arr.length > 0 ? Math.max(...arr.map(i => i.id)) + 1 : 1;
  const nextVentaId = () => ventas.length > 0 ? Math.max(...ventas.map(v => v.id)) + 1 : 1;
  const hoy = () => new Date().toISOString().split('T')[0];

  // -------------------- FORMATO MONEDA --------------------
  const fMoneda = (n) => '$' + Number(n).toLocaleString('es-CO', { minimumFractionDigits: 0, maximumFractionDigits: 0 });

  // -------------------- PRODUCTOS: CRUD --------------------
  const guardarProducto = () => {
    const { id, codigo, nombre, categoria, precioCompra, precioVenta, stock, stockMinimo, unidad } = formProducto;
    if (!codigo || !nombre || !precioVenta) { notificar('Complete los campos obligatorios (código, nombre, precio venta)', 'error'); return; }
    const p = { id: id || nextId(productos), codigo, nombre, categoria, precioCompra: Number(precioCompra) || 0, precioVenta: Number(precioVenta) || 0, stock: Number(stock) || 0, stockMinimo: Number(stockMinimo) || 0, unidad: unidad || 'und' };
    if (id) {
      setProductos(productos.map(prod => prod.id === id ? p : prod));
      notificar('Producto actualizado correctamente', 'exito');
    } else {
      setProductos([...productos, p]);
      notificar('Producto creado correctamente', 'exito');
    }
    setFormProducto({ id: null, codigo: '', nombre: '', categoria: '', precioCompra: '', precioVenta: '', stock: '', stockMinimo: '', unidad: 'und' });
  };

  const editarProducto = (prod) => {
    setFormProducto({ ...prod, precioCompra: String(prod.precioCompra), precioVenta: String(prod.precioVenta), stock: String(prod.stock), stockMinimo: String(prod.stockMinimo) });
  };

  const eliminarProducto = (id) => {
    abrirDialogo('Eliminar producto', '¿Está seguro de eliminar este producto?', () => {
      setProductos(productos.filter(p => p.id !== id));
      notificar('Producto eliminado', 'info');
    });
  };

  const ajustarStock = (productoId, cantidad) => {
    setProductos(productos.map(p => p.id === productoId ? { ...p, stock: Math.max(0, p.stock + cantidad) } : p));
  };

  // -------------------- PROVEEDORES: CRUD --------------------
  const guardarProveedor = () => {
    const { id, nombre, contacto, telefono, email, direccion, tipo } = formProveedor;
    if (!nombre) { notificar('El nombre del proveedor es obligatorio', 'error'); return; }
    const p = { id: id || nextId(proveedores), nombre, contacto: contacto || '', telefono: telefono || '', email: email || '', direccion: direccion || '', tipo: tipo || '' };
    if (id) {
      setProveedores(proveedores.map(prov => prov.id === id ? p : prov));
      notificar('Proveedor actualizado', 'exito');
    } else {
      setProveedores([...proveedores, p]);
      notificar('Proveedor creado', 'exito');
    }
    setFormProveedor({ id: null, nombre: '', contacto: '', telefono: '', email: '', direccion: '', tipo: '' });
  };

  const editarProveedor = (prov) => setFormProveedor({ ...prov });
  const eliminarProveedor = (id) => {
    abrirDialogo('Eliminar proveedor', '¿Está seguro?', () => {
      setProveedores(proveedores.filter(p => p.id !== id));
      notificar('Proveedor eliminado', 'info');
    });
  };

  // -------------------- GASTOS: CRUD --------------------
  const guardarGasto = () => {
    const { id, descripcion, categoria, monto, fecha, tipo } = formGasto;
    if (!descripcion || !monto) { notificar('Descripción y monto son obligatorios', 'error'); return; }
    const g = { id: id || nextId(gastos), descripcion, categoria: categoria || 'General', monto: Number(monto), fecha: fecha || hoy(), tipo: tipo || 'Variable' };
    if (id) {
      setGastos(gastos.map(gto => gto.id === id ? g : gto));
      notificar('Gasto actualizado', 'exito');
    } else {
      setGastos([...gastos, g]);
      notificar('Gasto registrado', 'exito');
    }
    setFormGasto({ id: null, descripcion: '', categoria: '', monto: '', fecha: hoy(), tipo: 'Variable' });
  };

  const editarGasto = (g) => setFormGasto({ ...g, monto: String(g.monto) });
  const eliminarGasto = (id) => {
    abrirDialogo('Eliminar gasto', '¿Está seguro?', () => {
      setGastos(gastos.filter(g => g.id !== id));
      notificar('Gasto eliminado', 'info');
    });
  };

  // -------------------- AUTOCONSUMOS: CRUD --------------------
  const guardarAutoconsumo = () => {
    const { id, productoId, cantidad, fecha, motivo } = formAutoconsumo;
    if (!productoId || !cantidad) { notificar('Seleccione producto e indique cantidad', 'error'); return; }
    const prod = productos.find(p => p.id === Number(productoId));
    if (!prod) { notificar('Producto no encontrado', 'error'); return; }
    if (Number(cantidad) > prod.stock) { notificar('Stock insuficiente', 'error'); return; }
    const a = { id: id || nextId(autoconsumos), productoId: Number(productoId), cantidad: Number(cantidad), fecha: fecha || hoy(), motivo: motivo || '' };
    if (id) {
      setAutoconsumos(autoconsumos.map(ac => ac.id === id ? a : ac));
    } else {
      setAutoconsumos([...autoconsumos, a]);
    }
    ajustarStock(Number(productoId), -Number(cantidad));
    notificar('Autoconsumo registrado', 'exito');
    setFormAutoconsumo({ id: null, productoId: '', cantidad: '', fecha: hoy(), motivo: '' });
  };

  const editarAutoconsumo = (a) => setFormAutoconsumo({ ...a, productoId: String(a.productoId), cantidad: String(a.cantidad) });
  const eliminarAutoconsumo = (id) => {
    abrirDialogo('Eliminar autoconsumo', '¿Está seguro?', () => {
      const ac = autoconsumos.find(a => a.id === id);
      if (ac) ajustarStock(ac.productoId, ac.cantidad);
      setAutoconsumos(autoconsumos.filter(a => a.id !== id));
      notificar('Autoconsumo eliminado', 'info');
    });
  };

  // -------------------- CLIENTES: CRUD --------------------
  const guardarCliente = () => {
    const { id, nombre, telefono, direccion, tipo, creditoMaximo, saldoPendiente } = formCliente;
    if (!nombre) { notificar('El nombre del cliente es obligatorio', 'error'); return; }
    const c = { id: id || nextId(clientes), nombre, telefono: telefono || '', direccion: direccion || '', tipo: tipo || 'Ocasional', creditoMaximo: Number(creditoMaximo) || 0, saldoPendiente: Number(saldoPendiente) || 0 };
    if (id) {
      setClientes(clientes.map(cl => cl.id === id ? c : cl));
      notificar('Cliente actualizado', 'exito');
    } else {
      setClientes([...clientes, c]);
      notificar('Cliente creado', 'exito');
    }
    setFormCliente({ id: null, nombre: '', telefono: '', direccion: '', tipo: 'Ocasional', creditoMaximo: '', saldoPendiente: 0 });
  };

  const editarCliente = (c) => setFormCliente({ ...c, creditoMaximo: String(c.creditoMaximo), saldoPendiente: String(c.saldoPendiente) });
  const eliminarCliente = (id) => {
    abrirDialogo('Eliminar cliente', '¿Está seguro?', () => {
      setClientes(clientes.filter(c => c.id !== id));
      notificar('Cliente eliminado', 'info');
    });
  };

  // -------------------- COMPRAS: CRUD --------------------
  const agregarItemCompra = (productoId, cantidad, precioCompra) => {
    const prod = productos.find(p => p.id === Number(productoId));
    if (!prod) { notificar('Producto no encontrado', 'error'); return; }
    const existente = formCompra.items.find(i => i.productoId === Number(productoId));
    let nuevosItems;
    if (existente) {
      nuevosItems = formCompra.items.map(i => i.productoId === Number(productoId) ? { ...i, cantidad: i.cantidad + Number(cantidad), subtotal: (i.cantidad + Number(cantidad)) * (Number(precioCompra) || prod.precioCompra) } : i);
    } else {
      nuevosItems = [...formCompra.items, { productoId: Number(productoId), nombre: prod.nombre, cantidad: Number(cantidad), precioCompra: Number(precioCompra) || prod.precioCompra, subtotal: Number(cantidad) * (Number(precioCompra) || prod.precioCompra) }];
    }
    const total = nuevosItems.reduce((s, i) => s + i.subtotal, 0);
    setFormCompra({ ...formCompra, items: nuevosItems, total });
  };

  const quitarItemCompra = (productoId) => {
    const nuevosItems = formCompra.items.filter(i => i.productoId !== productoId);
    const total = nuevosItems.reduce((s, i) => s + i.subtotal, 0);
    setFormCompra({ ...formCompra, items: nuevosItems, total });
  };

  const guardarCompra = () => {
    if (!formCompra.proveedorId || formCompra.items.length === 0) { notificar('Seleccione proveedor y agregue items', 'error'); return; }
    const compra = { ...formCompra, id: formCompra.id || nextId(compras), proveedorId: Number(formCompra.proveedorId), fecha: formCompra.fecha || hoy(), estado: formCompra.estado || 'Completada' };
    compra.items.forEach(item => {
      ajustarStock(item.productoId, item.cantidad);
      const prod = productos.find(p => p.id === item.productoId);
      if (prod && item.precioCompra !== prod.precioCompra) {
        setProductos(prev => prev.map(p => p.id === item.productoId ? { ...p, precioCompra: item.precioCompra } : p));
      }
    });
    if (formCompra.id) {
      setCompras(compras.map(c => c.id === compra.id ? compra : c));
    } else {
      setCompras([...compras, compra]);
    }
    notificar('Compra registrada correctamente', 'exito');
    setFormCompra({ id: null, proveedorId: '', fecha: hoy(), items: [], total: 0, estado: 'Pendiente' });
  };

  const eliminarCompra = (id) => {
    abrirDialogo('Eliminar compra', '¿Está seguro? Esto no revertirá el stock.', () => {
      setCompras(compras.filter(c => c.id !== id));
      notificar('Compra eliminida', 'info');
    });
  };

  // -------------------- POS: CARRITO Y VENTAS --------------------
  const agregarAlCarrito = (producto) => {
    const existente = carrito.find(i => i.productoId === producto.id);
    if (existente) {
      if (existente.cantidad >= producto.stock) { notificar('Stock insuficiente', 'error'); return; }
      const esPesable = existente.unidad !== 'und';
      const nuevaCantidad = esPesable ? existente.cantidad + 0.5 : existente.cantidad + 1;
      setCarrito(carrito.map(i => i.productoId === producto.id ? { ...i, cantidad: nuevaCantidad, subtotal: nuevaCantidad * i.precioVenta } : i));
    } else {
      if (producto.stock < 1) { notificar('Stock insuficiente', 'error'); return; }
      setCarrito([...carrito, { productoId: producto.id, nombre: producto.nombre, codigo: producto.codigo, precioVenta: producto.precioVenta, unidad: producto.unidad, cantidad: 1, subtotal: producto.precioVenta }]);
    }
  };

  const cambiarCantidadCarrito = (productoId, nuevaCantidad) => {
    const prod = productos.find(p => p.id === productoId);
    const item = carrito.find(i => i.productoId === productoId);
    const unidad = item ? item.unidad : (prod ? prod.unidad : 'und');
    const esPesable = unidad !== 'und';
    // Enforce integer for non-pesable units
    const cantidadFinal = esPesable ? nuevaCantidad : Math.floor(nuevaCantidad);
    if (cantidadFinal < 0.1) { setCarrito(carrito.filter(i => i.productoId !== productoId)); return; }
    if (prod && cantidadFinal > prod.stock) { notificar('Stock insuficiente', 'error'); return; }
    setCarrito(carrito.map(i => i.productoId === productoId ? { ...i, cantidad: cantidadFinal, subtotal: cantidadFinal * i.precioVenta } : i));
  };

  const quitarDelCarrito = (productoId) => setCarrito(carrito.filter(i => i.productoId !== productoId));

  const totalCarrito = () => carrito.reduce((s, i) => s + i.subtotal, 0);
  const calcularDescuento = () => {
    const total = totalCarrito();
    if (descuentoPorcentaje && Number(descuentoPorcentaje) > 0) {
      return total * (Number(descuentoPorcentaje) / 100);
    }
    if (descuentoMonto && Number(descuentoMonto) > 0) {
      return Number(descuentoMonto);
    }
    return 0;
  };
  const totalConDescuento = () => Math.max(0, totalCarrito() - calcularDescuento());

  const finalizarVenta = (metodoPago, esFiado = false) => {
    if (carrito.length === 0) { notificar('El carrito está vacío', 'error'); return; }
    if (esFiado && !clienteFiado) { notificar('Seleccione un cliente para venta a crédito', 'error'); return; }
    const descuento = calcularDescuento();
    const total = totalConDescuento();
    if (esFiado && clienteFiado) {
      if (clienteFiado.saldoPendiente + total > clienteFiado.creditoMaximo) { notificar('El cliente excede su límite de crédito', 'error'); return; }
    }
    const venta = {
      id: nextVentaId(),
      fecha: hoy(),
      items: carrito.map(i => ({ productoId: i.productoId, cantidad: i.cantidad, precioVenta: i.precioVenta })),
      total: total,
      descuento: descuento,
      metodoPago,
      cliente: esFiado ? clienteFiado.nombre : 'Cliente ocasional',
      clienteId: esFiado ? clienteFiado.id : null,
      montoRecibido: metodoPago === 'Efectivo' ? Number(montoRecibido) : null,
      cambio: metodoPago === 'Efectivo' ? Math.max(0, Number(montoRecibido) - total) : null
    };
    setVentas([...ventas, venta]);
    carrito.forEach(i => ajustarStock(i.productoId, -i.cantidad));
    if (esFiado && clienteFiado) {
      setClientes(clientes.map(c => c.id === clienteFiado.id ? { ...c, saldoPendiente: c.saldoPendiente + total } : c));
    }
    setCarrito([]);
    setClienteFiado(null);
    setDescuentoMonto('');
    setDescuentoPorcentaje('');
    setMontoRecibido('');
    abrirRecibo(venta);
    notificar(`Venta finalizada - ${fMoneda(venta.total)}`, 'exito');
  };

  // -------------------- MODAL: PAGOS --------------------
  const abrirModalPago = () => setModalPago({ abierto: true, venta: { total: totalCarrito() } });
  const cerrarModalPago = () => setModalPago({ abierto: false, venta: null });

  const procesarPagoEfectivo = () => {
    cerrarModalPago();
    finalizarVenta('Efectivo', false);
  };

  const procesarPagoTarjeta = () => {
    cerrarModalPago();
    finalizarVenta('Tarjeta', false);
  };

  const procesarPagoFiado = () => {
    if (!clienteFiado) { notificar('Seleccione un cliente para fiado', 'error'); return; }
    cerrarModalPago();
    finalizarVenta('Fiado', true);
  };

  // -------------------- MODAL: ARQUEO DE CAJA --------------------
  const abrirModalArqueo = () => setModalArqueo({ abierto: true });
  const cerrarModalArqueo = () => {
    setModalArqueo({ abierto: false });
    setMontoInicialArqueo('');
    setArqueoObservaciones('');
  };

  const realizarArqueo = () => {
    const montoInicial = Number(montoInicialArqueo) || 0;
    const ventasHoy = ventas.filter(v => v.fecha === hoy() && v.metodoPago !== 'Fiado');
    const ingresosEsperados = ventasHoy.reduce((s, v) => s + v.total, 0);
    const egresosHoy = gastos.filter(g => g.fecha === hoy()).reduce((s, g) => s + g.monto, 0);
    const gastosHoy = gastos.filter(g => g.fecha === hoy()).reduce((s, g) => s + g.monto, 0);
    const montoFinalEsperado = montoInicial + ingresosEsperados - gastosHoy;
    const arqueo = {
      id: nextId(arqueos),
      fecha: hoy(),
      hora: new Date().toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' }),
      montoInicial,
      ingresosEsperados,
      ingresosReales: ingresosEsperados,
      egresos: gastosHoy,
      montoFinalEsperado,
      montoFinalReal: montoFinalEsperado,
      diferencia: 0,
      observaciones: arqueoObservaciones || 'Arqueo de caja',
      estado: 'OK'
    };
    setArqueos([...arqueos, arqueo]);
    notificar('Arqueo realizado correctamente', 'exito');
    cerrarModalArqueo();
  };

  // -------------------- MODAL: RECIBO --------------------
  const abrirRecibo = (venta) => setModalRecibo({ abierto: true, datos: venta });
  const cerrarRecibo = () => setModalRecibo({ abierto: false, datos: null });

  // -------------------- MODAL: NOTIFICACION --------------------
  const notificar = (mensaje, tipo = 'info') => {
    setModalNotificacion({ abierto: true, mensaje, tipo });
    setTimeout(() => setModalNotificacion({ abierto: false, mensaje: '', tipo: 'info' }), 3000);
  };

  // -------------------- MODAL: DIALOGO CONFIRMACION --------------------
  const abrirDialogo = (titulo, mensaje, onConfirm) => setModalDialogo({ abierto: true, titulo, mensaje, onConfirm });
  const cerrarDialogo = () => setModalDialogo({ abierto: false, titulo: '', mensaje: '', onConfirm: null });
  const confirmarDialogo = () => { if (modalDialogo.onConfirm) modalDialogo.onConfirm(); cerrarDialogo(); };

  // -------------------- RESEED --------------------
  const reseed = () => {
    abrirDialogo('Reiniciar datos', '¿Está seguro? Se perderán todos los datos actuales.', () => {
      setProductos(PRODUCTOS_SEMILLA);
      setProveedores(PROVEEDORES_SEMILLA);
      setGastos(GASTOS_SEMILLA);
      setAutoconsumos(AUTOCONSUMOS_SEMILLA);
      setVentas(VENTAS_SEMILLA);
      setArqueos(HISTORIAL_ARQUEOS_SEMILLA);
      setClientes(CLIENTES_SEMILLA);
      setCompras([]);
      notificar('Datos reiniciados a valores semilla', 'info');
    });
  };

  // -------------------- EXPORTAR DATOS --------------------
  const exportarDatos = () => {
    const datos = { productos, proveedores, gastos, autoconsumos, ventas, arqueos, clientes, compras, fechaExportacion: new Date().toISOString() };
    const blob = new Blob([JSON.stringify(datos, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `exportacion_granjero_${hoy()}.json`;
    a.click();
    URL.revokeObjectURL(url);
    notificar('Datos exportados correctamente', 'exito');
  };

  // -------------------- IMPORTAR DATOS --------------------
  const importarDatos = (archivo) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const datos = JSON.parse(e.target.result);
        if (datos.productos) setProductos(datos.productos);
        if (datos.proveedores) setProveedores(datos.proveedores);
        if (datos.gastos) setGastos(datos.gastos);
        if (datos.autoconsumos) setAutoconsumos(datos.autoconsumos);
        if (datos.ventas) setVentas(datos.ventas);
        if (datos.arqueos) setArqueos(datos.arqueos);
        if (datos.clientes) setClientes(datos.clientes);
        if (datos.compras) setCompras(datos.compras);
        notificar('Datos importados correctamente', 'exito');
      } catch (err) {
        notificar('Error al importar: archivo inválido', 'error');
      }
    };
    reader.readAsText(archivo);
  };

  // ==================== RENDER PRINCIPAL ====================

  const categorias = [...new Set(productos.map(p => p.categoria))].sort();

  const productosFiltrados = productos.filter(p => {
    const nombreMatch = p.nombre.toLowerCase().includes(filtroProducto.toLowerCase());
    const codigoMatch = p.codigo.toLowerCase().includes(filtroProducto.toLowerCase());
    const catMatch = !filtroCategoria || p.categoria === filtroCategoria;
    return (nombreMatch || codigoMatch) && catMatch;
  });

  const productosSinStock = productos.filter(p => p.stock <= p.stockMinimo);

  const gastosFiltrados = gastos.filter(g => {
    return !filtroGasto || g.categoria === filtroGasto || g.descripcion.toLowerCase().includes(filtroGasto.toLowerCase());
  });

  const gastosPorCategoria = {};
  gastos.forEach(g => { gastosPorCategoria[g.categoria] = (gastosPorCategoria[g.categoria] || 0) + g.monto; });

  const ventasHoy = ventas.filter(v => v.fecha === hoy());
  const totalVentasHoy = ventasHoy.reduce((s, v) => s + v.total, 0);
  const ventasMes = ventas.filter(v => v.fecha.startsWith(hoy().substring(0, 7)));
  const totalVentasMes = ventasMes.reduce((s, v) => s + v.total, 0);
  const totalGastosMes = gastos.filter(g => g.fecha.startsWith(hoy().substring(0, 7))).reduce((s, g) => s + g.monto, 0);

  const proveedoresFiltrados = proveedores.filter(p => {
    return !filtroProveedor || p.nombre.toLowerCase().includes(filtroProveedor.toLowerCase()) || p.tipo.toLowerCase().includes(filtroProveedor.toLowerCase());
  });

  return React.createElement('div', { className: 'app min-h-screen bg-gradient-to-br from-green-50 to-emerald-100' },
    // ==================== HEADER ====================
    React.createElement('header', { className: 'bg-gradient-to-r from-green-700 via-emerald-600 to-green-500 text-white shadow-lg' },
      React.createElement('div', { className: 'container mx-auto px-4 py-2 flex items-center justify-between' },
        React.createElement('div', { className: 'flex items-center gap-2' },
      React.createElement('img', { src: 'logo.png', style: { width: '2rem', height: '2rem', borderRadius: '0.375rem', objectFit: 'cover' } }),
      React.createElement('h1', { className: 'text-lg font-bold' }, 'El Granjero')
        ),
        React.createElement('div', { className: 'flex items-center gap-2 text-xs' },
          React.createElement('span', null, hoy()),
          React.createElement('button', { onClick: reseed, className: 'bg-red-500 hover:bg-red-600 px-2 py-1 rounded text-xs' }, 'Reiniciar'),
          React.createElement('button', { onClick: exportarDatos, className: 'bg-blue-500 hover:bg-blue-600 px-2 py-1 rounded text-xs' }, 'Exportar'),
          React.createElement('label', { className: 'bg-purple-500 hover:bg-purple-600 px-2 py-1 rounded text-xs cursor-pointer' },
            'Importar',
            React.createElement('input', { type: 'file', accept: '.json', style: { display: 'none' }, onChange: (e) => { if (e.target.files[0]) importarDatos(e.target.files[0]); } })
          )
        )
      )
    ),

    // ==================== NAV ====================
    React.createElement('nav', { className: 'bg-white shadow-md border-b border-emerald-200 overflow-x-auto' },
      React.createElement('div', { className: 'container mx-auto flex gap-1 p-1' },
        React.createElement(NavBtn, { tab: 'cantina', icon: 'store', label: 'Cantina', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'dashboard', icon: 'chart-bar', label: 'Dashboard', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'pos', icon: 'credit-card', label: 'POS', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'fiados', icon: 'wallet', label: 'Fiados', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'caja', icon: 'receipt', label: 'Caja', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'inventario', icon: 'package', label: 'Inventario', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'compras', icon: 'truck', label: 'Compras', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'proveedores', icon: 'users', label: 'Proveedores', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'autoconsumo', icon: 'factory', label: 'Autoconsumo', activa: tabActiva, onClick: setTabActiva }),
        React.createElement(NavBtn, { tab: 'clientes', icon: 'user', label: 'Clientes', activa: tabActiva, onClick: setTabActiva })
      )
    ),

    // ==================== CONTENIDO PRINCIPAL ====================
    React.createElement('main', { className: 'container mx-auto p-4' },

      // ===================== TAB: CANTINA =====================
      tabActiva === 'cantina' && React.createElement('div', { className: 'grid grid-cols-1 lg:grid-cols-2 gap-6' },
        React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
          React.createElement('h2', { className: 'text-xl font-bold text-emerald-800 mb-4 flex items-center gap-2' },
            React.createElement(Icon, { name: 'store' }),
            'Cantina / Punto de Venta'
          ),
          React.createElement('div', { className: 'space-y-4' },
            React.createElement('div', null,
              React.createElement('input', {
                type: 'text',
                placeholder: 'Buscar producto por nombre o c\u00f3digo...',
                className: 'w-full p-3 border border-emerald-200 rounded-lg focus:ring-2 focus:ring-emerald-400 focus:border-emerald-400',
                value: busquedaProducto,
                onChange: (e) => setBusquedaProducto(e.target.value)
              })
            ),
            React.createElement('div', { className: 'grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 max-h-96 overflow-y-auto' },
              productos.filter(p => {
                const q = busquedaProducto.toLowerCase();
                return p.stock > 0 && (p.nombre.toLowerCase().includes(q) || p.codigo.toLowerCase().includes(q));
              }).slice(0, 50).map(prod =>
                React.createElement('button', {
                  key: prod.id,
                  onClick: () => agregarAlCarrito(prod),
                  className: 'bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 rounded-lg p-3 text-left transition-all hover:shadow-md'
                },
                  React.createElement('div', { className: 'text-xs text-gray-500' }, prod.codigo),
                  React.createElement('div', { className: 'font-medium text-sm text-gray-800 truncate' }, prod.nombre),
                  React.createElement('div', { className: 'text-sm font-bold text-emerald-600' }, fMoneda(prod.precioVenta)),
                  React.createElement('div', { className: 'text-xs ' + (prod.stock <= prod.stockMinimo ? 'text-red-500' : 'text-gray-400') }, 'Stock: ' + prod.stock)
                )
              ),
              productos.filter(p => p.stock > 0 && busquedaProducto && !p.nombre.toLowerCase().includes(busquedaProducto.toLowerCase()) && !p.codigo.toLowerCase().includes(busquedaProducto.toLowerCase())).length === 0 && productos.filter(p => p.stock > 0 && busquedaProducto && (p.nombre.toLowerCase().includes(busquedaProducto.toLowerCase()) || p.codigo.toLowerCase().includes(busquedaProducto.toLowerCase()))).length === 0 && busquedaProducto && React.createElement('div', { className: 'col-span-full text-center text-gray-400 py-8' }, 'No se encontraron productos')
            )
          )
        ),

        React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
          React.createElement('h2', { className: 'text-xl font-bold text-emerald-800 mb-4 flex items-center gap-2' },
            React.createElement(Icon, { name: 'shopping-cart' }),
            'Carrito de Compras'
          ),
          carrito.length === 0
              ? React.createElement('div', { className: 'text-center text-gray-400 py-12' }, 'El carrito est\u00e1 vac\u00edo')
              : React.createElement('div', { className: 'space-y-2' },
                  carrito.map(item => {
                    const prod = productos.find(p => p.id === item.productoId);
                    const unidad = item.unidad || (prod ? prod.unidad : 'und');
                    const esPesable = unidad !== 'und';
                    const paso = esPesable ? 0.5 : 1;
                    return React.createElement('div', { key: item.productoId, className: 'bg-white border border-emerald-100 rounded-xl p-3 shadow-sm hover:shadow-md transition-shadow' },
                      React.createElement('div', { className: 'flex justify-between items-start mb-2' },
                        React.createElement('div', { className: 'flex-1' },
                          React.createElement('div', { className: 'font-bold text-sm text-gray-800' }, item.nombre),
                          React.createElement('div', { className: 'text-xs text-gray-500' }, fMoneda(item.precioVenta) + ' c/u' + (unidad ? ' (' + unidad + ')' : ''))
                        ),
                        React.createElement('button', { onClick: () => quitarDelCarrito(item.productoId), className: 'text-red-400 hover:text-red-600 transition-colors' },
                          React.createElement(Icon, { name: 'x' })
                        )
                      ),
                      React.createElement('div', { className: 'flex items-center justify-between' },
                        React.createElement('div', { className: 'flex items-center gap-2 bg-gray-50 rounded-lg p-1' },
                          React.createElement('button', { onClick: () => cambiarCantidadCarrito(item.productoId, item.cantidad - paso), className: 'w-8 h-8 bg-white border border-gray-200 rounded-full text-sm font-bold text-red-600 hover:bg-red-50 hover:border-red-300 transition-all' }, '-'),
                          React.createElement('input', {
                            type: 'number',
                            value: item.cantidad,
                            onChange: (e) => cambiarCantidadCarrito(item.productoId, Number(e.target.value)),
                            step: paso,
                            min: esPesable ? 0.1 : 1,
                            className: 'font-bold w-16 text-center border-0 bg-transparent text-sm focus:ring-0'
                          }),
                          React.createElement('button', { onClick: () => cambiarCantidadCarrito(item.productoId, item.cantidad + paso), className: 'w-8 h-8 bg-white border border-gray-200 rounded-full text-sm font-bold text-emerald-600 hover:bg-emerald-50 hover:border-emerald-300 transition-all' }, '+')
                        ),
                        React.createElement('span', { className: 'font-bold text-lg text-emerald-700' }, fMoneda(item.subtotal))
                      )
                    );
                  }),
                  React.createElement('div', { className: 'bg-emerald-50 rounded-xl p-3 space-y-2' },
                    React.createElement('div', { className: 'flex justify-between' },
                      React.createElement('span', { className: 'text-gray-600' }, 'Subtotal:'),
                      React.createElement('span', { className: 'font-medium' }, fMoneda(totalCarrito()))
                    ),
                    (descuentoPorcentaje || descuentoMonto) && React.createElement('div', { className: 'flex justify-between text-red-600' },
                      React.createElement('span', null, 'Descuento:'),
                      React.createElement('span', { className: 'font-medium' }, '-' + fMoneda(calcularDescuento()))
                    ),
                    React.createElement('div', { className: 'flex justify-between items-center text-lg font-bold text-emerald-800 border-t border-emerald-200 pt-2' },
                      React.createElement('span', null, 'Total:'),
                      React.createElement('span', null, fMoneda(totalConDescuento()))
                    )
                  ),
                  React.createElement('div', { className: 'flex gap-2 pt-2' },
                    React.createElement('button', { onClick: () => abrirModalPago(), className: 'flex-1 bg-gradient-to-r from-emerald-500 to-green-600 text-white py-2 rounded-lg font-bold hover:from-emerald-600 hover:to-green-700 shadow-md' }, 'Cobrar'),
                    React.createElement('button', { onClick: () => { setCarrito([]); setClienteFiado(null); }, className: 'px-4 bg-gray-200 text-gray-600 rounded-lg font-bold hover:bg-gray-300' }, 'Vaciar')
                  )
                )
      ),

      // ===================== TAB: DASHBOARD =====================
      tabActiva === 'dashboard' && React.createElement('div', { className: 'space-y-6' },
        React.createElement('h2', { className: 'text-2xl font-bold text-emerald-800 flex items-center gap-2' },
          React.createElement(Icon, { name: 'chart-bar' }),
          'Panel de Control'
        ),
        React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4' },
          React.createElement(SummaryCard, { titulo: 'Ventas Hoy', valor: fMoneda(totalVentasHoy), color: 'emerald', icono: 'dollar-sign' }),
          React.createElement(SummaryCard, { titulo: 'Ventas del Mes', valor: fMoneda(totalVentasMes), color: 'blue', icono: 'trending-up' }),
          React.createElement(SummaryCard, { titulo: 'Gastos del Mes', valor: fMoneda(totalGastosMes), color: 'red', icono: 'trending-down' }),
          React.createElement(SummaryCard, { titulo: 'Ganancia Neta', valor: fMoneda(totalVentasMes - totalGastosMes), color: 'purple', icono: 'wallet' }),
          React.createElement(SummaryCard, { titulo: 'Productos', valor: productos.length, color: 'amber', icono: 'package' }),
          React.createElement(SummaryCard, { titulo: 'Stock Bajo', valor: productosSinStock.length, color: 'red', icono: 'alert-triangle' }),
          React.createElement(SummaryCard, { titulo: 'Proveedores', valor: proveedores.length, color: 'teal', icono: 'users' }),
          React.createElement(SummaryCard, { titulo: 'Clientes', valor: clientes.length, color: 'indigo', icono: 'user' })
        ),
        React.createElement('div', { className: 'grid grid-cols-1 lg:grid-cols-2 gap-6' },
          React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
            React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, React.createElement(Icon, { name: 'chart-bar' }), ' Ventas Recientes'),
            React.createElement('div', { className: 'space-y-2' },
              ventas.slice(-10).reverse().map(v =>
                React.createElement('div', { key: v.id, className: 'flex justify-between items-center border-b border-emerald-50 pb-1' },
                  React.createElement('div', null,
                    React.createElement('div', { className: 'text-sm font-medium' }, v.cliente),
                    React.createElement('div', { className: 'text-xs text-gray-400' }, v.fecha + ' - ' + v.metodoPago)
                  ),
                  React.createElement('div', { className: 'text-sm font-bold text-emerald-600' }, fMoneda(v.total))
                )
              ),
              ventas.length === 0 && React.createElement('div', { className: 'text-gray-400 text-center py-4' }, 'No hay ventas registradas')
            )
          ),
          React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
            React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, React.createElement(Icon, { name: 'alert-triangle' }), ' Productos con Stock Bajo'),
            React.createElement('div', { className: 'space-y-2' },
              productosSinStock.slice(0, 15).map(p =>
                React.createElement('div', { key: p.id, className: 'flex justify-between items-center border-b border-red-50 pb-1' },
                  React.createElement('div', null,
                    React.createElement('div', { className: 'text-sm font-medium' }, p.nombre),
                    React.createElement('div', { className: 'text-xs text-gray-400' }, 'C\u00f3digo: ' + p.codigo)
                  ),
                  React.createElement('div', { className: 'text-sm font-bold text-red-500' }, p.stock + ' / ' + p.stockMinimo)
                )
              ),
              productosSinStock.length === 0 && React.createElement('div', { className: 'text-green-500 text-center py-4' }, 'Todos los productos tienen stock suficiente')
            )
          ),
          React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
            React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, React.createElement(Icon, { name: 'calendar' }), ' Gastos por Categoría'),
            React.createElement('div', { className: 'space-y-2' },
              Object.entries(gastosPorCategoria).sort((a, b) => b[1] - a[1]).map(([cat, monto]) =>
                React.createElement('div', { key: cat, className: 'flex justify-between items-center border-b border-emerald-50 pb-1' },
                  React.createElement('span', { className: 'text-sm' }, cat),
                  React.createElement('span', { className: 'text-sm font-bold text-red-500' }, fMoneda(monto))
                )
              ),
              Object.keys(gastosPorCategoria).length === 0 && React.createElement('div', { className: 'text-gray-400 text-center py-4' }, 'No hay gastos registrados')
            )
          ),
          React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
            React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, React.createElement(Icon, { name: 'thumbtack' }), ' Últimos Arqueos'),
            React.createElement('div', { className: 'space-y-2' },
              arqueos.slice(-5).reverse().map(a =>
                React.createElement('div', { key: a.id, className: 'flex justify-between items-center border-b border-emerald-50 pb-1' },
                  React.createElement('div', null,
                    React.createElement('div', { className: 'text-sm font-medium' }, a.fecha + ' ' + a.hora),
                    React.createElement('div', { className: 'text-xs text-gray-400' }, 'Dif: ' + fMoneda(a.diferencia))
                  ),
                  React.createElement('div', { className: 'text-sm font-bold ' + (a.diferencia >= 0 ? 'text-emerald-500' : 'text-red-500') }, a.estado)
                )
              ),
              arqueos.length === 0 && React.createElement('div', { className: 'text-gray-400 text-center py-4' }, 'No hay arqueos registrados')
            )
          )
        )
      ),

      // ===================== TAB: POS =====================
      tabActiva === 'pos' && React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
        React.createElement('h2', { className: 'text-xl font-bold text-emerald-800 mb-4 flex items-center gap-2' },
          React.createElement(Icon, { name: 'credit-card' }),
          'Punto de Venta'
        ),
        React.createElement('div', { className: 'grid grid-cols-1 lg:grid-cols-3 gap-4' },
          React.createElement('div', { className: 'lg:col-span-2' },
            React.createElement('input', {
              type: 'text',
              placeholder: 'Buscar producto...',
              className: 'w-full p-2 border border-emerald-200 rounded-lg mb-3 focus:ring-2 focus:ring-emerald-400',
              value: busquedaProducto,
              onChange: (e) => setBusquedaProducto(e.target.value)
            }),
            React.createElement('div', { className: 'grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 max-h-96 overflow-y-auto' },
              productos.filter(p => {
                const q = busquedaProducto.toLowerCase();
                return p.nombre.toLowerCase().includes(q) || p.codigo.toLowerCase().includes(q);
              }).slice(0, 50).map(prod =>
                React.createElement('button', {
                  key: prod.id,
                  onClick: () => agregarAlCarrito(prod),
                  className: 'bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 rounded-lg p-2 text-left transition-all hover:shadow-md'
                },
                  React.createElement('div', { className: 'text-xs text-gray-500' }, prod.codigo),
                  React.createElement('div', { className: 'font-medium text-sm text-gray-800 truncate' }, prod.nombre),
                  React.createElement('div', { className: 'text-sm font-bold text-emerald-600' }, fMoneda(prod.precioVenta)),
                  React.createElement('div', { className: 'text-xs ' + (prod.stock <= prod.stockMinimo ? 'text-red-500' : 'text-gray-400') }, 'Stock: ' + prod.stock)
                )
              )
            )
          ),
          React.createElement('div', { className: 'bg-emerald-50 rounded-lg p-3 border border-emerald-200' },
            React.createElement('h3', { className: 'font-bold text-emerald-800 mb-2 text-center' }, 'Carrito'),
            carrito.length === 0
              ? React.createElement('p', { className: 'text-gray-400 text-center py-6 text-sm' }, 'Carrito vac\u00edo')
              : React.createElement('div', { className: 'space-y-1 max-h-60 overflow-y-auto' },
                  carrito.map(item => {
                    const prod = productos.find(p => p.id === item.productoId);
                    const unidad = item.unidad || (prod ? prod.unidad : 'und');
                    const esPesable = unidad !== 'und';
                    const paso = esPesable ? 0.5 : 1;
                    return React.createElement('div', { key: item.productoId, className: 'bg-white rounded-lg p-2 text-sm shadow-sm border border-emerald-50' },
                      React.createElement('div', { className: 'flex justify-between items-start mb-1' },
                        React.createElement('div', { className: 'flex-1 truncate font-medium' }, item.nombre),
                        React.createElement('button', { onClick: () => quitarDelCarrito(item.productoId), className: 'text-red-400 hover:text-red-600' },
                          React.createElement(Icon, { name: 'x' })
                        )
                      ),
                      React.createElement('div', { className: 'flex justify-between items-center' },
                        React.createElement('div', { className: 'flex items-center gap-1 bg-gray-50 rounded p-1' },
                          React.createElement('button', { onClick: () => cambiarCantidadCarrito(item.productoId, item.cantidad - paso), className: 'w-6 h-6 bg-white border border-gray-200 rounded-full text-xs font-bold text-red-600' }, '-'),
                          React.createElement('input', {
                            type: 'number',
                            value: item.cantidad,
                            onChange: (e) => cambiarCantidadCarrito(item.productoId, Number(e.target.value)),
                            step: paso,
                            min: esPesable ? 0.1 : 1,
                            className: 'font-bold w-10 text-center border-0 bg-transparent text-xs'
                          }),
                          React.createElement('button', { onClick: () => cambiarCantidadCarrito(item.productoId, item.cantidad + paso), className: 'w-6 h-6 bg-white border border-gray-200 rounded-full text-xs font-bold text-emerald-600' }, '+')
                        ),
                        React.createElement('span', { className: 'font-bold text-emerald-700' }, fMoneda(item.subtotal))
                      )
                    );
                  }),
                  React.createElement('div', { className: 'border-t border-emerald-200 pt-2 mt-2 space-y-1' },
                    React.createElement('div', { className: 'flex justify-between text-sm' },
                      React.createElement('span', { className: 'text-gray-600' }, 'Subtotal:'),
                      React.createElement('span', { className: 'font-medium' }, fMoneda(totalCarrito()))
                    ),
                    (descuentoPorcentaje || descuentoMonto) && React.createElement('div', { className: 'flex justify-between text-sm text-red-600' },
                      React.createElement('span', null, 'Descuento:'),
                      React.createElement('span', { className: 'font-medium' }, '-' + fMoneda(calcularDescuento()))
                    ),
                    React.createElement('div', { className: 'flex justify-between font-bold text-lg' },
                      React.createElement('span', null, 'Total:'),
                      React.createElement('span', { className: 'text-emerald-700' }, fMoneda(totalConDescuento()))
                    )
                  ),
                  React.createElement('div', { className: 'space-y-2 mt-3' },
                    React.createElement('select', {
                      className: 'w-full p-2 border border-emerald-200 rounded-lg text-sm',
                      value: clienteFiado ? clienteFiado.id : '',
                      onChange: (e) => {
                        const id = Number(e.target.value);
                        setClienteFiado(id ? clientes.find(c => c.id === id) : null);
                      }
                    },
                      React.createElement('option', { value: '' }, 'Cliente ocasional (contado)'),
                      clientes.filter(c => c.tipo !== 'Ocasional').map(c =>
                        React.createElement('option', { key: c.id, value: c.id }, c.nombre + ' (' + fMoneda(c.saldoPendiente) + ')')
                      )
                    ),
                    React.createElement('button', {
                      onClick: () => abrirModalPago(),
                      className: 'w-full bg-gradient-to-r from-emerald-500 to-green-600 text-white py-2 rounded-lg font-bold hover:from-emerald-600 hover:to-green-700 shadow-md'
                    }, 'Cobrar (' + fMoneda(totalCarrito()) + ')'),
                    React.createElement('button', {
                      onClick: () => { setCarrito([]); setClienteFiado(null); },
                      className: 'w-full bg-gray-200 text-gray-600 py-1 rounded-lg text-sm hover:bg-gray-300'
                    }, 'Vaciar carrito')
                  )
                )
          )
        )
      ),

      // ===================== TAB: FIADOS =====================
      tabActiva === 'fiados' && React.createElement('div', { className: 'space-y-4' },
        React.createElement('h2', { className: 'text-2xl font-bold text-emerald-800 flex items-center gap-2' },
          React.createElement(Icon, { name: 'wallet' }),
          'Fiados / Cr\u00e9ditos'
        ),
        React.createElement('div', { className: 'grid grid-cols-1 lg:grid-cols-3 gap-4' },
          React.createElement('div', { className: 'lg:col-span-2 bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
            React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, 'Clientes con Saldo Pendiente'),
            React.createElement('div', { className: 'overflow-x-auto' },
              React.createElement('table', { className: 'w-full text-sm' },
                React.createElement('thead', null,
                  React.createElement('tr', { className: 'bg-emerald-50' },
                    React.createElement('th', { className: 'p-2 text-left' }, 'Cliente'),
                    React.createElement('th', { className: 'p-2 text-left' }, 'Tel\u00e9fono'),
                    React.createElement('th', { className: 'p-2 text-right' }, 'L\u00edmite'),
                    React.createElement('th', { className: 'p-2 text-right' }, 'Saldo'),
                    React.createElement('th', { className: 'p-2 text-right' }, 'Disponible'),
                    React.createElement('th', { className: 'p-2 text-center' }, 'Acci\u00f3n')
                  )
                ),
                React.createElement('tbody', null,
                  clientes.filter(c => c.saldoPendiente > 0).map(c =>
                    React.createElement('tr', { key: c.id, className: 'border-b border-emerald-50 hover:bg-emerald-50' },
                      React.createElement('td', { className: 'p-2 font-medium' }, c.nombre),
                      React.createElement('td', { className: 'p-2 text-gray-500' }, c.telefono || '-'),
                      React.createElement('td', { className: 'p-2 text-right' }, fMoneda(c.creditoMaximo)),
                      React.createElement('td', { className: 'p-2 text-right text-red-500 font-bold' }, fMoneda(c.saldoPendiente)),
                      React.createElement('td', { className: 'p-2 text-right text-emerald-600' }, fMoneda(c.creditoMaximo - c.saldoPendiente)),
                      React.createElement('td', { className: 'p-2 text-center' },
                        React.createElement('button', {
                          onClick: () => {
                            const abono = prompt('Ingrese el monto del abono para ' + c.nombre + ':', '0');
                            if (abono && Number(abono) > 0) {
                              const montoAbono = Math.min(Number(abono), c.saldoPendiente);
                              setClientes(clientes.map(cl => cl.id === c.id ? { ...cl, saldoPendiente: cl.saldoPendiente - montoAbono } : cl));
                              notificar('Abono registrado: ' + fMoneda(montoAbono), 'exito');
                            }
                          },
                          className: 'bg-emerald-100 text-emerald-700 px-3 py-1 rounded text-xs hover:bg-emerald-200'
                        }, 'Abonar')
                      )
                    )
                  ),
                  clientes.filter(c => c.saldoPendiente > 0).length === 0 && React.createElement('tr', null,
                    React.createElement('td', { colSpan: 6, className: 'text-center text-gray-400 py-4' }, 'No hay saldos pendientes')
                  )
                )
              )
            )
          ),
          React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
            React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, 'Resumen Fiados'),
            React.createElement('div', { className: 'space-y-3' },
              React.createElement('div', { className: 'bg-blue-50 rounded-lg p-3 text-center' },
                React.createElement('div', { className: 'text-sm text-gray-500' }, 'Total por Cobrar'),
                React.createElement('div', { className: 'text-2xl font-bold text-blue-600' }, fMoneda(clientes.reduce((s, c) => s + c.saldoPendiente, 0)))
              ),
              React.createElement('div', { className: 'bg-emerald-50 rounded-lg p-3 text-center' },
                React.createElement('div', { className: 'text-sm text-gray-500' }, 'Clientes con Deuda'),
                React.createElement('div', { className: 'text-2xl font-bold text-emerald-600' }, clientes.filter(c => c.saldoPendiente > 0).length)
              ),
              React.createElement('div', { className: 'bg-purple-50 rounded-lg p-3 text-center' },
                React.createElement('div', { className: 'text-sm text-gray-500' }, 'Total Cr\u00e9dito Disponible'),
                React.createElement('div', { className: 'text-2xl font-bold text-purple-600' }, fMoneda(clientes.reduce((s, c) => s + (c.creditoMaximo - c.saldoPendiente), 0)))
              )
            )
          )
        )
      ),

      // ===================== TAB: CAJA =====================
      tabActiva === 'caja' && React.createElement('div', { className: 'space-y-4' },
        React.createElement('div', { className: 'flex justify-between items-center' },
          React.createElement('h2', { className: 'text-2xl font-bold text-emerald-800 flex items-center gap-2' },
            React.createElement(Icon, { name: 'receipt' }),
            'Caja / Arqueo'
          ),
          React.createElement('button', {
            onClick: () => abrirModalArqueo(),
            className: 'bg-green-600 text-white px-4 py-2 rounded-lg font-bold hover:bg-green-700 shadow-md'
          }, '+ Nuevo Arqueo')
        ),
        React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100 overflow-x-auto' },
          React.createElement('table', { className: 'w-full text-sm' },
            React.createElement('thead', null,
              React.createElement('tr', { className: 'bg-emerald-50' },
                React.createElement('th', { className: 'p-2 text-left' }, 'Fecha'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Hora'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Inicial'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Ingresos'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Egresos'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Final'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Diferencia'),
                React.createElement('th', { className: 'p-2 text-center' }, 'Estado'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Obs.')
              )
            ),
            React.createElement('tbody', null,
              [...arqueos].reverse().map(a =>
                React.createElement('tr', { key: a.id, className: 'border-b border-emerald-50 hover:bg-emerald-50' },
                  React.createElement('td', { className: 'p-2' }, a.fecha),
                  React.createElement('td', { className: 'p-2 text-gray-500' }, a.hora),
                  React.createElement('td', { className: 'p-2 text-right' }, fMoneda(a.montoInicial)),
                  React.createElement('td', { className: 'p-2 text-right text-emerald-600' }, fMoneda(a.ingresosEsperados)),
                  React.createElement('td', { className: 'p-2 text-right text-red-500' }, fMoneda(a.egresos)),
                  React.createElement('td', { className: 'p-2 text-right font-bold' }, fMoneda(a.montoFinalReal)),
                  React.createElement('td', { className: 'p-2 text-right font-bold ' + (a.diferencia >= 0 ? 'text-emerald-500' : 'text-red-500') }, fMoneda(a.diferencia)),
                  React.createElement('td', { className: 'p-2 text-center' },
                    React.createElement('span', { className: 'px-2 py-1 rounded text-xs ' + (a.estado === 'OK' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700') }, a.estado)
                  ),
                  React.createElement('td', { className: 'p-2 text-gray-500 text-xs max-w-xs truncate' }, a.observaciones)
                )
              ),
              arqueos.length === 0 && React.createElement('tr', null,
                React.createElement('td', { colSpan: 9, className: 'text-center text-gray-400 py-4' }, 'No hay arqueos registrados')
              )
            )
          )
        )
      ),

      // ===================== TAB: INVENTARIO =====================
      tabActiva === 'inventario' && React.createElement('div', { className: 'space-y-4' },
        React.createElement('div', { className: 'flex justify-between items-center flex-wrap gap-2' },
          React.createElement('h2', { className: 'text-2xl font-bold text-emerald-800 flex items-center gap-2' },
            React.createElement(Icon, { name: 'package' }),
            'Inventario'
          ),
          React.createElement('div', { className: 'flex gap-2 flex-wrap' },
            React.createElement('input', {
              type: 'text',
              placeholder: 'Buscar...',
              className: 'p-2 border border-emerald-200 rounded-lg text-sm',
              value: filtroProducto,
              onChange: (e) => setFiltroProducto(e.target.value)
            }),
            React.createElement('select', {
              className: 'p-2 border border-emerald-200 rounded-lg text-sm',
              value: filtroCategoria,
              onChange: (e) => setFiltroCategoria(e.target.value)
            },
              React.createElement('option', { value: '' }, 'Todas las categor\u00edas'),
              categorias.map(c => React.createElement('option', { key: c, value: c }, c))
            ),
            React.createElement('button', {
              onClick: () => setFormProducto({ id: null, codigo: '', nombre: '', categoria: '', precioCompra: '', precioVenta: '', stock: '', stockMinimo: '', unidad: 'und' }),
              className: 'bg-emerald-600 text-white px-3 py-2 rounded-lg text-sm font-bold hover:bg-emerald-700 shadow-md'
            }, '+ Nuevo Producto')
          )
        ),
        formProducto.nombre !== undefined && (formProducto.id || formProducto.codigo !== undefined) && React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
          React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, formProducto.id ? 'Editar Producto' : 'Nuevo Producto'),
          React.createElement('div', { className: 'grid grid-cols-2 md:grid-cols-4 gap-3' },
            React.createElement('input', { type: 'text', placeholder: 'C\u00f3digo *', className: 'p-2 border rounded text-sm', value: formProducto.codigo, onChange: (e) => setFormProducto({ ...formProducto, codigo: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Nombre *', className: 'p-2 border rounded text-sm', value: formProducto.nombre, onChange: (e) => setFormProducto({ ...formProducto, nombre: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Categor\u00eda', className: 'p-2 border rounded text-sm', value: formProducto.categoria, onChange: (e) => setFormProducto({ ...formProducto, categoria: e.target.value }) }),
            React.createElement('input', { type: 'number', placeholder: 'P. Compra', className: 'p-2 border rounded text-sm', value: formProducto.precioCompra, onChange: (e) => setFormProducto({ ...formProducto, precioCompra: e.target.value }) }),
            React.createElement('input', { type: 'number', placeholder: 'P. Venta *', className: 'p-2 border rounded text-sm', value: formProducto.precioVenta, onChange: (e) => setFormProducto({ ...formProducto, precioVenta: e.target.value }) }),
            React.createElement('input', { type: 'number', placeholder: 'Stock', className: 'p-2 border rounded text-sm', value: formProducto.stock, onChange: (e) => setFormProducto({ ...formProducto, stock: e.target.value }) }),
            React.createElement('input', { type: 'number', placeholder: 'Stock M\u00edn', className: 'p-2 border rounded text-sm', value: formProducto.stockMinimo, onChange: (e) => setFormProducto({ ...formProducto, stockMinimo: e.target.value }) }),
            React.createElement('select', { className: 'p-2 border rounded text-sm', value: formProducto.unidad, onChange: (e) => setFormProducto({ ...formProducto, unidad: e.target.value }) },
              React.createElement('option', { value: 'und' }, 'Unidad'),
              React.createElement('option', { value: 'kg' }, 'Kilogramo'),
              React.createElement('option', { value: 'lb' }, 'Libra'),
              React.createElement('option', { value: 'g' }, 'Gramo'),
              React.createElement('option', { value: 'L' }, 'Litro'),
              React.createElement('option', { value: 'ml' }, 'Mililitro')
            )
          ),
          React.createElement('div', { className: 'flex gap-2 mt-3' },
            React.createElement('button', { onClick: guardarProducto, className: 'bg-emerald-600 text-white px-4 py-2 rounded-lg font-bold hover:bg-emerald-700 text-sm' }, 'Guardar'),
            React.createElement('button', { onClick: () => setFormProducto({ id: null, codigo: '', nombre: '', categoria: '', precioCompra: '', precioVenta: '', stock: '', stockMinimo: '', unidad: 'und' }), className: 'bg-gray-200 text-gray-600 px-4 py-2 rounded-lg text-sm hover:bg-gray-300' }, 'Cancelar')
          )
        ),
        React.createElement('div', { className: 'bg-white rounded-xl shadow-lg border border-emerald-100 overflow-x-auto' },
          React.createElement('table', { className: 'w-full text-sm' },
            React.createElement('thead', null,
              React.createElement('tr', { className: 'bg-emerald-50' },
                React.createElement('th', { className: 'p-2 text-left' }, 'C\u00f3digo'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Nombre'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Categor\u00eda'),
                React.createElement('th', { className: 'p-2 text-right' }, 'P.Compra'),
                React.createElement('th', { className: 'p-2 text-right' }, 'P.Venta'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Stock'),
                React.createElement('th', { className: 'p-2 text-right' }, 'M\u00edn'),
                React.createElement('th', { className: 'p-2 text-center' }, 'Acciones')
              )
            ),
            React.createElement('tbody', null,
              productosFiltrados.map(prod =>
                React.createElement('tr', { key: prod.id, className: 'border-b border-emerald-50 hover:bg-emerald-50 ' + (prod.stock <= prod.stockMinimo ? 'bg-red-50' : '') },
                  React.createElement('td', { className: 'p-2 font-mono text-xs' }, prod.codigo),
                  React.createElement('td', { className: 'p-2' }, prod.nombre),
                  React.createElement('td', { className: 'p-2 text-gray-500' }, prod.categoria || '-'),
                  React.createElement('td', { className: 'p-2 text-right text-gray-500' }, fMoneda(prod.precioCompra)),
                  React.createElement('td', { className: 'p-2 text-right font-medium' }, fMoneda(prod.precioVenta)),
                  React.createElement('td', { className: 'p-2 text-right font-bold ' + (prod.stock <= prod.stockMinimo ? 'text-red-500' : 'text-emerald-600') }, prod.stock),
                  React.createElement('td', { className: 'p-2 text-right text-gray-400' }, prod.stockMinimo),
                  React.createElement('td', { className: 'p-2 text-center' },
                    React.createElement('div', { className: 'flex gap-1 justify-center' },
                      React.createElement('button', { onClick: () => editarProducto(prod), className: 'text-blue-500 hover:text-blue-700 text-xs px-2 py-1 bg-blue-50 rounded' }, 'Editar'),
                      React.createElement('button', { onClick: () => eliminarProducto(prod.id), className: 'text-red-500 hover:text-red-700 text-xs px-2 py-1 bg-red-50 rounded' }, 'Eliminar')
                    )
                  )
                )
              ),
              productosFiltrados.length === 0 && React.createElement('tr', null,
                React.createElement('td', { colSpan: 8, className: 'text-center text-gray-400 py-4' }, 'No se encontraron productos')
              )
            )
          )
        )
      ),

      // ===================== TAB: COMPRAS =====================
      tabActiva === 'compras' && React.createElement('div', { className: 'space-y-4' },
        React.createElement('div', { className: 'flex justify-between items-center' },
          React.createElement('h2', { className: 'text-2xl font-bold text-emerald-800 flex items-center gap-2' },
            React.createElement(Icon, { name: 'truck' }),
            'Compras'
          ),
          React.createElement('button', {
            onClick: () => setFormCompra({ id: null, proveedorId: '', fecha: hoy(), items: [], total: 0, estado: 'Pendiente' }),
            className: 'bg-emerald-600 text-white px-4 py-2 rounded-lg font-bold hover:bg-emerald-700 shadow-md'
          }, '+ Nueva Compra')
        ),
        formCompra.proveedorId !== undefined && React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
          React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, formCompra.id ? 'Editar Compra' : 'Nueva Compra'),
          React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-3 gap-3 mb-4' },
            React.createElement('select', {
              className: 'p-2 border rounded text-sm',
              value: formCompra.proveedorId,
              onChange: (e) => setFormCompra({ ...formCompra, proveedorId: e.target.value })
            },
              React.createElement('option', { value: '' }, 'Seleccionar proveedor *'),
              proveedores.map(p => React.createElement('option', { key: p.id, value: p.id }, p.nombre))
            ),
            React.createElement('input', { type: 'date', className: 'p-2 border rounded text-sm', value: formCompra.fecha, onChange: (e) => setFormCompra({ ...formCompra, fecha: e.target.value }) }),
            React.createElement('select', {
              className: 'p-2 border rounded text-sm',
              value: formCompra.estado,
              onChange: (e) => setFormCompra({ ...formCompra, estado: e.target.value })
            },
              React.createElement('option', { value: 'Pendiente' }, 'Pendiente'),
              React.createElement('option', { value: 'Completada' }, 'Completada'),
              React.createElement('option', { value: 'Cancelada' }, 'Cancelada')
            )
          ),
          React.createElement('div', { className: 'border-t border-emerald-100 pt-3' },
            React.createElement('h4', { className: 'font-bold text-sm text-emerald-600 mb-2' }, 'Agregar Productos'),
            React.createElement('div', { className: 'flex gap-2 flex-wrap items-end' },
              React.createElement('div', null,
                React.createElement('label', { className: 'block text-xs text-gray-500 mb-1' }, 'Producto'),
                React.createElement('select', {
                  id: 'select-producto-compra',
                  className: 'p-2 border rounded text-sm w-48',
                  defaultValue: ''
                },
                  React.createElement('option', { value: '', disabled: true }, 'Seleccionar...'),
                  productos.map(p => React.createElement('option', { key: p.id, value: p.id }, p.nombre + ' (' + p.codigo + ')'))
                )
              ),
              React.createElement('div', null,
                React.createElement('label', { className: 'block text-xs text-gray-500 mb-1' }, 'Cantidad'),
                React.createElement('input', { id: 'cantidad-compra', type: 'number', min: 1, className: 'p-2 border rounded text-sm w-20', defaultValue: 1 })
              ),
              React.createElement('div', null,
                React.createElement('label', { className: 'block text-xs text-gray-500 mb-1' }, 'P. Compra Unit.'),
                React.createElement('input', { id: 'precio-compra-item', type: 'number', className: 'p-2 border rounded text-sm w-24' })
              ),
              React.createElement('button', {
                onClick: () => {
                  const sel = document.getElementById('select-producto-compra');
                  const cant = document.getElementById('cantidad-compra');
                  const prec = document.getElementById('precio-compra-item');
                  if (sel && sel.value && cant && cant.value) {
                    agregarItemCompra(sel.value, cant.value, prec ? prec.value : 0);
                    sel.value = '';
                    cant.value = 1;
                    if (prec) prec.value = '';
                  } else {
                    notificar('Seleccione producto y cantidad', 'error');
                  }
                },
                className: 'bg-blue-500 text-white px-3 py-2 rounded text-sm hover:bg-blue-600'
              }, 'Agregar')
            )
          ),
          formCompra.items.length > 0 && React.createElement('div', { className: 'mt-4' },
            React.createElement('h4', { className: 'font-bold text-sm text-emerald-600 mb-2' }, 'Items (' + formCompra.items.length + ')'),
            React.createElement('div', { className: 'space-y-1' },
              formCompra.items.map(item =>
                React.createElement('div', { key: item.productoId, className: 'flex items-center justify-between bg-emerald-50 rounded p-2 text-sm' },
                  React.createElement('span', { className: 'flex-1' }, item.nombre + ' x' + item.cantidad + ' @ ' + fMoneda(item.precioCompra)),
                  React.createElement('span', { className: 'font-bold mx-2' }, fMoneda(item.subtotal)),
                  React.createElement('button', { onClick: () => quitarItemCompra(item.productoId), className: 'text-red-400 hover:text-red-600' },
                    React.createElement(Icon, { name: 'x' })
                  )
                )
              )
            ),
            React.createElement('div', { className: 'text-right font-bold text-lg mt-2 border-t pt-2' }, 'Total: ' + fMoneda(formCompra.total))
          ),
          React.createElement('div', { className: 'flex gap-2 mt-3' },
            React.createElement('button', { onClick: guardarCompra, className: 'bg-emerald-600 text-white px-4 py-2 rounded-lg font-bold hover:bg-emerald-700 text-sm', disabled: formCompra.items.length === 0 }, 'Guardar Compra'),
            React.createElement('button', { onClick: () => setFormCompra({ id: null, proveedorId: '', fecha: hoy(), items: [], total: 0, estado: 'Pendiente' }), className: 'bg-gray-200 text-gray-600 px-4 py-2 rounded-lg text-sm hover:bg-gray-300' }, 'Cancelar')
          )
        ),
        React.createElement('div', { className: 'bg-white rounded-xl shadow-lg border border-emerald-100 overflow-x-auto' },
          React.createElement('table', { className: 'w-full text-sm' },
            React.createElement('thead', null,
              React.createElement('tr', { className: 'bg-emerald-50' },
                React.createElement('th', { className: 'p-2 text-left' }, 'Fecha'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Proveedor'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Items'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Total'),
                React.createElement('th', { className: 'p-2 text-center' }, 'Estado'),
                React.createElement('th', { className: 'p-2 text-center' }, 'Acci\u00f3n')
              )
            ),
            React.createElement('tbody', null,
              [...compras].reverse().map(c =>
                React.createElement('tr', { key: c.id, className: 'border-b border-emerald-50 hover:bg-emerald-50' },
                  React.createElement('td', { className: 'p-2' }, c.fecha),
                  React.createElement('td', { className: 'p-2' }, proveedores.find(p => p.id === c.proveedorId)?.nombre || 'N/A'),
                  React.createElement('td', { className: 'p-2 text-right' }, c.items.length),
                  React.createElement('td', { className: 'p-2 text-right font-bold' }, fMoneda(c.total)),
                  React.createElement('td', { className: 'p-2 text-center' },
                    React.createElement('span', { className: 'px-2 py-1 rounded text-xs ' + (c.estado === 'Completada' ? 'bg-green-100 text-green-700' : c.estado === 'Cancelada' ? 'bg-red-100 text-red-700' : 'bg-yellow-100 text-yellow-700') }, c.estado)
                  ),
                  React.createElement('td', { className: 'p-2 text-center' },
                    React.createElement('button', { onClick: () => eliminarCompra(c.id), className: 'text-red-500 hover:text-red-700 text-xs px-2 py-1 bg-red-50 rounded' }, 'Eliminar')
                  )
                )
              ),
              compras.length === 0 && React.createElement('tr', null,
                React.createElement('td', { colSpan: 6, className: 'text-center text-gray-400 py-4' }, 'No hay compras registradas')
              )
            )
          )
        )
      ),

      // ===================== TAB: PROVEEDORES =====================
      tabActiva === 'proveedores' && React.createElement('div', { className: 'space-y-4' },
        React.createElement('div', { className: 'flex justify-between items-center flex-wrap gap-2' },
          React.createElement('h2', { className: 'text-2xl font-bold text-emerald-800 flex items-center gap-2' },
            React.createElement(Icon, { name: 'users' }),
            'Proveedores'
          ),
          React.createElement('div', { className: 'flex gap-2 flex-wrap' },
            React.createElement('input', {
              type: 'text',
              placeholder: 'Buscar...',
              className: 'p-2 border border-emerald-200 rounded-lg text-sm',
              value: filtroProveedor,
              onChange: (e) => setFiltroProveedor(e.target.value)
            }),
            React.createElement('button', {
              onClick: () => setFormProveedor({ id: null, nombre: '', contacto: '', telefono: '', email: '', direccion: '', tipo: '' }),
              className: 'bg-emerald-600 text-white px-3 py-2 rounded-lg text-sm font-bold hover:bg-emerald-700 shadow-md'
            }, '+ Nuevo Proveedor')
          )
        ),
        formProveedor.nombre !== undefined && (formProveedor.id || formProveedor.nombre !== undefined) && React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
          React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, formProveedor.id ? 'Editar Proveedor' : 'Nuevo Proveedor'),
          React.createElement('div', { className: 'grid grid-cols-2 md:grid-cols-3 gap-3' },
            React.createElement('input', { type: 'text', placeholder: 'Nombre *', className: 'p-2 border rounded text-sm', value: formProveedor.nombre, onChange: (e) => setFormProveedor({ ...formProveedor, nombre: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Contacto', className: 'p-2 border rounded text-sm', value: formProveedor.contacto, onChange: (e) => setFormProveedor({ ...formProveedor, contacto: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Tel\u00e9fono', className: 'p-2 border rounded text-sm', value: formProveedor.telefono, onChange: (e) => setFormProveedor({ ...formProveedor, telefono: e.target.value }) }),
            React.createElement('input', { type: 'email', placeholder: 'Email', className: 'p-2 border rounded text-sm', value: formProveedor.email, onChange: (e) => setFormProveedor({ ...formProveedor, email: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Direcci\u00f3n', className: 'p-2 border rounded text-sm', value: formProveedor.direccion, onChange: (e) => setFormProveedor({ ...formProveedor, direccion: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Tipo (L\u00e1cteos, Despensa...)', className: 'p-2 border rounded text-sm', value: formProveedor.tipo, onChange: (e) => setFormProveedor({ ...formProveedor, tipo: e.target.value }) })
          ),
          React.createElement('div', { className: 'flex gap-2 mt-3' },
            React.createElement('button', { onClick: guardarProveedor, className: 'bg-emerald-600 text-white px-4 py-2 rounded-lg font-bold hover:bg-emerald-700 text-sm' }, 'Guardar'),
            React.createElement('button', { onClick: () => setFormProveedor({ id: null, nombre: '', contacto: '', telefono: '', email: '', direccion: '', tipo: '' }), className: 'bg-gray-200 text-gray-600 px-4 py-2 rounded-lg text-sm hover:bg-gray-300' }, 'Cancelar')
          )
        ),
        React.createElement('div', { className: 'bg-white rounded-xl shadow-lg border border-emerald-100 overflow-x-auto' },
          React.createElement('table', { className: 'w-full text-sm' },
            React.createElement('thead', null,
              React.createElement('tr', { className: 'bg-emerald-50' },
                React.createElement('th', { className: 'p-2 text-left' }, 'Nombre'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Contacto'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Tel\u00e9fono'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Email'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Tipo'),
                React.createElement('th', { className: 'p-2 text-center' }, 'Acciones')
              )
            ),
            React.createElement('tbody', null,
              proveedoresFiltrados.map(prov =>
                React.createElement('tr', { key: prov.id, className: 'border-b border-emerald-50 hover:bg-emerald-50' },
                  React.createElement('td', { className: 'p-2 font-medium' }, prov.nombre),
                  React.createElement('td', { className: 'p-2 text-gray-500' }, prov.contacto || '-'),
                  React.createElement('td', { className: 'p-2 text-gray-500' }, prov.telefono || '-'),
                  React.createElement('td', { className: 'p-2 text-gray-500' }, prov.email || '-'),
                  React.createElement('td', { className: 'p-2' }, React.createElement('span', { className: 'bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded text-xs' }, prov.tipo || 'General')),
                  React.createElement('td', { className: 'p-2 text-center' },
                    React.createElement('div', { className: 'flex gap-1 justify-center' },
                      React.createElement('button', { onClick: () => editarProveedor(prov), className: 'text-blue-500 hover:text-blue-700 text-xs px-2 py-1 bg-blue-50 rounded' }, 'Editar'),
                      React.createElement('button', { onClick: () => eliminarProveedor(prov.id), className: 'text-red-500 hover:text-red-700 text-xs px-2 py-1 bg-red-50 rounded' }, 'Eliminar')
                    )
                  )
                )
              ),
              proveedoresFiltrados.length === 0 && React.createElement('tr', null,
                React.createElement('td', { colSpan: 6, className: 'text-center text-gray-400 py-4' }, 'No se encontraron proveedores')
              )
            )
          )
        )
      ),

      // ===================== TAB: AUTOCONSUMO =====================
      tabActiva === 'autoconsumo' && React.createElement('div', { className: 'space-y-4' },
        React.createElement('div', { className: 'flex justify-between items-center' },
          React.createElement('h2', { className: 'text-2xl font-bold text-emerald-800 flex items-center gap-2' },
            React.createElement(Icon, { name: 'factory' }),
            'Autoconsumo'
          ),
          React.createElement('button', {
            onClick: () => setFormAutoconsumo({ id: null, productoId: '', cantidad: '', fecha: hoy(), motivo: '' }),
            className: 'bg-emerald-600 text-white px-3 py-2 rounded-lg text-sm font-bold hover:bg-emerald-700 shadow-md'
          }, '+ Nuevo Registro')
        ),
        formAutoconsumo.productoId !== undefined && React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
          React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, 'Registrar Autoconsumo'),
          React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-4 gap-3' },
            React.createElement('select', {
              className: 'p-2 border rounded text-sm',
              value: formAutoconsumo.productoId,
              onChange: (e) => setFormAutoconsumo({ ...formAutoconsumo, productoId: e.target.value })
            },
              React.createElement('option', { value: '' }, 'Seleccionar producto *'),
              productos.map(p => React.createElement('option', { key: p.id, value: p.id }, p.nombre + ' (Stock: ' + p.stock + ')'))
            ),
            React.createElement('input', { type: 'number', min: 1, placeholder: 'Cantidad *', className: 'p-2 border rounded text-sm', value: formAutoconsumo.cantidad, onChange: (e) => setFormAutoconsumo({ ...formAutoconsumo, cantidad: e.target.value }) }),
            React.createElement('input', { type: 'date', className: 'p-2 border rounded text-sm', value: formAutoconsumo.fecha, onChange: (e) => setFormAutoconsumo({ ...formAutoconsumo, fecha: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Motivo', className: 'p-2 border rounded text-sm', value: formAutoconsumo.motivo, onChange: (e) => setFormAutoconsumo({ ...formAutoconsumo, motivo: e.target.value }) })
          ),
          React.createElement('div', { className: 'flex gap-2 mt-3' },
            React.createElement('button', { onClick: guardarAutoconsumo, className: 'bg-emerald-600 text-white px-4 py-2 rounded-lg font-bold hover:bg-emerald-700 text-sm' }, 'Registrar'),
            React.createElement('button', { onClick: () => setFormAutoconsumo({ id: null, productoId: '', cantidad: '', fecha: hoy(), motivo: '' }), className: 'bg-gray-200 text-gray-600 px-4 py-2 rounded-lg text-sm hover:bg-gray-300' }, 'Cancelar')
          )
        ),
        React.createElement('div', { className: 'bg-white rounded-xl shadow-lg border border-emerald-100 overflow-x-auto' },
          React.createElement('table', { className: 'w-full text-sm' },
            React.createElement('thead', null,
              React.createElement('tr', { className: 'bg-emerald-50' },
                React.createElement('th', { className: 'p-2 text-left' }, 'Fecha'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Producto'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Cantidad'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Motivo'),
                React.createElement('th', { className: 'p-2 text-center' }, 'Acci\u00f3n')
              )
            ),
            React.createElement('tbody', null,
              [...autoconsumos].reverse().map(a => {
                const prod = productos.find(p => p.id === a.productoId);
                return React.createElement('tr', { key: a.id, className: 'border-b border-emerald-50 hover:bg-emerald-50' },
                  React.createElement('td', { className: 'p-2' }, a.fecha),
                  React.createElement('td', { className: 'p-2' }, prod ? prod.nombre : 'Producto eliminado'),
                  React.createElement('td', { className: 'p-2 text-right font-bold' }, a.cantidad),
                  React.createElement('td', { className: 'p-2 text-gray-500' }, a.motivo || '-'),
                  React.createElement('td', { className: 'p-2 text-center' },
                    React.createElement('button', { onClick: () => eliminarAutoconsumo(a.id), className: 'text-red-500 hover:text-red-700 text-xs px-2 py-1 bg-red-50 rounded' }, 'Eliminar')
                  )
                );
              }),
              autoconsumos.length === 0 && React.createElement('tr', null,
                React.createElement('td', { colSpan: 5, className: 'text-center text-gray-400 py-4' }, 'No hay autoconsumos registrados')
              )
            )
          )
        )
      ),

      // ===================== TAB: CLIENTES =====================
      tabActiva === 'clientes' && React.createElement('div', { className: 'space-y-4' },
        React.createElement('div', { className: 'flex justify-between items-center' },
          React.createElement('h2', { className: 'text-2xl font-bold text-emerald-800 flex items-center gap-2' },
            React.createElement(Icon, { name: 'user' }),
            'Clientes'
          ),
          React.createElement('button', {
            onClick: () => setFormCliente({ id: null, nombre: '', telefono: '', direccion: '', tipo: 'Ocasional', creditoMaximo: '', saldoPendiente: 0 }),
            className: 'bg-emerald-600 text-white px-3 py-2 rounded-lg text-sm font-bold hover:bg-emerald-700 shadow-md'
          }, '+ Nuevo Cliente')
        ),
        formCliente.nombre !== undefined && (formCliente.id || formCliente.nombre !== undefined) && React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100' },
          React.createElement('h3', { className: 'font-bold text-emerald-700 mb-3' }, formCliente.id ? 'Editar Cliente' : 'Nuevo Cliente'),
          React.createElement('div', { className: 'grid grid-cols-2 md:grid-cols-3 gap-3' },
            React.createElement('input', { type: 'text', placeholder: 'Nombre *', className: 'p-2 border rounded text-sm', value: formCliente.nombre, onChange: (e) => setFormCliente({ ...formCliente, nombre: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Tel\u00e9fono', className: 'p-2 border rounded text-sm', value: formCliente.telefono, onChange: (e) => setFormCliente({ ...formCliente, telefono: e.target.value }) }),
            React.createElement('input', { type: 'text', placeholder: 'Direcci\u00f3n', className: 'p-2 border rounded text-sm', value: formCliente.direccion, onChange: (e) => setFormCliente({ ...formCliente, direccion: e.target.value }) }),
            React.createElement('select', { className: 'p-2 border rounded text-sm', value: formCliente.tipo, onChange: (e) => setFormCliente({ ...formCliente, tipo: e.target.value }) },
              React.createElement('option', { value: 'Frecuente' }, 'Frecuente'),
              React.createElement('option', { value: 'Comercial' }, 'Comercial'),
              React.createElement('option', { value: 'Ocasional' }, 'Ocasional')
            ),
            React.createElement('input', { type: 'number', placeholder: 'Cr\u00e9dito M\u00e1ximo', className: 'p-2 border rounded text-sm', value: formCliente.creditoMaximo, onChange: (e) => setFormCliente({ ...formCliente, creditoMaximo: e.target.value }) }),
            React.createElement('input', { type: 'number', placeholder: 'Saldo Pendiente', className: 'p-2 border rounded text-sm', value: formCliente.saldoPendiente, onChange: (e) => setFormCliente({ ...formCliente, saldoPendiente: e.target.value }) })
          ),
          React.createElement('div', { className: 'flex gap-2 mt-3' },
            React.createElement('button', { onClick: guardarCliente, className: 'bg-emerald-600 text-white px-4 py-2 rounded-lg font-bold hover:bg-emerald-700 text-sm' }, 'Guardar'),
            React.createElement('button', { onClick: () => setFormCliente({ id: null, nombre: '', telefono: '', direccion: '', tipo: 'Ocasional', creditoMaximo: '', saldoPendiente: 0 }), className: 'bg-gray-200 text-gray-600 px-4 py-2 rounded-lg text-sm hover:bg-gray-300' }, 'Cancelar')
          )
        ),
        React.createElement('div', { className: 'bg-white rounded-xl shadow-lg border border-emerald-100 overflow-x-auto' },
          React.createElement('table', { className: 'w-full text-sm' },
            React.createElement('thead', null,
              React.createElement('tr', { className: 'bg-emerald-50' },
                React.createElement('th', { className: 'p-2 text-left' }, 'Nombre'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Tel\u00e9fono'),
                React.createElement('th', { className: 'p-2 text-left' }, 'Tipo'),
                React.createElement('th', { className: 'p-2 text-right' }, 'L\u00edmite'),
                React.createElement('th', { className: 'p-2 text-right' }, 'Saldo'),
                React.createElement('th', { className: 'p-2 text-center' }, 'Acciones')
              )
            ),
            React.createElement('tbody', null,
              clientes.map(c =>
                React.createElement('tr', { key: c.id, className: 'border-b border-emerald-50 hover:bg-emerald-50' },
                  React.createElement('td', { className: 'p-2 font-medium' }, c.nombre),
                  React.createElement('td', { className: 'p-2 text-gray-500' }, c.telefono || '-'),
                  React.createElement('td', { className: 'p-2' }, React.createElement('span', { className: 'px-2 py-0.5 rounded text-xs ' + (c.tipo === 'Comercial' ? 'bg-purple-100 text-purple-700' : c.tipo === 'Frecuente' ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600') }, c.tipo)),
                  React.createElement('td', { className: 'p-2 text-right' }, fMoneda(c.creditoMaximo)),
                  React.createElement('td', { className: 'p-2 text-right font-bold ' + (c.saldoPendiente > 0 ? 'text-red-500' : 'text-emerald-500') }, fMoneda(c.saldoPendiente)),
                  React.createElement('td', { className: 'p-2 text-center' },
                    React.createElement('div', { className: 'flex gap-1 justify-center' },
                      React.createElement('button', { onClick: () => editarCliente(c), className: 'text-blue-500 hover:text-blue-700 text-xs px-2 py-1 bg-blue-50 rounded' }, 'Editar'),
                      React.createElement('button', { onClick: () => eliminarCliente(c.id), className: 'text-red-500 hover:text-red-700 text-xs px-2 py-1 bg-red-50 rounded' }, 'Eliminar')
                    )
                  )
                )
              ),
              clientes.length === 0 && React.createElement('tr', null,
                React.createElement('td', { colSpan: 6, className: 'text-center text-gray-400 py-4' }, 'No hay clientes registrados')
              )
            )
          )
        )
      )
    ),

    // ==================== MODAL: PAGO ====================
    modalPago.abierto && React.createElement('div', { className: 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4' },
      React.createElement('div', { className: 'bg-white rounded-2xl shadow-2xl max-w-md w-full p-6' },
        React.createElement('h3', { className: 'text-xl font-bold text-emerald-800 mb-2 text-center' }, 'Seleccionar Método de Pago'),
        React.createElement('div', { className: 'bg-emerald-50 rounded-xl p-4 mb-4' },
          React.createElement('div', { className: 'flex justify-between text-sm' },
            React.createElement('span', { className: 'text-gray-600' }, 'Subtotal:'),
            React.createElement('span', { className: 'font-medium' }, fMoneda(totalCarrito()))
          ),
          (descuentoPorcentaje || descuentoMonto) && React.createElement('div', { className: 'flex justify-between text-sm text-red-600' },
            React.createElement('span', null, 'Descuento:'),
            React.createElement('span', { className: 'font-medium' }, '-' + fMoneda(calcularDescuento()))
          ),
          React.createElement('div', { className: 'flex justify-between text-lg font-bold text-emerald-700 mt-2 pt-2 border-t border-emerald-200' },
            React.createElement('span', null, 'Total a Cobrar:'),
            React.createElement('span', null, fMoneda(totalConDescuento()))
          )
        ),
        React.createElement('div', { className: 'mb-4 space-y-3' },
          React.createElement('label', { className: 'block text-sm font-medium text-gray-700 mb-1' }, 'Descuento'),
          React.createElement('div', { className: 'grid grid-cols-2 gap-2' },
            React.createElement('div', null,
              React.createElement('div', { className: 'text-xs text-gray-500 mb-1' }, 'Porcentaje (%)'),
              React.createElement('input', {
                type: 'number',
                placeholder: '0',
                className: 'w-full p-2 border border-gray-200 rounded-lg text-sm',
                value: descuentoPorcentaje,
                onChange: (e) => { setDescuentoPorcentaje(e.target.value); if (e.target.value) setDescuentoMonto(''); }
              })
            ),
            React.createElement('div', null,
              React.createElement('div', { className: 'text-xs text-gray-500 mb-1' }, 'Monto ($)'),
              React.createElement('input', {
                type: 'number',
                placeholder: '0',
                className: 'w-full p-2 border border-gray-200 rounded-lg text-sm',
                value: descuentoMonto,
                onChange: (e) => { setDescuentoMonto(e.target.value); if (e.target.value) setDescuentoPorcentaje(''); }
              })
            )
          )
        ),
        React.createElement('div', { className: 'space-y-3' },
          React.createElement('div', { className: 'mb-3' },
            React.createElement('label', { className: 'block text-sm font-medium text-gray-700 mb-1' }, 'Monto Recibido (Efectivo)'),
            React.createElement('input', {
              type: 'number',
              placeholder: '0',
              className: 'w-full p-2 border border-gray-200 rounded-lg text-sm',
              value: montoRecibido,
              onChange: (e) => setMontoRecibido(e.target.value)
            }),
            montoRecibido && Number(montoRecibido) > 0 && React.createElement('div', { className: 'mt-2 p-2 bg-blue-50 rounded-lg text-sm' },
              React.createElement('div', { className: 'flex justify-between' },
                React.createElement('span', { className: 'text-gray-600' }, 'Cambio:'),
                React.createElement('span', { className: 'font-bold text-blue-700' }, fMoneda(Math.max(0, Number(montoRecibido) - totalConDescuento())))
              )
            )
          ),
          React.createElement('button', { onClick: procesarPagoEfectivo, className: 'w-full bg-gradient-to-r from-emerald-400 to-green-500 text-white py-3 rounded-xl font-bold text-lg hover:from-emerald-500 hover:to-green-600 shadow-md flex items-center justify-center gap-2' },
            React.createElement(Icon, { name: 'dollar-sign' }),
            'Efectivo'
          ),
          React.createElement('button', { onClick: procesarPagoTarjeta, className: 'w-full bg-gradient-to-r from-blue-400 to-blue-500 text-white py-3 rounded-xl font-bold text-lg hover:from-blue-500 hover:to-blue-600 shadow-md flex items-center justify-center gap-2' },
            React.createElement(Icon, { name: 'credit-card' }),
            'Tarjeta'
          ),
          React.createElement('div', { className: 'border-t border-gray-200 pt-3 mt-3' },
            React.createElement('label', { className: 'block text-sm text-gray-500 mb-1' }, 'Cliente para crédito (fiado):'),
            React.createElement('select', {
              className: 'w-full p-2 border border-gray-200 rounded-lg text-sm mb-2',
              value: clienteFiado ? String(clienteFiado.id) : '',
              onChange: (e) => {
                const id = Number(e.target.value);
                setClienteFiado(id ? clientes.find(c => c.id === id) : null);
              }
            },
              React.createElement('option', { value: '' }, 'Seleccionar cliente...'),
              clientes.filter(c => c.tipo !== 'Ocasional').map(c =>
                React.createElement('option', { key: c.id, value: c.id }, c.nombre + ' (disp. ' + fMoneda(c.creditoMaximo - c.saldoPendiente) + ')')
              )
            ),
            React.createElement('button', { onClick: procesarPagoFiado, disabled: !clienteFiado, className: 'w-full bg-gradient-to-r from-amber-400 to-orange-500 text-white py-3 rounded-xl font-bold text-lg hover:from-amber-500 hover:to-orange-600 shadow-md disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2' },
              React.createElement(Icon, { name: 'wallet' }),
              'Fiado / Crédito'
            )
          )
        ),
        React.createElement('button', { onClick: cerrarModalPago, className: 'w-full mt-3 bg-gray-100 text-gray-500 py-2 rounded-xl text-sm hover:bg-gray-200' }, 'Cancelar')
      )
    ),

    // ==================== MODAL: ARQUEO ====================
    modalArqueo.abierto && React.createElement('div', { className: 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4' },
      React.createElement('div', { className: 'bg-white rounded-2xl shadow-2xl max-w-md w-full p-6' },
        React.createElement('h3', { className: 'text-xl font-bold text-emerald-800 mb-4 text-center' }, 'Arqueo de Caja'),
        React.createElement('div', { className: 'space-y-4' },
          React.createElement('div', null,
            React.createElement('label', { className: 'block text-sm text-gray-500 mb-1' }, 'Monto Inicial en Caja'),
            React.createElement('input', { type: 'number', className: 'w-full p-3 border border-emerald-200 rounded-lg text-lg font-bold', placeholder: '0', value: montoInicialArqueo, onChange: (e) => setMontoInicialArqueo(e.target.value) })
          ),
          React.createElement('div', { className: 'bg-emerald-50 rounded-lg p-3 space-y-2 text-sm' },
            React.createElement('div', { className: 'flex justify-between' },
              React.createElement('span', null, 'Ventas de hoy:'),
              React.createElement('span', { className: 'font-bold' }, fMoneda(totalVentasHoy))
            ),
            React.createElement('div', { className: 'flex justify-between' },
              React.createElement('span', null, 'Gastos de hoy:'),
              React.createElement('span', { className: 'font-bold' }, fMoneda(gastos.filter(g => g.fecha === hoy()).reduce((s, g) => s + g.monto, 0)))
            ),
            React.createElement('div', { className: 'flex justify-between text-base border-t border-emerald-200 pt-2' },
              React.createElement('span', { className: 'font-bold' }, 'Total Esperado:'),
              React.createElement('span', { className: 'font-bold text-emerald-700' }, fMoneda((Number(montoInicialArqueo) || 0) + totalVentasHoy - gastos.filter(g => g.fecha === hoy()).reduce((s, g) => s + g.monto, 0)))
            )
          ),
          React.createElement('div', null,
            React.createElement('label', { className: 'block text-sm text-gray-500 mb-1' }, 'Observaciones'),
            React.createElement('textarea', { className: 'w-full p-2 border border-gray-200 rounded-lg text-sm', rows: 2, placeholder: 'Notas del arqueo...', value: arqueoObservaciones, onChange: (e) => setArqueoObservaciones(e.target.value) })
          )
        ),
        React.createElement('div', { className: 'flex gap-3 mt-4' },
          React.createElement('button', { onClick: realizarArqueo, className: 'flex-1 bg-gradient-to-r from-emerald-500 to-green-600 text-white py-2 rounded-xl font-bold hover:from-emerald-600 hover:to-green-700 shadow-md' }, 'Realizar Arqueo'),
          React.createElement('button', { onClick: cerrarModalArqueo, className: 'px-4 bg-gray-100 text-gray-500 py-2 rounded-xl hover:bg-gray-200' }, 'Cancelar')
        )
      )
    ),

    // ==================== MODAL: RECIBO ====================
    modalRecibo.abierto && modalRecibo.datos && React.createElement('div', { className: 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4' },
      React.createElement('div', { className: 'bg-white rounded-2xl shadow-2xl max-w-sm w-full p-6' },
        React.createElement('div', { className: 'text-center mb-4' },
          React.createElement(Icon, { name: 'sparkles', className: 'text-4xl text-emerald-500 mb-2' }),
          React.createElement('h3', { className: 'text-xl font-bold text-emerald-800' }, 'Venta Registrada'),
          React.createElement('p', { className: 'text-sm text-gray-400' }, 'Supermercado El Granjero')
        ),
        React.createElement('div', { className: 'border-t border-b border-gray-200 py-3 space-y-1 text-sm' },
          React.createElement('div', { className: 'flex justify-between' },
            React.createElement('span', { className: 'text-gray-500' }, 'Fecha:'),
            React.createElement('span', null, modalRecibo.datos.fecha)
          ),
          React.createElement('div', { className: 'flex justify-between' },
            React.createElement('span', { className: 'text-gray-500' }, 'Cliente:'),
            React.createElement('span', null, modalRecibo.datos.cliente)
          ),
          React.createElement('div', { className: 'flex justify-between' },
            React.createElement('span', { className: 'text-gray-500' }, 'Método:'),
            React.createElement('span', null, modalRecibo.datos.metodoPago)
          ),
          React.createElement('div', { className: 'border-t border-gray-200 pt-2 mt-2' },
            modalRecibo.datos.items.map((item, idx) =>
              React.createElement('div', { key: idx, className: 'flex justify-between text-xs' },
                React.createElement('span', null, item.cantidad + 'x ' + (productos.find(p => p.id === item.productoId)?.nombre || '')),
                React.createElement('span', null, fMoneda(item.cantidad * item.precioVenta))
              )
            )
          ),
          React.createElement('div', { className: 'border-t border-gray-200 pt-2 mt-2 space-y-1' },
            React.createElement('div', { className: 'flex justify-between' },
              React.createElement('span', { className: 'text-gray-500' }, 'Subtotal:'),
              React.createElement('span', null, fMoneda(modalRecibo.datos.items.reduce((s, i) => s + (i.cantidad * i.precioVenta), 0)))
            ),
            modalRecibo.datos.descuento > 0 && React.createElement('div', { className: 'flex justify-between text-red-600' },
              React.createElement('span', null, 'Descuento:'),
              React.createElement('span', null, '-' + fMoneda(modalRecibo.datos.descuento))
            ),
            modalRecibo.datos.montoRecibido > 0 && React.createElement('div', { className: 'flex justify-between' },
              React.createElement('span', { className: 'text-gray-500' }, 'Monto Recibido:'),
              React.createElement('span', null, fMoneda(modalRecibo.datos.montoRecibido))
            ),
            modalRecibo.datos.cambio > 0 && React.createElement('div', { className: 'flex justify-between text-blue-600' },
              React.createElement('span', null, 'Cambio:'),
              React.createElement('span', null, fMoneda(modalRecibo.datos.cambio))
            ),
            React.createElement('div', { className: 'flex justify-between font-bold text-lg border-t border-gray-200 pt-2 mt-2' },
              React.createElement('span', null, 'Total:'),
              React.createElement('span', { className: 'text-emerald-600' }, fMoneda(modalRecibo.datos.total))
            )
          )
        ),
        React.createElement('button', { onClick: cerrarRecibo, className: 'w-full mt-4 bg-emerald-500 text-white py-2 rounded-xl font-bold hover:bg-emerald-600' }, 'Cerrar')
      )
    ),

    // ==================== MODAL: NOTIFICACION ====================
    modalNotificacion.abierto && React.createElement('div', { className: 'fixed top-4 right-4 z-50 max-w-xs' },
      React.createElement('div', {
        className: 'p-4 rounded-xl shadow-2xl text-white text-sm font-medium ' +
          (modalNotificacion.tipo === 'exito' ? 'bg-gradient-to-r from-green-500 to-emerald-500' :
           modalNotificacion.tipo === 'error' ? 'bg-gradient-to-r from-red-500 to-pink-500' :
           'bg-gradient-to-r from-blue-500 to-indigo-500')
      },
        React.createElement('div', { className: 'flex items-center gap-2' },
          React.createElement('span', { className: 'text-lg' },
            modalNotificacion.tipo === 'exito' ? React.createElement(Icon, { name: 'check-circle' }) : modalNotificacion.tipo === 'error' ? React.createElement(Icon, { name: 'x-circle' }) : React.createElement(Icon, { name: 'info' })
          ),
          React.createElement('span', null, modalNotificacion.mensaje)
        )
      )
    ),

    // ==================== MODAL: DIALOGO ====================
    modalDialogo.abierto && React.createElement('div', { className: 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4' },
      React.createElement('div', { className: 'bg-white rounded-2xl shadow-2xl max-w-sm w-full p-6' },
        React.createElement('h3', { className: 'text-lg font-bold text-gray-800 mb-2' }, modalDialogo.titulo),
        React.createElement('p', { className: 'text-gray-500 mb-6' }, modalDialogo.mensaje),
        React.createElement('div', { className: 'flex gap-3' },
          React.createElement('button', { onClick: confirmarDialogo, className: 'flex-1 bg-red-500 text-white py-2 rounded-xl font-bold hover:bg-red-600' }, 'Sí, confirmar'),
          React.createElement('button', { onClick: cerrarDialogo, className: 'flex-1 bg-gray-100 text-gray-500 py-2 rounded-xl font-bold hover:bg-gray-200' }, 'Cancelar')
        )
      )
    )
  ));
}


// ==================== SUBCOMPONENTES ====================

function NavBtn({ tab, icon, label, activa, onClick }) {
  const isActive = activa === tab;
  return React.createElement('button', {
    onClick: () => onClick(tab),
    className: 'flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium transition-all ' +
      (isActive ? 'bg-emerald-600 text-white shadow-md' : 'text-gray-500 hover:bg-emerald-50 hover:text-emerald-600')
  },
    React.createElement(Icon, { name: icon }),
    React.createElement('span', null, label)
  );
}

function SummaryCard({ titulo, valor, color, icono }) {
  const colorMap = {
    emerald: 'from-emerald-500 to-green-500',
    blue: 'from-blue-500 to-indigo-500',
    red: 'from-red-500 to-pink-500',
    purple: 'from-purple-500 to-violet-500',
    amber: 'from-amber-500 to-orange-500',
    teal: 'from-teal-500 to-cyan-500',
    indigo: 'from-indigo-500 to-blue-500'
  };
  return React.createElement('div', { className: 'bg-white rounded-xl shadow-lg p-4 border border-emerald-100 hover:shadow-xl transition-shadow' },
    React.createElement('div', { className: 'flex items-center justify-between' },
      React.createElement('div', null,
        React.createElement('div', { className: 'text-sm text-gray-500' }, titulo),
        React.createElement('div', { className: 'text-2xl font-bold text-gray-800 mt-1' }, valor)
      ),
      React.createElement('div', { className: 'w-12 h-12 rounded-lg bg-gradient-to-br ' + (colorMap[color] || 'from-gray-500 to-gray-600') + ' flex items-center justify-center text-2xl text-white shadow-md' },
        React.createElement(Icon, { name: icono })
      )
    )
  );
}

// ==================== NOTA ====================
// El renderizado automatico se ha eliminado.
// La app React (App) se carga bajo demanda via PageLoader.load('app').
