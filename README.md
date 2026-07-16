# Supermercado El Granjero - Sistema de Gestion

ERP/POS para supermercado. Gestiona ventas, compras, inventario, clientes, proveedores,
fiados, caja, distribuciones y mas.

## Estructura del Proyecto

```
/
├── index.html              # Punto de entrada principal (SPA)
│                           # Contiene todas las plantillas HTML de las pantallas
│
├── css/
│   └── style.css           # Estilos generales del sistema
│
├── js/
│   └── api-bridge.js       # API Bridge - conexion con localStorage y Firestore
│                           # Contiene toda la logica de datos (CRUD)
│
├── assets/
│   └── logo.png            # Logo del supermercado
│
├── libs/                   # Librerias externas (vendor)
│   ├── tailwind.css        # Utilidades CSS tipo Tailwind
│   ├── react.min.js        # React (CDN fallback)
│   └── react-dom.min.js    # ReactDOM (CDN fallback)
│
├── paginas/                # Paginas individuales (redirigen a index.html)
│   ├── dashboard.html      # → Inicio / Dashboard
│   ├── caja.html           # → Caja registradora
│   ├── productos.html      # → Productos / Inventario
│   ├── clientes.html       # → Gestion de clientes
│   ├── proveedores.html    # → Gestion de proveedores
│   ├── ventas_super.html   # → Ventas supermercado
│   ├── ventas_bar.html     # → Ventas bar
│   ├── fiados.html         # → Creditos / Fiados
│   ├── historial_ventas.html # → Historial de ventas
│   ├── compras.html        # → Compras
│   ├── compras_programadas.html # → Compras programadas
│   ├── categorias.html     # → Categorias
│   ├── reportes.html       # → Reportes y graficos
│   ├── cierres.html        # → Cierre de caja
│   ├── distribuciones.html # → Distribuciones / Caja Negocio
│   ├── configuracion.html  # → Configuracion del sistema
│   └── usuarios.html       # → Usuarios y roles
│
├── app.js                  # App React (en desuso, los templates se cargan desde index.html)
│
├── firebase.json           # Configuracion Firebase Hosting
├── firestore.rules         # Reglas de seguridad Firestore
├── package.json            # Scripts de deploy
├── .firebaserc             # Proyecto Firebase asociado
└── .venv/                  # Entorno virtual Python (para utilidades)
```

## Como usar

1. Abre `index.html` en el navegador
2. Inicia sesion con un usuario
3. Navega por el menu lateral

### Usuario por defecto
- **Usuario:** nelson
- **Contrasena:** nelsonrodri
- **Rol:** Jefe (acceso completo)

## Tecnologias

- **Frontend:** HTML + CSS + JavaScript (vanilla, sin frameworks)
- **Base de datos:** localStorage (navegador) + Firebase Firestore (nube)
- **Graficos:** Chart.js
- **Iconos:** Font Awesome 6
- **Firebase Project:** supermercado-el-campesino
