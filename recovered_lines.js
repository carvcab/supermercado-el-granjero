440: margin-bottom: 1.5rem;
441: }
442: @media (max-width: 768px) {
443: .charts-grid {
444: grid-template-columns: 1fr;
445: }
446: }
447: </style>
448: 
449: <script>
450: console.log('dashboard script loaded');
451: function init_dashboard() {
452: console.log('init_dashboard called');
453: cargarDashboard();
454: }
455: 
456: async function cargarDashboard() {
457: try {
458: console.log('cargarDashboard: fetching data...');
459: var data = await API.get('/dashboard');
460: console.log('Dashboard data:', JSON.stringify(data));
461: if (!data) { console.warn('Dashboard: sin datos'); return; }
462: document.getElementById('kpiVentasDia').textContent = data.ventas_dia || 0;
463: document.getElementById('kpiGananciasDia').textContent = Helpers.formatMoney(data.ganancias_dia || 0);
464: document.getElementById('kpiProductosStock').textContent = data.productos_stock || 0;
465: document.getElementById('kpiValorInventario').textContent = Helpers.formatMoney(data.valor_inventario || 0);
466: document.getElementById('kpiStockBajo').textContent = data.stock_bajo || 0;
467: document.getElementById('kpiAgotados').textContent = data.productos_agotados || 0;
468: document.getElementById('kpiClientesDeuda').textContent = data.clientes_deuda || 0;
469: document.getElementById('kpiCuentasBar').textContent = data.cuentas_bar || 0;
470: document.getElementById('kpiVentasMes').textContent = Helpers.formatMoney(data.ventas_mes || 0);
471: 
472: var barFills = document.querySelectorAll('.kpi-bar-fill');
473: var vals = [data.ventas_dia, data.ganancias_dia, data.productos_stock, data.valor_inventario, data.stock_bajo, data.productos_agotados, data.clientes_deuda, data.cuentas_bar, data.ventas_mes];
474: var maxVal = 1;
475: for (var vi = 0; vi < vals.length; vi++) { if (vals[vi] > maxVal) maxVal = vals[vi]; }
476: for (var bfi = 0; bfi < barFills.length; bfi++) {
477: barFills[bfi].style.width = ((vals[bfi] || 0) / maxVal * 100) + '%';
478: }
479: 
480: renderVentasHora(data.ventas_por_hora);
481: renderVentasMes(data.ventas_por_mes);
482: window._dashboardTopData = data.top_productos;
483: window._dashboardCategoriasData = data.ventas_por_categoria;
484: renderTopProductos(data.top_productos);
485: renderCategorias(data.ventas_por_categoria);
486: renderLowStock(data.stock_bajo);
487: } catch (e) {
488: console.error('Error dashboard:', e);
489: Helpers.mostrarToast('Error al cargar dashboard: ' + e.message, 'error');
490: }
491: }
492: 
493: // Chart.js Chart Instances Tracker
494: if (!window.myCharts) { window.myCharts = {}; }
495: 
496: function renderVentasHora(data) {
497: var ctx = document.getElementById('chartCanvasVentasHora');
498: if (!ctx) return;
499: if (window.myCharts.ventasHora) { window.myCharts.ventasHora.destroy(); }
500: 
501: var labels = [];
502: var dataset = [];
503: if (data && data.length) {
504: for (var vi = 0; vi < data.length; vi++) {
505: var h = String(data[vi].hora);
506: if (h.length < 2) h = '0' + h;
507: labels.push(h + ':00');
508: dataset.push(data[vi].total);
509: }
510: }
511: 
512: if (!data || !data.length) {
513: labels = ['Sin datos'];
514: dataset = [0];
515: }
516: 
517: var grad = ctx.getContext('2d').createLinearGradient(0, 0, 0, 300);
518: grad.addColorStop(0, '#073155');
519: grad.addColorStop(1, '#1a7a2e');
520: 
521: window.myCharts.ventasHora = new Chart(ctx, {
522: type: 'bar',
523: data: {
524: labels: labels,
525: datasets: [{
526: label: 'Ventas por Hora ($)',
527: data: dataset,
528: backgroundColor: grad,
529: borderColor: '#031627',
530: borderWidth: 0,
531: borderRadius: 8,
532: barPercentage: 0.7
533: }]
534: },
535: options: {
536: responsive: true,
537: maintainAspectRatio: false,
538: plugins: {
539: legend: { display: false },
540: tooltip: {
541: backgroundColor: '#073155',
542: titleColor: '#fff',
543: bodyColor: '#fff',
544: cornerRadius: 8,
545: padding: 10,
546: callbacks: { label: function(context) { return ' ' + Helpers.formatMoney(context.raw); } }
547: }
548: },
549: scales: {
550: y: { beginAtZero: true, grid: { color: '#e0e0e0', drawBorder: false }, ticks: { callback: function(value) { return '$' + value; }, color: '#616161' } },
551: x: { grid: { display: false }, ticks: { color: '#616161' } }
552: }
553: }
554: });
555: }
556: 
557: function renderVentasMes(data) {
558: var ctx = document.getElementById('chartCanvasVentasMes');
559: if (!ctx) return;
560: if (window.myCharts.ventasMes) { window.myCharts.ventasMes.destroy(); }
561: 
562: var meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
563: var labels = [];
564: var dataset = [];
565: if (data && data.length) {
566: for (var vi = 0; vi < data.length; vi++) {
567: labels.push(meses[(data[vi].mes || 1) - 1]);
568: dataset.push(data[vi].total);
569: }
570: }
571: 
572: if (!data || !data.length) {
573: labels = ['Sin datos'];
574: dataset = [0];
575: }
576: 
577: var colors = ['#073155', '#1a7a2e', '#e65100', '#f9a825', '#c62828', '#00796b'];
578: 
579: window.myCharts.ventasMes = new Chart(ctx, {
580: type: 'bar',
581: data: {
582: labels: labels,
583: datasets: [{
584: label: 'Ventas por Mes ($)',
585: data: dataset,
586: backgroundColor: colors,
587: borderWidth: 0,
588: borderRadius: 6,
589: barPercentage: 0.65
590: }]
591: },
592: options: {
593: responsive: true,
594: maintainAspectRatio: false,
595: plugins: {
596: legend: { display: false },
597: tooltip: {
598: backgroundColor: '#1a7a2e',
599: titleColor: '#fff',
600: bodyColor: '#fff',
601: cornerRadius: 8,
602: padding: 10,
603: callbacks: { label: function(context) { return ' ' + Helpers.formatMoney(context.raw); } }
604: }
605: },
606: scales: {
607: y: { beginAtZero: true, grid: { color: '#e0e0e0', drawBorder: false }, ticks: { callback: function(value) { return '$' + value; }, color: '#616161' } },
608: x: { grid: { display: false }, ticks: { color: '#616161' } }
609: }
610: }
611: });
612: }
613: 
614: function renderTopProductos(data) {
615: var ctx = document.getElementById('chartCanvasTopProductos');
616: if (!ctx) return;
617: if (window.myCharts.topProductos) { window.myCharts.topProductos.destroy(); }
618: 
619: var labels = [];
620: var dataset = [];
621: if (data && data.length) {
622: for (var vi = 0; vi < data.length; vi++) {
623: labels.push(data[vi].producto || '');
624: var val = data[vi].cantidad != null ? data[vi].cantidad : (data[vi].total != null ? data[vi].total : 0);
625: dataset.push(val);
626: }
627: }
628: 
629: if (!data || !data.length) {
630: labels = ['Sin datos'];
631: dataset = [0];
632: }
633: 
634: var typeSelect = document.getElementById('chartTypeTop');
635: var chartType = typeSelect ? typeSelect.value : 'bar';
636: 
637: var chartColors = ['#073155', '#1a7a2e', '#e65100', '#f9a825', '#c62828', '#00796b', '#1565c0', '#6a1b9a', '#2e7d32', '#e65100'];
638: 
639: if (chartType === 'bar') {
640: window.myCharts.topProductos = new Chart(ctx, {
641: type: 'bar',
642: data: {
643: labels: labels,
644: datasets: [{
645: label: 'Cantidad vendida',
646: data: dataset,
647: backgroundColor: '#e65100',
648: borderWidth: 0,
649: borderRadius: 8,
650: barPercentage: 0.6
651: }]
652: },
653: options: {
654: indexAxis: 'y',
655: responsive: true,
656: maintainAspectRatio: false,
657: plugins: {
658: legend: { display: false },
659: tooltip: { backgroundColor: '#e65100', titleColor: '#fff', bodyColor: '#fff', cornerRadius: 8, padding: 10 }
660: },
661: scales: {
662: x: { beginAtZero: true, grid: { color: '#e0e0e0', drawBorder: false }, ticks: { color: '#616161' } },
663: y: { grid: { display: false }, ticks: { color: '#616161' } }
664: }
665: }
666: });
667: } else {
668: window.myCharts.topProductos = new Chart(ctx, {
669: type: chartType,
670: data: {
671: labels: labels,
672: datasets: [{
673: data: dataset,
674: backgroundColor: chartColors,
675: borderWidth: 3,
676: borderColor: '#ffffff',
677: hoverOffset: 8
678: }]
679: },
680: options: {
681: responsive: true,
682: maintainAspectRatio: false,
683: cutout: chartType === 'doughnut' ? '45%' : 0,
684: plugins: {
685: legend: { position: 'bottom', labels: { boxWidth: 14, padding: 10, font: { size: 11, weight: 'bold' }, color: '#424242' } },
686: tooltip: { backgroundColor: '#424242', titleColor: '#fff', bodyColor: '#fff', cornerRadius: 8, padding: 10 }
687: }
688: }
689: });
690: }
691: }
692: 
693: function renderCategorias(data) {
694: var ctx = document.getElementById('chartCanvasCategorias');
695: if (!ctx) return;
696: if (window.myCharts.categorias) { window.myCharts.categorias.destroy(); }
697: 
698: var labels = [];
699: var dataset = [];
700: if (data && data.length) {
701: for (var vi = 0; vi < data.length; vi++) {
702: labels.push(data[vi].categoria);
703: dataset.push(data[vi].total || 0);
704: }
705: }
706: 
707: if (!data || !data.length) {
708: labels = ['Sin datos'];
709: dataset = [0];
710: }
711: 
712: var typeSelect = document.getElementById('chartTypeCategorias');
713: var chartType = typeSelect ? typeSelect.value : 'doughnut';
714: 
715: var chartColors = ['#073155', '#1a7a2e', '#e65100', '#f9a825', '#c62828', '#00796b', '#1565c0', '#6a1b9a'];
716: 
717: if (chartType === 'bar') {
718: window.myCharts.categorias = new Chart(ctx, {
719: type: 'bar',
720: data: {
721: labels: labels,
722: datasets: [{
723: label: 'Ventas ($)',
724: data: dataset,
725: backgroundColor: '#073155',
726: borderWidth: 0,
727: borderRadius: 8,
728: barPercentage: 0.6
729: }]
730: },
731: options: {
732: indexAxis: 'y',
733: responsive: true,
734: maintainAspectRatio: false,
735: plugins: {
736: legend: { display: false },
737: tooltip: { backgroundColor: '#073155', titleColor: '#fff', bodyColor: '#fff', cornerRadius: 8, padding: 10 }
738: },
739: scales: {
740: x: { beginAtZero: true, grid: { color: '#e0e0e0', drawBorder: false }, ticks: { color: '#616161' } },
741: y: { grid: { display: false }, ticks: { color: '#616161' } }
742: }
743: }
744: });
745: } else {
746: window.myCharts.categorias = new Chart(ctx, {
747: type: chartType,
748: data: {
749: labels: labels,
750: datasets: [{
