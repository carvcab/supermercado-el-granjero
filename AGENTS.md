# AGENTS.md - Progress & Session Context

## Goal
- Complete the supermarket POS system (PC Electron + Flutter) fixing all reported issues: persistent JS errors, duplicate clients, purchases/abastecimiento stock+price updates, provider calendar, dashboard accuracy, inventory alerts, reports, and user management.

## Constraints & Preferences
- User runs PC from installed EXE (`app://local/`); Flutter app syncs via Firestore.
- Fiado payments must go to `caja_negocio` (balance + balance_al_cierre), not to `ganancias_acumuladas`.
- Scanner reads non‑standard codes (53‑digit garbage); user only cares about the functional behavior, not the scanner config.
- Prompt() is not supported in Electron 33; replaced with custom async modal dialog.
- IVA in purchases must be user‑defined, not auto‑forced to 19%.
- Provider calendar must show red dots for past visits and blue dots for scheduled visits.

## Completed Features

### Core Fixes
- Moved `init_distribuciones` script from template block to main page so it runs under `file://`.
- Fixed cierre date filter in `api-bridge.js` by using `(v.fecha||'').substring(0,10) === openDate`.
- Added `getConfigCajaNegocio()` helper that resets `config_caja_negocio` to a proper object if stored as `[]`.
- Added array‑safety check in `BridgeDB.init()` for `config_caja_negocio` loaded from `localStorage`.
- Modified `/distribuciones/balance` endpoint to recalculate balance from closed `cajas` records + fiado abonos − distributions.

### Fiado Payments (PC + Flutter)
- Fixed fiado abono handler: updates `balance` and `balance_al_cierre` (not `ganancias_acumuladas`).
- Updated both Flutter fiado functions (`_registrarAbono` and `_mostrarPagarFiado`).

### Error Handling
- Added global `window.onerror` handler saving full stack trace to `localStorage`.
- Added `unhandledrejection` handler for promise errors.
- Improved PageLoader script evaluation error logging.

### Update Mechanism
- Fixed stale update folder cleanup in `main.js`: clears `AppData/update/` when no valid `main.js` found.

### Client Management
- Fixed `cambiarTabDetalle` / `renderTabDetalle` / `cargarHistorial` / `cargarFiadosActivos` null safety for `selectedCliente`.
- Fixed duplicate client creation: searches API before creating new one (`GET /api/clientes?nombre=...`).

### Scanner
- Added barcode scanner support for `facturacion.html` via `procesarCodigoFac()`.

### Prompt Replacement
- Replaced all 5 `prompt()` calls with `await mostrarPrompt()` (custom async modal with resolve/reject).

### Purchases (Compras) & Abastecimiento
- Removed auto‑19% IVA; user enters any IVA value freely.
- After saving a compra, updates `stock_actual`, `precio_compra`, `precio_venta` via `PUT /api/productos/{id}`.
- Added `pagado` checkbox in abastecimiento modal to deduct from caja_negocio.
- Fixed abastecimiento NEW mode to update stock/prices; fixed EDIT mode API endpoint.
- Fixed provider autocomplete in compras form (dropdown + flag to prevent re-trigger).
- Fixed detail table in compras detail view (replaced `.table-container` with inline styles).

### Provider Calendar & Modal
- Calendar: red dots for past visits, blue dots for scheduled visits, `today` class on current day.
- `mostrarDetalleDia` shows visits + purchases for selected date.
- **Redesigned modal**: two-column layout (calendar left, visits/compras right), compact header with all contact info, edit button.

### Dashboard
- Added `ventas_dia_monto` to `_buildDashboardData()` so "Ventas Totales" shows money amount, not count.
- Verified all calculations: ventas_dia, ganancias_dia, stock_bajo, agotados, valor_inventario, deudaTotal, ventas_mes, top_productos, categorias, horas, meses.

### Inventory Alerts
- On login: checks products with `stock_actual <= stock_minimo` and shows toast.
- Dashboard: renders low-stock table (`.has-visit`, `.has-scheduled` dot markers).

### Reports
- 7 tabs: Ventas, Ganancias, Inventario, Fiados, Caja, Distribuciones, Ganancia Neta.
- Each tab has: KPI cards, table with data, Chart.js chart.
- Backend handlers in `api-bridge.js` `_handleReportes()`.

### Users & Permissions
- 3 sections: Usuarios, Roles, Acciones.
- Full CRUD: create/edit/delete users, manage roles, assign permissions.
- Firebase Auth integration for Flutter app login.
- Login system with localStorage session.

### Sidebar Layout
- Moved `#sidebarUserInfo` OUTSIDE `<nav class="sidebar-nav">` so the Salir button is always pinned at the bottom of the sidebar, never scrolled away when many nav items or a long username fills the space.
- Added `.sidebar.closed #sidebarUserInfo { display: none; }` so it hides when sidebar is collapsed.

### Bug Fix: Marca field in products
- Fixed `Number(_invMarcaId)` converting brand name strings like `"Coca-Cola"` to `NaN` → now stores as `_invMarcaId || null`.
- Fixed `inventario_editar` to iterate `_marcasData` as strings (not objects) and match against `p.marca`.
- Added **Marca column** to inventory table so brand is visible in the product list.
- Added blur handler to clear `_invMarcaId` when user types a brand not in autocomplete list.

### Performance: Debounce + Pagination
- Added debounce (200ms) to `Helpers.autocomplete()` shared helper.
- Added debounce to Inventario search, Facturacion search, and Bar client search (none had debounce).
- Added early termination (break after `maxResults` matches) in `Helpers.autocomplete()` — no more full-array scan per keystroke.
- Limited product search results to 30 in Compras and Compras Programadas (was unlimited).
- Limited Bar client `<select>` to 200 options with "... y X más" message.
- Created reusable `Helpers.Paginador` class with 100 items/page + page navigation controls.
- Added pagination to: Inventario, Clientes, Ventas (HV), Compras, Proveedores, Compras Programadas, Distribuciones.
- Added `.paginador-controls .pag-btn` CSS styles.

### Bug Fix: precio_compra missing from sale items
- Added `precio_compra` lookup when adding product to cart (`agregarAlCarrito`).
- Pass `precio_compra` in items payload when processing payment (`procesarPago`).
- Added `precio_compra` for bar product additions (`agregarProductoCuenta`).
- **Before fix**: dashboard and reports showed inflated profits (all margin = sale price).
- **After fix**: `_handleCrearVenta` falls back to product's `precio_compra` if not provided.

## Last Builds
- `dist_prod/Supermercado El Granjero Setup 3.6.3.exe` — built successfully (2026-07-06)
- `aplicacion android/build/app/outputs/flutter-apk/app-release.apk` (76.1 MB) — built successfully
- `dist_prod/Supermercado El Granjero Setup 3.7.0.exe` — built successfully (2026-07-06)
- v3.7.0 published to Firestore (auto-update) — 2026-07-06

## Key Decisions
- Use `balance_al_cierre` as primary source for distribuciones page, with recalculation fallback.
- Fiado payments are capital recovery, not new profit; never touch `ganancias_acumuladas`.
- Scanner uses default price (no prompt); user adjusts price/cantidad in cart.
- IVA in purchases is fully user‑defined.
- Provider calendar uses two dot colors (red = visit, blue = scheduled) matching Flutter.
- `ventasPorMes` chart includes ALL sales (including fiado) for a complete revenue picture, while KPI shows only non-fiado.

## Relevant Files
- **`index.html`**: Main HTML; pages, templates, inline JS (dashboard, proveedores, compras, facturacion, bar, calendar, scanner, login, users, reports).
- **`js/api-bridge.js`**: Offline‑first BridgeDB, REST API handlers, dashboard/report calculations.
- **`main.js`**: Electron main process, file serving, update mechanism.
- **`preload.js`**: Electron preload exposing `electronAPI`.
- **`css/style.css`**: Calendar dots, modal styles, general UI.
- **`package.json`**: Electron-builder config.

## Next Steps / Future Work
- (none currently — all items complete)
