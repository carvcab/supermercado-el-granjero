// ============================================================
// API BRIDGE - Supermercado El Granjero POS
// localStorage + Firestore sync bridge
// ============================================================

var CATEGORY_ICONS = {
  "Lacteos":"fa-glass-whiskey","Lácteos":"fa-glass-whiskey",
  "Huevos":"fa-egg","Despensa":"fa-box",
  "Enlatados":"fa-boxes","Bebidas":"fa-wine-bottle",
  "Panadería":"fa-bread-slice","Panaderia":"fa-bread-slice",
  "Frutas y Verduras":"fa-apple-alt","Carnes":"fa-drumstick-bite",
  "Aseo":"fa-pump-soap","Mercado":"fa-shopping-basket",
  "Preparados":"fa-blender","General":"fa-tag",
  "Bebidas Alcoholicas":"fa-beer","Bebidas Alcohólicas":"fa-beer",
  "Congelados":"fa-snowflake","Granos":"fa-seedling",
  "Snacks":"fa-cookie","Dulces":"fa-candy-cane",
  "Mascotas":"fa-paw","Limpieza":"fa-broom",
  "Otros":"fa-ellipsis-h"
};

window.Helpers = {
  formatMoney: function(v){ return '$' + Number(v||0).toLocaleString('es-CO',{minimumFractionDigits:0,maximumFractionDigits:0}); },
  formatDate: function(d){
    if(!d)return'-';
    var s = (typeof d==='string'?d:(d.toISOString?d.toISOString():String(d))).substring(0,10);
    var p = s.split('-');
    if(p.length===3) return p[2]+'/'+p[1]+'/'+p[0];
    return s;
  },
  formatDateTime: function(d){
    if(!d)return'-';
    var s = typeof d==='string'?d:(d.toISOString?d.toISOString():String(d));
    var dt = s.substring(0,10), tm = s.substring(11,16);
    var p = dt.split('-');
    if(p.length===3) return p[2]+'/'+p[1]+'/'+p[0]+' '+tm;
    return s;
  },
  escapeHtml: function(s){ if(!s)return''; return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#039;'); },
  today: function(){ return new Date().toISOString().substring(0,10); },
  thisMonth: function(){ var d=new Date(); return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0'); },
  mostrarToast: function(msg,type){
    var e = document.getElementById('toast');
    var colors={success:'#1a7a2e',error:'#c62828',warning:'#e65100',info:'#073155'};
    var bg=colors[type]||colors.info;
    if(!e){
      e = document.createElement('div');
      e.id='toast';
      e.style.cssText='position:fixed;bottom:1.5rem;right:1.5rem;z-index:99999;padding:0.75rem 1.4rem;border-radius:0.5rem;color:#ffffff;font-weight:700;font-size:0.9rem;box-shadow:0 4px 12px rgba(0,0,0,0.2);transition:opacity 0.3s;max-width:500px;word-break:break-word;background:'+bg+';';
      document.body.appendChild(e);
    }
    e.style.opacity='0';
    e.style.background=bg;
    setTimeout(function(){
      e.textContent=msg;
      e.style.opacity='1';
      clearTimeout(e._timeout);
      e._timeout=setTimeout(function(){e.style.opacity='0';},3500);
    },50);
  },
  confirmar: function(msg,title){
    return new Promise(function(resolve){
      var ov = document.createElement('div');
      ov.className='modal-overlay';
      ov.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:9999;display:flex;align-items:flex-start;justify-content:center;padding:3rem 1rem;overflow-y:auto;';
      ov.innerHTML = '<div style="background:#fff;border-radius:0.75rem;padding:1.5rem;max-width:420px;width:90%;box-shadow:0 8px 24px rgba(0,0,0,0.2);">'+
        '<h3 style="margin:0 0 0.75rem;font-weight:700;color:#1a1a1a;">'+(title||'Confirmar')+'</h3>'+
        '<p style="margin:0 0 1.25rem;color:#616161;">'+msg+'</p>'+
        '<div style="display:flex;gap:0.5rem;justify-content:flex-end;">'+
        '<button class="btn-cancel-confirm" style="background:#95a5a6;color:#fff;border:none;padding:0.5rem 1rem;border-radius:0.4rem;cursor:pointer;font-weight:600;">Cancelar</button>'+
        '<button class="btn-ok-confirm" style="background:#1a7a2e;color:#fff;border:none;padding:0.5rem 1rem;border-radius:0.4rem;cursor:pointer;font-weight:600;">Aceptar</button>'+
        '</div></div>';
      document.body.appendChild(ov);
      ov.querySelector('.btn-cancel-confirm').onclick=function(){ov.remove();resolve(false);};
      ov.querySelector('.btn-ok-confirm').onclick=function(){ov.remove();resolve(true);};
      ov.onclick=function(e){if(e.target===ov){ov.remove();resolve(false);}};
    });
  },
  mostrarModal: function(title,content,opts){
    opts=opts||{};
    var size=opts.size||'md';
    var maxW=size==='modal-lg'?'700px':size==='modal-xl'?'900px':'500px';
    var ov = document.createElement('div');
    ov.className='modal-overlay';
    ov.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:9999;display:flex;align-items:flex-start;justify-content:center;padding:3rem 1rem;overflow-y:auto;';
    ov.innerHTML = '<div style="background:#fff;border-radius:0.75rem;max-width:'+maxW+';width:100%;max-height:85vh;overflow-y:auto;box-shadow:0 8px 24px rgba(0,0,0,0.2);">'+
      '<div class="modal-header" style="display:flex;align-items:center;justify-content:space-between;padding:1rem 1.25rem;border-bottom:1px solid #e5e7eb;">'+
      '<h3 style="margin:0;font-weight:700;font-size:1rem;color:#1a1a1a;">'+title+'</h3>'+
      '<button style="background:none;border:none;font-size:1.2rem;cursor:pointer;color:#6b7280;padding:0;" onclick="this.closest(\'.modal-overlay\').remove()">&times;</button>'+
      '</div>'+
      '<div style="padding:1rem 1.25rem;">'+content+'</div>'+
      (opts.footer?'<div style="padding:1rem 1.25rem;border-top:1px solid #e5e7eb;display:flex;justify-content:flex-end;gap:0.5rem;">'+opts.footer+'</div>':'')+
      '</div>';
    document.body.appendChild(ov);
    ov.onclick=function(e){if(e.target===ov)ov.remove();};
  },
  descargarJSON: function(data,filename){
    var blob=new Blob([JSON.stringify(data,null,2)],{type:'application/json'});
    var url=URL.createObjectURL(blob);
    var a=document.createElement('a');a.href=url;a.download=filename;a.click();
    URL.revokeObjectURL(url);
  },
  descargarCSV: function(data,filename){
    if(!data||!data.length)return;
    var keys=Object.keys(data[0]),csv=keys.join(',')+'\n';
    for(var i=0;i<data.length;i++){
      var row=keys.map(function(k){var v=data[i][k];if(v==null)return'';v=String(v);return v.indexOf(',')>-1||v.indexOf('"')>-1?'"'+v.replace(/"/g,'""')+'"':v;});
      csv+=row.join(',')+'\n';
    }
    var blob=new Blob([csv],{type:'text/csv;charset=utf-8;'});
    var url=URL.createObjectURL(blob);
    var a=document.createElement('a');a.href=url;a.download=filename;a.click();
    URL.revokeObjectURL(url);
  },
  icon: function(name){
    var map={check:'fa-check-circle',edit:'fa-edit','edit-2':'fa-pencil-alt',trash:'fa-trash','trash-2':'fa-trash',package:'fa-box',plus:'fa-plus',search:'fa-search',save:'fa-save',user:'fa-user',clock:'fa-clock',chart:'fa-chart-bar',inventory:'fa-boxes',money:'fa-dollar-sign',download:'fa-download',upload:'fa-upload',sync:'fa-sync-alt',print:'fa-print',lock:'fa-lock',unlock:'fa-unlock',key:'fa-key',cog:'fa-cog',bell:'fa-bell',times:'fa-times',arrowLeft:'fa-arrow-left',arrowRight:'fa-arrow-right',external:'fa-external-link-alt'};
    var cls = map[name]||'fa-'+name;
    return '<i class="fas ' + cls + '"></i>';
  },
  getCategoryIcon: function(nombre){
    return CATEGORY_ICONS[nombre]||'fa-tag';
  },
  autocomplete: function(input,source,opts){
    opts=opts||{};
    var displayKey=opts.displayKey||'nombre';
    var valueKey=opts.valueKey||'id';
    var maxResults=opts.maxResults||8;
    var container=document.createElement('div');
    container.className='autocomplete-dropdown';
    container.style.cssText='position:absolute;top:100%;left:0;right:0;background:#fff;border:2px solid #073155;border-top:none;border-radius:0 0 0.5rem 0.5rem;max-height:200px;overflow-y:auto;z-index:1000;display:none;box-shadow:0 4px 12px rgba(0,0,0,0.1);';
    input.parentNode.style.position='relative';
    input.parentNode.appendChild(container);
    input.setAttribute('autocomplete','off');
    var acTimeout=null;
    input.addEventListener('input',function(){
      clearTimeout(acTimeout);
      var q=input.value.toLowerCase().trim();
      acTimeout=setTimeout(function(){
        if(!q){container.style.display='none';return;}
        var filtered=[];
        for(var i=0;i<source.length;i++){
          if((source[i][displayKey]||'').toLowerCase().indexOf(q)!==-1){
            filtered.push(source[i]);
            if(filtered.length>=maxResults) break;
          }
        }
        if(!filtered.length){container.style.display='none';return;}
        container.innerHTML=filtered.map(function(x){
          var name=x[displayKey]||'', extra=opts.extraKey?(x[opts.extraKey]||''):'';
          return '<div class="autocomplete-item" style="padding:0.4rem 0.6rem;cursor:pointer;font-size:0.8rem;border-bottom:1px solid #f0f0f0;" data-id="'+x[valueKey]+'" data-name="'+Helpers.escapeHtml(name)+'">'+Helpers.escapeHtml(name)+(extra?' <small style="color:#6b7280;">'+Helpers.escapeHtml(extra)+'</small>':'')+'</div>';
        }).join('');
        container.style.display='block';
        container.querySelectorAll('.autocomplete-item').forEach(function(el){
          el.addEventListener('click',function(){
            var item={id:el.dataset.id,nombre:el.dataset.name};
            if(opts.onSelect)opts.onSelect(item);
            input.value=el.dataset.name;
            container.style.display='none';
          });
        });
      },200);
    });
    input.addEventListener('blur',function(){setTimeout(function(){container.style.display='none';},200);});
    input.addEventListener('focus',function(){if(input.value.trim())input.dispatchEvent(new Event('input'));});
  },
  _paginadores: {},
  Paginador: function(tbodyId, opts){
    opts=opts||{};
    this.tbodyId=tbodyId;
    this.pageSize=opts.pageSize||100;
    this.colspan=opts.colspan||1;
    this.emptyHtml=opts.emptyHtml||'<tr><td colspan="'+this.colspan+'" style="text-align:center;padding:2rem;color:var(--gray-400);">No hay datos</td></tr>';
    this.currentPage=1;
    this.data=[];
    this.renderRow=null;
    this.onPageRender=opts.onPageRender||null;
    this.controlsId=(tbodyId||'')+'-pag';
    Helpers._paginadores[tbodyId]=this;
  }
};

Helpers.Paginador.prototype.update = function(data, renderRow){
  this.data=data||[];
  this.renderRow=renderRow;
  this.currentPage=1;
  this._render();
};

Helpers.Paginador.prototype.goToPage = function(page){
  this.currentPage=page;
  this._render();
};

Helpers.Paginador.prototype._render = function(){
  var totalPages=Math.ceil(this.data.length/this.pageSize)||1;
  if(this.currentPage<1) this.currentPage=1;
  if(this.currentPage>totalPages) this.currentPage=totalPages;
  var start=(this.currentPage-1)*this.pageSize;
  var pageData=this.data.slice(start, start+this.pageSize);
  var tbody=document.getElementById(this.tbodyId);
  if(!tbody) return;
  if(!pageData.length){ tbody.innerHTML=this.emptyHtml; this._renderControls(totalPages); return; }
  var html='';
  for(var i=0;i<pageData.length;i++) html+=this.renderRow(pageData[i], start+i);
  tbody.innerHTML=html;
  if(this.onPageRender) this.onPageRender();
  this._renderControls(totalPages);
};

Helpers.Paginador.prototype._renderControls = function(totalPages){
  var c=document.getElementById(this.controlsId);
  if(!c){
    c=document.createElement('div');
    c.id=this.controlsId;
    c.className='paginador-controls';
    c.style.cssText='display:flex;align-items:center;justify-content:center;gap:0.25rem;padding:0.75rem 0;flex-wrap:wrap;';
    var tbody=document.getElementById(this.tbodyId);
    if(tbody&&tbody.parentNode) tbody.parentNode.appendChild(c);
  }
  if(totalPages<=1){ c.style.display='none'; return; }
  c.style.display='flex';
  var self=this;
  var html='<button class="btn btn-sm pag-btn" onclick="Helpers._paginadores[\''+this.tbodyId+'\'].goToPage('+(this.currentPage-1)+')" '+(this.currentPage<=1?'disabled':'')+' style="padding:0.2rem 0.6rem;font-size:0.75rem;">« Anterior</button>';
  var maxVis=5, half=Math.floor(maxVis/2);
  var sp=Math.max(1, this.currentPage-half);
  var ep=Math.min(totalPages, sp+maxVis-1);
  if(ep-sp<maxVis-1) sp=Math.max(1, ep-maxVis+1);
  if(sp>1) html+='<span style="color:var(--gray-400);font-size:0.75rem;padding:0 0.2rem;">...</span>';
  for(var p=sp;p<=ep;p++){
    html+='<button class="btn btn-sm pag-btn" onclick="Helpers._paginadores[\''+this.tbodyId+'\'].goToPage('+p+')" style="padding:0.2rem 0.6rem;font-size:0.75rem;'+(p===this.currentPage?'font-weight:700;background:var(--primary);color:#fff;border-color:var(--primary);':'')+'">'+p+'</button>';
  }
  if(ep<totalPages) html+='<span style="color:var(--gray-400);font-size:0.75rem;padding:0 0.2rem;">...</span>';
  html+='<button class="btn btn-sm pag-btn" onclick="Helpers._paginadores[\''+this.tbodyId+'\'].goToPage('+(this.currentPage+1)+')" '+(this.currentPage>=totalPages?'disabled':'')+' style="padding:0.2rem 0.6rem;font-size:0.75rem;">Siguiente »</button>';
  html+='<span style="font-size:0.7rem;color:var(--gray-400);margin-left:0.5rem;">Pág '+this.currentPage+' de '+totalPages+' ('+this.data.length+' registros)</span>';
  c.innerHTML=html;
};

var FIRESTORE_SYNC_COLS = ['categorias','productos','clientes','proveedores','ventas','cajas','movimientos_caja','fiados','fiado_abonos','user_actions','compras','compras_programadas','autoconsumos','visitas_proveedor','distribuciones','distribuciones_categorias','ventas_bar_cuentas','ventas_bar_categorias','ventas_bar_productos','cotizaciones','permisos','roles','usuarios','deletions'];

var BridgeDB = {
  _data: {},
  _defaults: {
    categorias:[],productos:[],clientes:[],proveedores:[],
    ventas:[],cajas:[],movimientos_caja:[],fiados:[],fiado_abonos:[],
    user_actions:[],compras:[],compras_programadas:[],autoconsumos:[],
    visitas_proveedor:[],distribuciones:[],distribuciones_categorias:[],
    ventas_bar_cuentas:[],ventas_bar_categorias:[],ventas_bar_productos:[],
    cotizaciones:[],permisos:[],roles:[],usuarios:[],deletions:[],
    config_caja_negocio:{balance:0,ganancias_acumuladas:0,balance_al_cierre:0}
  },
  init: function(){
    var self=this;
    // Load from localStorage FIRST (always works, offline-safe)
    var saved=localStorage.getItem('bridge_data');
    if(saved){
      try{
        var parsed=JSON.parse(saved);
        this._data={};
        for(var k in this._defaults){
          this._data[k]=parsed[k]||JSON.parse(JSON.stringify(this._defaults[k]));
        }
        this._data.config_caja_negocio=parsed.config_caja_negocio||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
        if(Array.isArray(this._data.config_caja_negocio))this._data.config_caja_negocio={balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
        this._configStr = JSON.stringify(this._data.config_caja_negocio);
        this._seedIfEmpty();
        this._save();
      }catch(e){this._initEmpty();}
    }else{
      this._initEmpty();
    }
    // Try Firestore AFTER login (called from ocultarLogin when user is authenticated)
  },
  _initEmpty: function(){
    this._data={};
    for(var k in this._defaults){
      this._data[k]=JSON.parse(JSON.stringify(this._defaults[k]));
    }
    this._data.config_caja_negocio={balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
    this._configStr = JSON.stringify(this._data.config_caja_negocio);
    this._seedIfEmpty();
    this._save();
  },
  _mergeLists: function(colName, localList, remoteList) {
    localList = localList || [];
    remoteList = remoteList || [];
    var merged = [];
    var remoteMap = {};
    for (var i = 0; i < remoteList.length; i++) {
      var item = remoteList[i];
      if (item && item.id != null) {
        remoteMap[String(item.id)] = item;
      }
    }
    
    // Map of deletion timestamps for this collection
    var deletions = this._data.deletions || [];
    var deletionMap = {};
    for (var i = 0; i < deletions.length; i++) {
      var d = deletions[i];
      if (d && d.col === colName && d.target_id != null) {
        deletionMap[String(d.target_id)] = new Date(d.deleted_at || 0).getTime();
      }
    }

    var hasLocalChanges = false;
    var remoteIdsProcessed = {};
    for (var i = 0; i < localList.length; i++) {
      var localItem = localList[i];
      if (!localItem || localItem.id == null) continue;
      var idStr = String(localItem.id);
      
      // If deleted, check if update is newer than deletion
      if (deletionMap[idStr] !== undefined) {
        var localTime = new Date(localItem.updated_at || localItem.created_at || 0).getTime();
        if (deletionMap[idStr] >= localTime) {
          // This local item was deleted, skip it!
          continue;
        }
      }

      var remoteItem = remoteMap[idStr];
      if (!remoteItem) {
        // Local only (created offline)
        merged.push(localItem);
        hasLocalChanges = true;
      } else {
        // Exists in both. Compare timestamps.
        var localTime = new Date(localItem.updated_at || localItem.created_at || 0).getTime();
        var remoteTime = new Date(remoteItem.updated_at || remoteItem.created_at || 0).getTime();
        if (localTime > remoteTime) {
          // Local is newer (edited offline)
          merged.push(localItem);
          hasLocalChanges = true;
        } else {
          // Remote is newer or equal
          merged.push(remoteItem);
        }
        remoteIdsProcessed[idStr] = true;
      }
    }
    // Add remaining remote items
    for (var i = 0; i < remoteList.length; i++) {
      var remoteItem = remoteList[i];
      if (remoteItem && remoteItem.id != null) {
        var idStr = String(remoteItem.id);
        if (!remoteIdsProcessed[idStr]) {
          // Check if deleted locally
          if (deletionMap[idStr] !== undefined) {
            var remoteTime = new Date(remoteItem.updated_at || remoteItem.created_at || 0).getTime();
            if (deletionMap[idStr] >= remoteTime) {
              // This remote item was deleted locally, skip it!
              hasLocalChanges = true;
              continue;
            }
          }
          merged.push(remoteItem);
        }
      }
    }
    return { list: merged, changed: hasLocalChanges };
  },
  _syncFromCloud: function(){
    var self=this;
    this._loadFromFirestore().then(function(){
      self._seedIfEmpty();
      self._listenToFirestore();
      self._save(); // Cache Firestore data locally
      self._deduplicateClients();
      self._cleanOrphanFiados();
      // Notify UI that config_caja_negocio was refreshed from cloud
      try {
        var ev = new CustomEvent('db-change', { detail: { collection: 'config_caja_negocio' } });
        window.dispatchEvent(ev);
      } catch(err) {
        console.error('Error dispatching db-change:', err);
      }
    });
  },
  _deduplicateClients: function(){
    var self = this;
    try {
      var clientes = self.get('clientes');
      var fiados = self.get('fiados');
      var abonos = self.get('fiado_abonos');
      var ventas = self.get('ventas');
      
      if (!clientes || !clientes.length) return;
      
      var groups = {};
      clientes.forEach(function(c) {
        var name = (c.nombre || '').trim().toLowerCase();
        if (!name) return;
        if (!groups[name]) groups[name] = [];
        groups[name].push(c);
      });
      
      var hasChanges = false;
      var mergedCount = 0;
      
      Object.keys(groups).forEach(function(name) {
        var list = groups[name];
        if (list.length <= 1) return;
        
        list.sort(function(a, b) {
          var aScore = (a.telefono ? 1 : 0) + (a.email ? 1 : 0) + (a.numero_documento ? 1 : 0);
          var bScore = (b.telefono ? 1 : 0) + (b.email ? 1 : 0) + (b.numero_documento ? 1 : 0);
          if (aScore !== bScore) return bScore - aScore;
          return Number(a.id) - Number(b.id);
        });
        
        var master = list[0];
        var duplicates = list.slice(1);
        
        duplicates.forEach(function(dup) {
          var dupSaldo = Number(dup.saldo_pendiente || dup.saldoPendiente || 0);
          master.saldo_pendiente = (Number(master.saldo_pendiente) || 0) + dupSaldo;
          master.saldoPendiente = master.saldo_pendiente;
          
          fiados.forEach(function(f) {
            if (String(f.cliente_id) === String(dup.id)) {
              f.cliente_id = master.id;
              f.cliente_nombre = master.nombre;
              hasChanges = true;
            }
          });
          
          abonos.forEach(function(a) {
            if (String(a.cliente_id) === String(dup.id)) {
              a.cliente_id = master.id;
              hasChanges = true;
            }
          });
          
          ventas.forEach(function(v) {
            if (String(v.cliente_id) === String(dup.id)) {
              v.cliente_id = master.id;
              v.cliente_nombre = master.nombre;
              hasChanges = true;
            }
          });
          
          var dupIndex = clientes.findIndex(function(c) { return String(c.id) === String(dup.id); });
          if (dupIndex > -1) {
            clientes.splice(dupIndex, 1);
            hasChanges = true;
          }
          mergedCount++;
        });
      });
      
      if (hasChanges) {
        self._save('clientes');
        self._save('fiados');
        self._save('fiado_abonos');
        self._save('ventas');
        console.log('Deduplicated clients successfully. Merged ' + mergedCount + ' clients.');
        setTimeout(function(){
          if (typeof Helpers !== 'undefined' && Helpers.mostrarToast) {
            Helpers.mostrarToast('Base de datos depurada: Se fusionaron ' + mergedCount + ' clientes duplicados.', 'success');
          }
        }, 3000);
      }
      localStorage.setItem('deduplicate_done_v4', 'true');
    } catch (e) {
      console.error('Error during client deduplication:', e);
    }
  },
  _cleanOrphanFiados: function() {
    var self = this;
    try {
      var clientes = self.get('clientes') || [];
      var clientIds = {};
      clientes.forEach(function(c) {
        if (c && c.id != null) clientIds[String(c.id)] = true;
      });
      
      var fiados = self.get('fiados') || [];
      var abonos = self.get('fiado_abonos') || [];
      
      var initialFiadosCount = fiados.length;
      var initialAbonosCount = abonos.length;
      
      var cleanFiados = fiados.filter(function(f) {
        return f && f.cliente_id != null && clientIds[String(f.cliente_id)] === true;
      });
      var cleanAbonos = abonos.filter(function(a) {
        return a && a.cliente_id != null && clientIds[String(a.cliente_id)] === true;
      });
      
      if (cleanFiados.length !== initialFiadosCount || cleanAbonos.length !== initialAbonosCount) {
        self._data.fiados = cleanFiados;
        self._data.fiado_abonos = cleanAbonos;
        self._save('fiados');
        self._save('fiado_abonos');
        console.log('Cleaned up orphan fiados: removed ' + (initialFiadosCount - cleanFiados.length) + ' fiados, ' + (initialAbonosCount - cleanAbonos.length) + ' abonos.');
      }
    } catch (e) {
      console.error('Error cleaning up orphan fiados:', e);
    }
  },
  _seedIfEmpty: function(){
    if(this._data.roles.length===0){
      this._data.roles=[{id:1,nombre:'Admin',descripcion:'Administrador'},{id:2,nombre:'Cajero',descripcion:'Cajero'},{id:3,nombre:'Vendedor',descripcion:'Vendedor'},{id:4,nombre:'Jefe',descripcion:'Jefe'}];
    }
    
    // Default system permissions list
    var defaultPerms = [
      {id:1,modulo:'Pantallas',permiso:'dashboard',nombre:'Dashboard'},
      {id:2,modulo:'Pantallas',permiso:'caja',nombre:'Caja'},
      {id:3,modulo:'Pantallas',permiso:'productos',nombre:'Productos'},
      {id:4,modulo:'Pantallas',permiso:'clientes',nombre:'Clientes'},
      {id:5,modulo:'Pantallas',permiso:'proveedores',nombre:'Proveedores'},
      {id:6,modulo:'Pantallas',permiso:'ventas_super',nombre:'Ventas Super'},
      {id:7,modulo:'Pantallas',permiso:'ventas_bar',nombre:'Ventas Bar'},
      {id:8,modulo:'Pantallas',permiso:'fiados',nombre:'Fiados'},
      {id:9,modulo:'Pantallas',permiso:'historial_ventas',nombre:'Historial Ventas'},
      {id:10,modulo:'Pantallas',permiso:'compras',nombre:'Compras'},
      {id:11,modulo:'Pantallas',permiso:'compras_programadas',nombre:'Compras Programadas'},
      {id:12,modulo:'Pantallas',permiso:'autoconsumos',nombre:'Autoconsumos'},
      {id:13,modulo:'Pantallas',permiso:'categorias',nombre:'Categorias'},
      {id:14,modulo:'Pantallas',permiso:'reportes',nombre:'Reportes'},
      {id:15,modulo:'Pantallas',permiso:'cierres',nombre:'Cierres'},
      {id:16,modulo:'Pantallas',permiso:'distribuciones',nombre:'Distribuciones'},
      {id:17,modulo:'Pantallas',permiso:'configuracion',nombre:'Configuracion'},
      {id:18,modulo:'Pantallas',permiso:'usuarios',nombre:'Usuarios'},
      {id:19,modulo:'Acciones',permiso:'crear_venta',nombre:'Crear Venta'},
      {id:20,modulo:'Acciones',permiso:'crear_fiado',nombre:'Crear Fiado'},
      {id:21,modulo:'Acciones',permiso:'fiar',nombre:'Fiar'},
      {id:22,modulo:'Acciones',permiso:'descuentos',nombre:'Descuentos'},
      {id:23,modulo:'Acciones',permiso:'ajustar_stock',nombre:'Ajustar Stock'},
      {id:24,modulo:'Acciones',permiso:'registrar_productos',nombre:'Registrar Productos'},
      {id:25,modulo:'Acciones',permiso:'eliminar_productos',nombre:'Eliminar Productos'},
      {id:26,modulo:'Acciones',permiso:'abrir_caja',nombre:'Abrir Caja'},
      {id:27,modulo:'Acciones',permiso:'cerrar_caja',nombre:'Cerrar Caja'},
      {id:28,modulo:'Acciones',permiso:'editar_ventas',nombre:'Editar Ventas'},
      {id:29,modulo:'Acciones',permiso:'eliminar_ventas',nombre:'Eliminar Ventas'},
      {id:30,modulo:'Acciones',permiso:'editar_compras',nombre:'Editar Compras'},
      {id:31,modulo:'Acciones',permiso:'eliminar_compras',nombre:'Eliminar Compras'},
      {id:32,modulo:'Acciones',permiso:'editar_fiados',nombre:'Editar Fiados'},
      {id:33,modulo:'Acciones',permiso:'eliminar_fiados',nombre:'Eliminar Fiados'},
      {id:33,modulo:'Acciones',permiso:'editar_clientes',nombre:'Editar Clientes'},
      {id:34,modulo:'Acciones',permiso:'eliminar_clientes',nombre:'Eliminar Clientes'},
      {id:35,modulo:'Acciones',permiso:'editar_proveedores',nombre:'Editar Proveedores'},
      {id:36,modulo:'Acciones',permiso:'eliminar_proveedores',nombre:'Eliminar Proveedores'},
      {id:37,modulo:'Acciones',permiso:'editar_categorias',nombre:'Editar Categorias'},
      {id:38,modulo:'Acciones',permiso:'eliminar_categorias',nombre:'Eliminar Categorias'},
      {id:39,modulo:'Acciones',permiso:'editar_usuarios',nombre:'Editar Usuarios'},
      {id:40,modulo:'Acciones',permiso:'eliminar_usuarios',nombre:'Eliminar Usuarios'},
      {id:41,modulo:'Acciones',permiso:'editar_cierres',nombre:'Editar Cierres'},
      {id:42,modulo:'Acciones',permiso:'eliminar_cierres',nombre:'Eliminar Cierres'},
      {id:43,modulo:'Acciones',permiso:'abono_fiado',nombre:'Abonar Fiado'},
      {id:44,modulo:'Acciones',permiso:'pagar_compra',nombre:'Pagar Compra'},
      {id:45,modulo:'Acciones',permiso:'cambiar_precio_venta',nombre:'Cambiar Precio Venta'},
      {id:46,modulo:'Acciones',permiso:'admin',nombre:'Administracion del sistema'},
      {id:47,modulo:'Acciones',permiso:'editar_distribuciones',nombre:'Editar Distribuciones'},
      {id:48,modulo:'Acciones',permiso:'eliminar_distribuciones',nombre:'Eliminar Distribuciones'},
      {id:49,modulo:'Pantallas',permiso:'facturacion',nombre:'Facturacion'}
    ];

    var currentPerms = this._data.permisos || [];
    var currentMap = {};
    for (var i = 0; i < currentPerms.length; i++) {
      if (currentPerms[i]) {
        currentMap[String(currentPerms[i].id)] = currentPerms[i];
      }
    }
    
    var mergedPerms = [];
    var hasNew = false;
    for (var i = 0; i < defaultPerms.length; i++) {
      var dp = defaultPerms[i];
      if (currentMap[String(dp.id)]) {
        var existing = currentMap[String(dp.id)];
        existing.modulo = dp.modulo;
        existing.permiso = dp.permiso;
        existing.nombre = dp.nombre;
        mergedPerms.push(existing);
      } else {
        mergedPerms.push(dp);
        hasNew = true;
      }
    }
    
    this._data.permisos = mergedPerms;
    if (hasNew) {
      this._save('permisos');
    }

    // Always ensure admin user exists (Firestore sync may overwrite list)
    var hasNelson=false;
    for(var ui=0;ui<this._data.usuarios.length;ui++){
      if(this._data.usuarios[ui].username==='nelson'){hasNelson=true;break;}
    }
    if(!hasNelson){
      this._data.usuarios.push({
        id:this._nextId('usuarios'),username:'nelson',password:'nelsonrodri',
        nombre_completo:'Nelson Rodriguez',email:'nelson@elgranjero.com',
        telefono:'',rol:'Jefe',activo:true,ultimo_acceso:null
      });
    }
    if(this._data.usuarios.length===0){
      this._data.usuarios=[{
        id:this._nextId('usuarios'),username:'nelson',password:'nelsonrodri',
        nombre_completo:'Nelson Rodriguez',email:'nelson@elgranjero.com',
        telefono:'',rol:'Jefe',activo:true,ultimo_acceso:null
      }];
    }
  },
  _seedFromReact: function(data){
    if(!data)return;
    if(data.categorias)this._data.categorias=data.categorias;
    if(data.productos)this._data.productos=data.productos;
    if(data.clientes)this._data.clientes=data.clientes;
    this._save();
  },
  _getFirestore: function(){
    if(typeof firebase!=='undefined'&&firebase.firestore)return firebase.firestore();
    return null;
  },
  _writeColToFirestore: function(colName){
    if (this._silent) return;
    var db=this._getFirestore();
    if(!db||!this._data[colName])return;
    var self=this;
    var col=colName;
    
    if (colName === 'config_caja_negocio') {
      db.collection('datos').doc(colName).set(this._data[colName],{merge:true}).catch(function(e){
        console.warn('Firestore write error ('+colName+'):',e.code||e.message);
      });
      return;
    }
    
    // Use transaction to atomically read remote, merge with local, and write back.
    // This prevents the "last write wins" bug where one PC's full-collection overwrite
    // deletes products added by another PC.
    var docRef = db.collection('datos').doc(colName);
    db.runTransaction(function(transaction) {
      return transaction.get(docRef).then(function(doc) {
        var remoteList = [];
        if (doc.exists && doc.data().lista && Array.isArray(doc.data().lista)) {
          remoteList = doc.data().lista;
        }
        var res = self._mergeLists(col, self._data[col], remoteList);
        self._data[col] = res.list;
        try{localStorage.setItem('bridge_data',JSON.stringify(self._data));}catch(e){}
        transaction.set(docRef, {lista: self._data[col]}, {merge: true});
      });
    }).catch(function(e){
      console.warn('Firestore transaction error ('+col+'):',e.code||e.message, e.code==='permission-denied'?'(Requiere autenticacion)':'');
    });
  },
  _writeConfigCajaNegocio: function(){
    var db=this._getFirestore();
    if(!db||!this._data.config_caja_negocio)return;
    db.collection('datos').doc('config_caja_negocio').set(this._data.config_caja_negocio,{merge:true}).catch(function(e){
      console.warn('Firestore write error (config_caja_negocio):',e.code||e.message);
    });
  },
  _loadFromFirestore: function(){
    var db=this._getFirestore();
    if(!db)return;
    var self=this;
    // Load deletions first to ensure deletionMap is populated
    return db.collection('datos').doc('deletions').get().then(function(doc){
      if(doc.exists){
        var d=doc.data();
        if(d.lista&&Array.isArray(d.lista)){
          var local = self._data.deletions || [];
          var res = self._mergeLists('deletions', local, d.lista);
          self._data.deletions = res.list;
          if (res.changed) {
            self._writeColToFirestore('deletions');
          }
        }
      }
    }).catch(function(){}).then(function(){
      var colls=['productos','categorias','clientes','proveedores','ventas','cajas','movimientos_caja','fiados','fiado_abonos','user_actions','compras','compras_programadas','autoconsumos','distribuciones','usuarios','roles','permisos','cotizaciones','historial_precios'];
      var proms=[];
      for(var ci=0;ci<colls.length;ci++){
        (function(c){
          proms.push(db.collection('datos').doc(c).get().then(function(doc){
            if(doc.exists){
              var d=doc.data();
              if(d.lista&&Array.isArray(d.lista)){
                var local = self._data[c] || [];
                var res = self._mergeLists(c, local, d.lista);
                self._data[c] = res.list;
                if (res.changed) {
                  self._writeColToFirestore(c);
                }
              }
            }
          }).catch(function(){}));
        })(colls[ci]);
      }
      // Also load config_caja_negocio
      proms.push(db.collection('datos').doc('config_caja_negocio').get().then(function(doc){
        if(doc.exists){
          var d = doc.data() || {};
          var remoteCaja = {
            balance: d.balance != null ? Number(d.balance) : 0,
            ganancias_acumuladas: d.ganancias_acumuladas != null ? Number(d.ganancias_acumuladas) : 0,
            balance_al_cierre: d.balance_al_cierre != null ? Number(d.balance_al_cierre) : (d.balance != null ? Number(d.balance) : 0),
            updated_at: d.updated_at || null
          };
          var localCaja = self._data.config_caja_negocio || {balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
          var localTime = new Date(localCaja.updated_at || 0).getTime();
          var remoteTime = new Date(remoteCaja.updated_at || 0).getTime();
          if (localTime > remoteTime) {
            self._writeConfigCajaNegocio();
          } else {
            self._data.config_caja_negocio = remoteCaja;
            self._configStr = JSON.stringify(remoteCaja);
          }
        }
      }).catch(function(){}));
      return Promise.all(proms);
    });
  },
  _listenToFirestore: function(){
    var db=this._getFirestore();
    if(!db)return;
    var self=this;
    
    // Listen to deletions separately first
    db.collection('datos').doc('deletions').onSnapshot(function(doc){
      if(!doc.exists)return;
      var d=doc.data();
      if(!d.lista||!Array.isArray(d.lista))return;
      var oldStr = JSON.stringify(self._data.deletions||[]);
      var local = self._data.deletions || [];
      var res = self._mergeLists('deletions', local, d.lista);
      var neuStr = JSON.stringify(res.list);
      if(oldStr === neuStr) return;
      
      self._silent=true;
      self._data.deletions=res.list;
      try{localStorage.setItem('bridge_data',JSON.stringify(self._data));}catch(e){}
      
      if (res.changed) {
        self._writeColToFirestore('deletions');
      }
      
      self._silent=false;
      try {
        var ev = new CustomEvent('db-change', { detail: { collection: 'deletions' } });
        window.dispatchEvent(ev);
      } catch(err) {}
    },function(){});

    // Listen to all other collections
    var colls=['productos','categorias','clientes','proveedores','ventas','cajas','movimientos_caja','fiados','fiado_abonos','user_actions','compras','compras_programadas','autoconsumos','distribuciones','usuarios','roles','permisos','cotizaciones','historial_precios'];
    for(var ci=0;ci<colls.length;ci++){
      (function(c){
        db.collection('datos').doc(c).onSnapshot(function(doc){
          if(!doc.exists)return;
          var d=doc.data();
          if(!d.lista||!Array.isArray(d.lista))return;
          var oldStr = JSON.stringify(self._data[c]||[]);
          var local = self._data[c] || [];
          var res = self._mergeLists(c, local, d.lista);
          var neuStr = JSON.stringify(res.list);
          if(oldStr === neuStr) return;
          
          self._silent=true;
          self._data[c]=res.list;
          if(c==='usuarios'){self._seedIfEmpty();}
          try{localStorage.setItem('bridge_data',JSON.stringify(self._data));}catch(e){}
          
          if (res.changed) {
            self._writeColToFirestore(c);
          }
          
          self._silent=false;
          
          try {
            var ev = new CustomEvent('db-change', { detail: { collection: c } });
            window.dispatchEvent(ev);
          } catch(err) {
            console.error('Error dispatching db-change:', err);
          }
        },function(){});
      })(colls[ci]);
    }
    // Also listen to config_caja_negocio
    db.collection('datos').doc('config_caja_negocio').onSnapshot(function(doc){
      if(!doc.exists)return;
      var d=doc.data() || {};
      var remoteCaja = {
        balance: d.balance != null ? Number(d.balance) : 0,
        ganancias_acumuladas: d.ganancias_acumuladas != null ? Number(d.ganancias_acumuladas) : 0,
        balance_al_cierre: d.balance_al_cierre != null ? Number(d.balance_al_cierre) : (d.balance != null ? Number(d.balance) : 0),
        updated_at: d.updated_at || null
      };
      var localCaja = self._data.config_caja_negocio || {balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      var localTime = new Date(localCaja.updated_at || 0).getTime();
      var remoteTime = new Date(remoteCaja.updated_at || 0).getTime();
      
      var old=JSON.stringify(self._data.config_caja_negocio||{});
      var neu=JSON.stringify(remoteCaja);
      if (localTime > remoteTime) {
        self._writeConfigCajaNegocio();
        return;
      }
      if(old===neu)return;
      
      self._silent=true;
      self._data.config_caja_negocio=remoteCaja;
      self._configStr = JSON.stringify(remoteCaja);
      try{localStorage.setItem('bridge_data',JSON.stringify(self._data));}catch(e){}
      self._silent=false;
      
      try {
        var ev = new CustomEvent('db-change', { detail: { collection: 'config_caja_negocio' } });
        window.dispatchEvent(ev);
      } catch(err) {
        console.error('Error dispatching db-change:', err);
      }
    },function(){});
  },
  _save: function(col){
    try{localStorage.setItem('bridge_data',JSON.stringify(this._data));}catch(e){}
    if(col && !this._silent){
      this._writeColToFirestore(col);
    }
    // Write config_caja_negocio to Firestore if changed
    if(!this._silent && this._data.config_caja_negocio){
      var curStr = JSON.stringify(this._data.config_caja_negocio);
      if(curStr !== this._configStr){
        this._configStr = curStr;
        this._writeConfigCajaNegocio();
      }
    }
  },
  _nextId: function(col){
    var arr=this._data[col];
    if(!arr)return 1;
    var max=0;
    for(var i=0;i<arr.length;i++){if(arr[i].id>max)max=arr[i].id;}
    return max+1;
  },
  get: function(col){
    return this._data[col]||[];
  },
  getConfigCajaNegocio: function(){
    var val = this._data.config_caja_negocio;
    if(!val || Array.isArray(val)){
      this._data.config_caja_negocio = {balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      val = this._data.config_caja_negocio;
    }
    return val;
  },
  getById: function(col,id){
    var arr=this._data[col]||[];
    for(var i=0;i<arr.length;i++){if(String(arr[i].id)===String(id))return arr[i];}
    return null;
  },
  create: function(col,data){
    data.id=this._nextId(col);
    if(!data.created_at)data.created_at=new Date().toISOString();
    var arr=this._data[col];
    if(!arr){this._data[col]=[];arr=this._data[col];}
    arr.push(data);
    this._save(col);
    return data;
  },
  update: function(col,id,data){
    var arr=this._data[col]||[];
    for(var i=0;i<arr.length;i++){
      if(String(arr[i].id)===String(id)){
        if(col==='productos'&&data.precio_venta!=null&&arr[i].precio_venta!=null&&data.precio_venta!==arr[i].precio_venta){
          if(!arr[i].historial_precios)arr[i].historial_precios=[];
          arr[i].historial_precios.push({
            precio_anterior:arr[i].precio_venta,
            precio_nuevo:data.precio_venta,
            fecha_cambio:new Date().toISOString()
          });
        }
        for(var k in data){if(data.hasOwnProperty(k))arr[i][k]=data[k];}
        arr[i].updated_at=new Date().toISOString();
        this._save(col);
        return arr[i];
      }
    }
    throw new Error('Registro no encontrado en '+col+' id='+id);
  },
  delete: function(col,id){
    var arr=this._data[col]||[];
    for(var i=0;i<arr.length;i++){
      if(String(arr[i].id)===String(id)){
        arr.splice(i,1);
        
        // Record deletion log to prevent resurrection
        var delId = col + '_' + id;
        this._data.deletions = this._data.deletions || [];
        var existingDel = this._data.deletions.find(function(d){ return d.id === delId; });
        if (!existingDel) {
          this._data.deletions.push({
            id: delId,
            col: col,
            target_id: id,
            deleted_at: new Date().toISOString()
          });
          this._save('deletions');
        }

        this._save(col);
        return true;
      }
    }
    throw new Error('Registro no encontrado');
  }
};

window.API = {
  currentQueryParams: null,
  get: function(url,opts){
    return this.request('GET',url,null,opts);
  },
  post: function(url,data,opts){
    return this.request('POST',url,data,opts);
  },
  put: function(url,data,opts){
    return this.request('PUT',url,data,opts);
  },
  patch: function(url,data,opts){
    return this.request('PATCH',url,data,opts);
  },
  del: function(url,data,opts){
    return this.request('DEL',url,data||null,opts);
  },
  logAction: function(accion,detalle){
    try{
      var usuario='Sistema';
      var saved=localStorage.getItem('el_granjero_session');
      if(saved){var sess=JSON.parse(saved);usuario=sess.username||sess.nombre_completo||'Sistema';}
      BridgeDB.create('user_actions',{
        accion:accion,detalle:detalle,usuario:usuario,usuario_nombre:usuario,
        timestamp:new Date().toISOString()
      });
    }catch(e){}
  },
  request: function(method,url,data,opts){
    opts=opts||{};
    var u=url.replace(/\/+/g,'/');
    if(u.endsWith('/')&&u.length>1)u=u.slice(0,-1);
    var parts=u.split('/').filter(function(p){return p!=='';});
    var result=null;

    // Parse query params
    if(parts.length>0&&parts[parts.length-1].indexOf('?')>-1){
      var lastPart=parts[parts.length-1];
      var qIdx=lastPart.indexOf('?');
      var qStr=lastPart.substring(qIdx+1);
      parts[parts.length-1]=lastPart.substring(0,qIdx);
      this.currentQueryParams={};
      qStr.split('&').forEach(function(pair){
        var eq=pair.indexOf('=');
        if(eq>-1)this.currentQueryParams[decodeURIComponent(pair.substring(0,eq))]=decodeURIComponent(pair.substring(eq+1));
      }.bind(this));
    }else{
      this.currentQueryParams=null;
    }

    // Short routes
    if(parts[0]==='dashboard'){
      result=this._handleDashboard(method,parts,data);
    }else if(parts[0]==='caja'){
      result=this._handleCaja(method,parts,data);
    }else if(parts[0]==='clientes'){
      result=this._handleClientes(method,parts,data);
    }else if(parts[0]==='fiados'){
      result=this._handleFiados(method,parts,data);
    }else if(parts[0]==='distribuciones'){
      result=this._handleDistribuciones(method,parts,data);
    }else if(parts[0]==='categorias'){
      result=this._crud('categorias',method,parts[1]||null,data);
    }else if(parts[0]==='api'){
      result=this._routeApi(method,parts,data);
    }

    if(result===undefined||result===null){
      return Promise.reject(new Error('Ruta no encontrada: '+u));
    }
    if(result&&typeof result.then==='function')return result;
    return Promise.resolve(result);
  },
  _routeApi: function(method,parts,data){
    var col=parts[1];
    var idOrAction=parts[2]||null;
    var subCol=parts[3]||null;
    var itemId=parts[4]||null;
    var subsub=parts[5]||null;

    // Extract numeric ID if present
    var entidadId=null;
    var subaccion=null;
    if(idOrAction&&/^\d+$/.test(idOrAction)){
      entidadId=idOrAction;
      subaccion=subCol;
    }else{
      subaccion=idOrAction;
      entidadId=subCol;
      itemId=parts[4];
      subsub=parts[5];
    }

    if(col==='proveedores')return this._handleProveedores(method,entidadId,subaccion,data,parts);
    if(col==='productos'){
      if(method==='PATCH'&&subaccion==='stock')return this._patchStock(entidadId,data);
      return this._crud('productos',method,entidadId,data);
    }
    if(col==='clientes')return this._handleClientes(method,parts.slice(1),data);
    if(col==='categorias')return this._crud('categorias',method,entidadId,data);
    if(col==='marcas')return BridgeDB.get('productos').map(function(p){return p.marca;}).filter(function(v,i,a){return v&&a.indexOf(v)===i;});
    if(col==='ventas'){
      if(method==='POST')return this._handleCrearVenta(data);
    }
    if(col==='ventas-bar')return this._handleVentasBar(method,entidadId,subaccion,data,parts);
    if(col==='historial-ventas')return this._handleHistorialVentas(method,entidadId,data);
    if(col==='compras'){
      if(entidadId&&subaccion==='visita')return this._handleVisita(method,entidadId,data);
      if(entidadId&&subaccion==='pagar')return this._handlePagarCompra(entidadId);
      return this._handleCompras(method,entidadId,data);
    }
    if(col==='compras-programadas'){
      if(subaccion==='abastecer')return this._handleAbastecer(method,entidadId,data);
      return this._handleComprasProgramadas(method,entidadId,data);
    }
    if(col==='autoconsumos')return this._handleAutoconsumos(method,entidadId,data);
    if(col==='cotizaciones'){
      if(method==='POST')return BridgeDB.create('cotizaciones',data);
      return BridgeDB.get('cotizaciones');
    }
    if(col==='reportes')return this._handleReportes(method,subaccion,entidadId,data);
    if(col==='sync')return this._handleSync(method,subaccion,data);
    if(col==='usuarios')return this._handleUsuarios(method,entidadId,subaccion,itemId,data);
    if(col==='log'){
      if(method==='POST'){BridgeDB.create('user_actions',data);return {ok:true};}
      return BridgeDB.get('user_actions');
    }

    return Promise.reject(new Error('API no encontrada'));
  },
  _crud: function(col,method,id,data){
    if(method==='GET'&&id){
      if(id==='stock')return BridgeDB.get(col);
      return BridgeDB.getById(col,id);
    }
    if(method==='GET')return BridgeDB.get(col);
    if(method==='POST')return BridgeDB.create(col,data);
    if(method==='PUT'&&id)return BridgeDB.update(col,id,data);
    if(method==='PATCH'&&id)return BridgeDB.update(col,id,data);
    if(method==='DEL'&&id)return BridgeDB.delete(col,id);
    return null;
  },
  _patchStock: function(id,data){
    var prod=BridgeDB.getById('productos',id);
    if(!prod)throw new Error('Producto no encontrado');
    return BridgeDB.update('productos',id,{stock_actual:(data.cantidad!=null?data.cantidad:prod.stock_actual)});
  },

  _handleCrearVenta: function(data){
    if(!data||!data.items||!data.items.length)throw new Error('Carrito vacío');
    if(!data.usuario){
      try{var s=JSON.parse(localStorage.getItem('el_granjero_session')||'{}');data.usuario=s.username||s.nombre_completo||'Sistema';}catch(e){data.usuario='Sistema';}
    }
    data.cliente_nombre=data.cliente_nombre||'Mostrador';
    data.fecha=data.fecha||Helpers.today();
    data.estado='completada';
    // Calculate total_costo from items
    var totalCosto=0,totalBruto=0;
    var prods=BridgeDB.get('productos');
    for(var i=0;i<data.items.length;i++){
      var item=data.items[i];
      var prod=null;
      for(var j=0;j<prods.length;j++){if(String(prods[j].id)===String(item.producto_id)){prod=prods[j];break;}}
      var qty=item.cantidad||1;
      totalBruto+=qty*(item.precio_unitario||0);
      if(prod){
        var newStock=(prod.stock_actual||0)-qty;
        if(newStock<0)throw new Error('Stock insuficiente: '+prod.nombre);
        BridgeDB.update('productos',prod.id,{stock_actual:newStock});
        if(!item.precio_compra)item.precio_compra=prod.precio_compra||0;
        totalCosto+=qty*(prod.precio_compra||0);
        if(!item.nombre)item.nombre=prod.nombre;
      }
    }
    if(!data.subtotal)data.subtotal=totalBruto;
    if(!data.total)data.total=totalBruto-(data.descuento||0);
    data.total_costo=totalCosto;
    var venta=BridgeDB.create('ventas',data);
    // Caja movement for non-fiado
    if(data.metodo_pago!=='fiado'){
      var caAb=BridgeDB.get('cajas').filter(function(c){return c.estado==='abierta';});
      if(caAb.length>0){
        var mov = BridgeDB.create('movimientos_caja',{caja_id:caAb[0].id,tipo:'ingreso',concepto:'Venta #'+venta.id,monto:data.total||0,metodo_pago:data.metodo_pago||'efectivo',fecha:data.fecha});
        caAb[0].ingresos=(caAb[0].ingresos||0)+(data.total||0);
        if(!caAb[0].movimientos) caAb[0].movimientos=[];
        caAb[0].movimientos.push(mov);
        BridgeDB.update('cajas',caAb[0].id,{ingresos:caAb[0].ingresos,movimientos:caAb[0].movimientos});
      }
    }
    // Fiado
    if(data.metodo_pago==='fiado'&&data.cliente_id){
      var montoFiado=data.total||totalBruto;
      BridgeDB.create('fiados',{
        cliente_id:data.cliente_id,monto_original:montoFiado,monto_pendiente:montoFiado,
        saldo:montoFiado,monto:montoFiado,
        fecha:data.fecha,estado:'Pendiente',venta_id:venta.id,
        items:data.items,detalle:'Venta fiada - '+data.cliente_nombre,
        producto_id:data.items[0]?data.items[0].producto_id:null,
        producto_nombre:data.items[0]?data.items[0].nombre:'',
        cantidad:data.items.length
      });
      // Update client saldo_pendiente
      var cl=BridgeDB.getById('clientes',data.cliente_id);
      if(cl)BridgeDB.update('clientes',cl.id,{saldo_pendiente:(cl.saldo_pendiente||0)+montoFiado});
    }
    return venta;
  },

  _handleVentasBar: function(method,entidadId,subaccion,data,parts){
    // parts[0]=api, [1]=ventas-bar, [2]=tipo(cuentas/categorias/productos), [3]=entidadId, [4]=subaccion(productos), [5]=itemId, [6]=subsub(pagar)
    var tipo=parts[2];
    var entId=parts[3]||null;
    var sub=parts[4]||null;
    var itemId=parts[5]||null;
    var subsub=parts[6]||null;

    if(tipo==='cuentas'){
      if(method==='GET'&&!entId)return BridgeDB.get('ventas_bar_cuentas');
      if(method==='GET'&&entId&&!sub)return BridgeDB.getById('ventas_bar_cuentas',entId);
      if(method==='POST'&&!entId)return BridgeDB.create('ventas_bar_cuentas',data);
      if(method==='PUT'&&entId&&!sub)return BridgeDB.update('ventas_bar_cuentas',entId,data);
      if(method==='POST'&&entId&&sub==='cerrar'){
        var cuenta=BridgeDB.getById('ventas_bar_cuentas',entId);
        if(!cuenta)throw new Error('Cuenta no encontrada');
        if(data.pasar_a_fiado&&data.cliente_id){
          var itemsFiar=data.items||[];
          if(itemsFiar.length>0){
            var totalFiado=0;
            for(var fi=0;fi<itemsFiar.length;fi++){
              var it=itemsFiar[fi];
              var subt=(it.cantidad||1)*(it.precio_unitario||0);
              totalFiado+=subt;
              BridgeDB.create('fiados',{
                cliente_id:data.cliente_id,
                producto_id:it.producto_id,
                producto_nombre:it.nombre||'',
                cantidad:it.cantidad||1,
                monto_original:subt,monto_pendiente:subt,
                saldo:subt,monto:subt,
                precio_unitario:it.precio_unitario||0,
                fecha:Helpers.today(),estado:'Pendiente',
                detalle:'Cuenta Bar #'+entId,
                items:[it]
              });
            }
            var cl=BridgeDB.getById('clientes',data.cliente_id);
            if(cl)BridgeDB.update('clientes',cl.id,{saldo_pendiente:(cl.saldo_pendiente||0)+totalFiado});
            var prodsC=cuenta.productos||[];
            for(var pc=0;pc<prodsC.length;pc++){
              if(!prodsC[pc].pagado) prodsC[pc].pagado=true;
            }
            BridgeDB.update('ventas_bar_cuentas',entId,{productos:prodsC});
          }
        }
        return BridgeDB.update('ventas_bar_cuentas',entId,{estado:'cerrada',fecha_cierre:new Date().toISOString()});
      }
      if(method==='PUT'&&entId&&sub==='productos'&&itemId&&subsub==='pagar'){
        var cuentaP=BridgeDB.getById('ventas_bar_cuentas',entId);
        if(!cuentaP)throw new Error('Cuenta no encontrada');
        var prodsP=cuentaP.productos||[];
        for(var j=0;j<prodsP.length;j++){
          if(String(prodsP[j].id||prodsP[j].producto_id)===String(itemId)){prodsP[j].pagado=true;break;}
        }
        var tp=BridgeDB._calcBarTotals(prodsP);
        return BridgeDB.update('ventas_bar_cuentas',entId,{productos:prodsP,total:tp.total,total_productos:tp.count});
      }
      if(method==='PUT'&&entId&&sub==='productos'&&itemId){
        var cuentaU=BridgeDB.getById('ventas_bar_cuentas',entId);
        if(!cuentaU)throw new Error('Cuenta no encontrada');
        var prodsU=cuentaU.productos||[];
        for(var k=0;k<prodsU.length;k++){
          if(String(prodsU[k].id||prodsU[k].producto_id)===String(itemId)){
            // Validate stock
            var prodId = prodsU[k].producto_id || prodsU[k].id;
            var p = BridgeDB.getById('productos', prodId) || BridgeDB.getById('ventas_bar_productos', prodId);
            if (p) {
              var stock = p.stock_actual != null ? p.stock_actual : (p.stock != null ? p.stock : 999999);
              var otherQty = 0;
              for (var o = 0; o < prodsU.length; o++) {
                if (o !== k && String(prodsU[o].producto_id || prodsU[o].id) === String(prodId)) {
                  otherQty += prodsU[o].cantidad;
                }
              }
              if (otherQty + data.cantidad > stock) {
                throw new Error('Stock insuficiente. Disponible: ' + stock);
              }
            }
            prodsU[k].cantidad=data.cantidad;
            prodsU[k].subtotal=data.cantidad*(prodsU[k].precio_unitario||0);
            break;
          }
        }
        var tu=BridgeDB._calcBarTotals(prodsU);
        return BridgeDB.update('ventas_bar_cuentas',entId,{productos:prodsU,total:tu.total,total_productos:tu.count});
      }
      if(method==='DEL'&&entId&&sub==='productos'&&itemId){
        var cuentaD=BridgeDB.getById('ventas_bar_cuentas',entId);
        if(!cuentaD)throw new Error('Cuenta no encontrada');
        var prodsD=cuentaD.productos||[];
        var newProds=[];
        for(var l=0;l<prodsD.length;l++){
          if(String(prodsD[l].id||prodsD[l].producto_id)!==String(itemId))newProds.push(prodsD[l]);
        }
        var td=BridgeDB._calcBarTotals(newProds);
        return BridgeDB.update('ventas_bar_cuentas',entId,{productos:newProds,total:td.total,total_productos:td.count});
      }
      // POST to cuenta to add producto
      if(method==='POST'&&entId){
        var cuentaA=BridgeDB.getById('ventas_bar_cuentas',entId);
        if(!cuentaA)throw new Error('Cuenta no encontrada');
        if(!cuentaA.productos)cuentaA.productos=[];
        var p = BridgeDB.getById('productos', data.producto_id) || BridgeDB.getById('ventas_bar_productos', data.producto_id);
        if (p) {
          var stock = p.stock_actual != null ? p.stock_actual : (p.stock != null ? p.stock : 999999);
          var currentQty = 0;
          for (var o = 0; o < cuentaA.productos.length; o++) {
            if (String(cuentaA.productos[o].producto_id) === String(data.producto_id)) {
              currentQty += cuentaA.productos[o].cantidad;
            }
          }
          if (currentQty + (data.cantidad||1) > stock) {
            throw new Error('Stock insuficiente. Disponible: ' + stock);
          }
        }
        var existente = null;
        for (var e = 0; e < cuentaA.productos.length; e++) {
          if (String(cuentaA.productos[e].producto_id) === String(data.producto_id) && !cuentaA.productos[e].pagado) {
            existente = cuentaA.productos[e];
            break;
          }
        }
        if (existente) {
          existente.cantidad = (existente.cantidad||1) + (data.cantidad||1);
          existente.subtotal = existente.cantidad * (existente.precio_unitario||data.precio_unitario||0);
        } else {
          data.id=BridgeDB._nextId('ventas_bar_cuentas')+'_'+Date.now();
          if(!data.pagado)data.pagado=false;
          data.subtotal = (data.cantidad||1) * (data.precio_unitario||0);
          cuentaA.productos.push(data);
        }
        return BridgeDB.update('ventas_bar_cuentas',entId,{productos:cuentaA.productos});
      }
    }
    if(tipo==='categorias'){
      if(method==='GET')return BridgeDB.get('ventas_bar_categorias');
      if(method==='POST')return BridgeDB.create('ventas_bar_categorias',data);
    }
    if(tipo==='productos'){
      if(method==='GET')return BridgeDB.get('ventas_bar_productos');
      if(method==='POST')return BridgeDB.create('ventas_bar_productos',data);
    }
    return null;
  },

  _handleProveedores: function(method,id,action,data,parts){
    if(method==='GET'&&action==='visitas'){
      var qp=this.currentQueryParams||{};
      var mes=qp.mes||'',anio=qp.anio||'';
      var visitas=BridgeDB.get('visitas_proveedor');
      if(mes&&anio)visitas=visitas.filter(function(v){return(v.fecha||'').substring(0,7)===anio+'-'+mes;});
      else if(mes)visitas=visitas.filter(function(v){return(v.fecha||'').substring(5,7)===mes;});
      return visitas;
    }
    if(method==='GET'&&id&&action==='calendario'){
      var qpc=this.currentQueryParams||{};
      var cmes=qpc.mes||'',canio=qpc.anio||'';
      var cvisitas=BridgeDB.get('visitas_proveedor').filter(function(v){
        return String(v.proveedor_id)===String(id)&&(v.fecha||'').substring(0,7)===cmes;
      });
      return{citas:cvisitas,proveedor_id:id};
    }
    if(method==='GET'&&id&&action==='compras'){
      var qpcm=this.currentQueryParams||{};
      var fecha=qpcm.fecha||'';
      var compras=BridgeDB.get('compras').filter(function(c){
        return String(c.proveedor_id)===String(id)&&(!fecha||(c.fecha||'')===fecha);
      });
      return{data:compras};
    }
    if(method==='GET'&&id&&action==='visitas'){
      var provVisitas=BridgeDB.get('visitas_proveedor').filter(function(v){
        return String(v.proveedor_id)===String(id);
      });
      return{data:provVisitas};
    }
    if(method==='GET'&&id)return BridgeDB.getById('proveedores',id);
    if(method==='GET')return BridgeDB.get('proveedores');
    if(method==='POST'&&!id)return BridgeDB.create('proveedores',data);
    if(method==='PUT'&&id)return BridgeDB.update('proveedores',id,data);
    if(method==='DEL'&&id)return BridgeDB.delete('proveedores',id);
    return null;
  },

  _handleVisita: function(method,provId,data){
    if(method==='POST'){
      return BridgeDB.create('visitas_proveedor',{
        proveedor_id:Number(provId),fecha:data.fecha||Helpers.today(),
        programada:!!data.programada
      });
    }
    return null;
  },

  _handlePagarCompra: function(id){
    var comp=BridgeDB.getById('compras',id);
    if(!comp)throw new Error('Compra no encontrada');
    var total=comp.total||0;
    var cajaN=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
    cajaN.balance=(cajaN.balance||0)-total;
    cajaN.balance_al_cierre=(cajaN.balance_al_cierre||0)-total;
    if(cajaN.balance<0)cajaN.balance=0;
    if(cajaN.balance_al_cierre<0)cajaN.balance_al_cierre=0;
    cajaN.updated_at=new Date().toISOString();
    BridgeDB._data.config_caja_negocio=cajaN;
    BridgeDB._save();
    return BridgeDB.update('compras',id,{pagado:true});
  },

  _handleCompras: function(method,id,data){
    if(method==='GET'&&id)return BridgeDB.getById('compras',id);
    if(method==='GET'){
      var qp=this.currentQueryParams||{};
      var provId=qp.proveedor_id||null;
      if(provId)return BridgeDB.get('compras').filter(function(c){return String(c.proveedor_id)===String(provId);});
      return BridgeDB.get('compras');
    }
    if(method==='POST'){
      var compra=BridgeDB.create('compras',data);
      if(data.pagado){
        var total2=compra.total||compra.subtotal||0;
        var cajaN2=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
        cajaN2.balance=(cajaN2.balance||0)-total2;
        cajaN2.balance_al_cierre=(cajaN2.balance_al_cierre||0)-total2;
        if(cajaN2.balance<0)cajaN2.balance=0;
        if(cajaN2.balance_al_cierre<0)cajaN2.balance_al_cierre=0;
        cajaN2.updated_at=new Date().toISOString();
        BridgeDB._data.config_caja_negocio=cajaN2;
        BridgeDB._save();
      }
      return compra;
    }
    if(method==='PUT'&&id){
      var oldComp=BridgeDB.getById('compras',id);
      var oldPagado=oldComp?oldComp.pagado:false;
      var oldTotal=oldComp?oldComp.total:0;
      var newPagado=data.pagado;
      var newTotal=data.total||oldTotal||0;
      var result=BridgeDB.update('compras',id,data);
      if(!oldPagado&&newPagado){
        var cajaN3=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
        cajaN3.balance=(cajaN3.balance||0)-newTotal;
        cajaN3.balance_al_cierre=(cajaN3.balance_al_cierre||0)-newTotal;
        if(cajaN3.balance<0)cajaN3.balance=0;
        if(cajaN3.balance_al_cierre<0)cajaN3.balance_al_cierre=0;
        cajaN3.updated_at=new Date().toISOString();
        BridgeDB._data.config_caja_negocio=cajaN3;
        BridgeDB._save();
      }else if(oldPagado&&!newPagado){
        var cajaN4=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
        cajaN4.balance=(cajaN4.balance||0)+oldTotal;
        cajaN4.balance_al_cierre=(cajaN4.balance_al_cierre||0)+oldTotal;
        cajaN4.updated_at=new Date().toISOString();
        BridgeDB._data.config_caja_negocio=cajaN4;
        BridgeDB._save();
      }else if(oldPagado&&newPagado&&newTotal!==oldTotal){
        var diff=newTotal-oldTotal;
        var cajaN5=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
        cajaN5.balance=(cajaN5.balance||0)-diff;
        cajaN5.balance_al_cierre=(cajaN5.balance_al_cierre||0)-diff;
        if(cajaN5.balance<0)cajaN5.balance=0;
        if(cajaN5.balance_al_cierre<0)cajaN5.balance_al_cierre=0;
        cajaN5.updated_at=new Date().toISOString();
        BridgeDB._data.config_caja_negocio=cajaN5;
        BridgeDB._save();
      }
      return result;
    }
    if(method==='DEL'&&id){
      var oldComp=BridgeDB.getById('compras',id);
      if(oldComp && (oldComp.pagado || oldComp.estado === 'Pagada')){
        var total=oldComp.total||0;
        var cajaN=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
        cajaN.balance=(cajaN.balance||0)+total;
        cajaN.balance_al_cierre=(cajaN.balance_al_cierre||0)+total;
        cajaN.updated_at=new Date().toISOString();
        BridgeDB._data.config_caja_negocio=cajaN;
        BridgeDB._save();
      }
      return BridgeDB.delete('compras',id);
    }
    return null;
  },

  _handleComprasProgramadas: function(method,id,data){
    if(method==='GET')return BridgeDB.get('compras_programadas');
    if(method==='POST')return BridgeDB.create('compras_programadas',data);
    if(method==='PUT'&&id)return BridgeDB.update('compras_programadas',id,data);
    if(method==='DEL'&&id)return BridgeDB.delete('compras_programadas',id);
    return null;
  },

  _handleAutoconsumos: function(method,id,data){
    var now = new Date().toISOString();
    var productos = BridgeDB.get('productos');
    var buscarProd = function(pid){
      for(var i=0;i<productos.length;i++){if(String(productos[i].id)===String(pid))return productos[i];}
      return null;
    };
    if(method==='GET')return BridgeDB.get('autoconsumos');
    if(method==='POST'){
      var prod = buscarProd(data.producto_id);
      if(!prod)throw new Error('Producto no encontrado');
      if((prod.stock_actual||0) < (data.cantidad||0))throw new Error('Stock insuficiente');
      prod.stock_actual = (prod.stock_actual||0) - (data.cantidad||0);
      data.created_at = now;
      data.updated_at = now;
      var result = BridgeDB.create('autoconsumos',data);
      BridgeDB._save();
      return result;
    }
    if(method==='PUT'&&id){
      var old = BridgeDB.getById('autoconsumos',id);
      if(!old)throw new Error('Consumo no encontrado');
      var oldProd = buscarProd(old.producto_id);
      if(oldProd) oldProd.stock_actual = (oldProd.stock_actual||0) + (old.cantidad||0);
      var newProd = buscarProd(data.producto_id);
      if(!newProd)throw new Error('Producto no encontrado');
      if((newProd.stock_actual||0) < (data.cantidad||0))throw new Error('Stock insuficiente');
      newProd.stock_actual = (newProd.stock_actual||0) - (data.cantidad||0);
      data.updated_at = now;
      var result2 = BridgeDB.update('autoconsumos',id,data);
      BridgeDB._save();
      return result2;
    }
    if(method==='DEL'&&id){
      var old2 = BridgeDB.getById('autoconsumos',id);
      if(old2){
        var oldProd2 = buscarProd(old2.producto_id);
        if(oldProd2) oldProd2.stock_actual = (oldProd2.stock_actual||0) + (old2.cantidad||0);
      }
      var result3 = BridgeDB.delete('autoconsumos',id);
      BridgeDB._save();
      return result3;
    }
    return null;
  },

  _handleAbastecer: function(method,id,data){
    var col='_abastecimientos';
    if(!BridgeDB._data[col])BridgeDB._data[col]=[];
    if(method==='GET'){
      if(id)return BridgeDB.getById(col,id);
      return BridgeDB.get(col);
    }
    if(method==='POST')return BridgeDB.create(col,data);
    if(method==='PUT'&&id)return BridgeDB.update(col,id,data);
    if(method==='DEL'&&id)return BridgeDB.delete(col,id);
    return null;
  },

  _handleDashboard: function(method,parts,data){
    var prods=BridgeDB.get('productos');
    var ventas=BridgeDB.get('ventas');
    var clientes=BridgeDB.get('clientes');
    var fiados=BridgeDB.get('fiados');
    var cuentasBar=BridgeDB.get('ventas_bar_cuentas');
    var today=Helpers.today();
    var thisMonth=Helpers.thisMonth();

    var ventasHoy=ventas.filter(function(v){return v.fecha===today;});
    var ventasMes=ventas.filter(function(v){return(v.fecha||'').substring(0,7)===thisMonth;});

    var ventasDia=ventasHoy.filter(function(v){return v.metodo_pago!=='fiado';}).length;
    var ventasDiaMonto=ventasHoy.filter(function(v){return v.metodo_pago!=='fiado';}).reduce(function(s,v){return s+(v.total||0);},0);
    var gananciasDia=0;
    ventasHoy.forEach(function(v){
      if(v.metodo_pago==='fiado')return;
      gananciasDia+=(v.total||0)-((v.items||[]).reduce(function(s,i){return s+(i.cantidad||1)*(i.precio_compra||0);},0));
    });

    var stockBajo=prods.filter(function(p){return(p.stock_actual||0)>0&&(p.stock_actual||0)<=(p.stock_minimo||0);});
    var agotados=prods.filter(function(p){return(p.stock_actual||0)===0;});
    var valorInv=prods.reduce(function(s,p){return s+(p.stock_actual||0)*(p.precio_compra||0);},0);
    var deudaTotal=fiados.filter(function(f){return (f.estado||'')!=='Pagado'&&String(f.estado||'').toLowerCase()!=='pagado';}).reduce(function(s,f){return s+(Number(f.saldo||f.saldoPendiente||f.monto_pendiente||0));},0);
    var cuentasAbiertas=cuentasBar.filter(function(c){return c.estado!=='cerrada';}).length;

    var ventasMesTotal=ventasMes.filter(function(v){return v.metodo_pago!=='fiado';}).reduce(function(s,v){return s+(v.total||0);},0);

    // top productos
    var topMap={};
    ventasMes.forEach(function(v){
      (v.items||[]).forEach(function(item){
        var pid=String(item.producto_id||'');
        if(!topMap[pid])topMap[pid]={producto_id:pid,nombre:item.nombre||'',cantidad:0,total:0};
        topMap[pid].cantidad+=item.cantidad||1;
        topMap[pid].total+=(item.cantidad||1)*(item.precio_unitario||0);
      });
    });
    var topProductos=Object.values(topMap).sort(function(a,b){return b.total-a.total;}).slice(0,10);

    // ventas por categoria
    var catMap={};
    var catList=BridgeDB.get('categorias');
    catList.forEach(function(c){catMap[c.nombre]={categoria:c.nombre,ingresos:0,costo_ventas:0,ganancia_bruta:0};});
    ventasMes.forEach(function(v){
      (v.items||[]).forEach(function(item){
        var prod=prods.find(function(p){return String(p.id)===String(item.producto_id);});
        var cat=prod?prod.categoria_nombre:'General';
        if(!catMap[cat])catMap[cat]={categoria:cat,ingresos:0,costo_ventas:0,ganancia_bruta:0};
        var ingresos=(item.cantidad||1)*(item.precio_unitario||0);
        var costo=(item.cantidad||1)*(item.precio_compra||0);
        catMap[cat].ingresos+=ingresos;
        catMap[cat].costo_ventas+=costo;
        catMap[cat].ganancia_bruta+=ingresos-costo;
      });
    });

    // ventas por hora (basado en created_at)
    var horasMap={};
    for(var h=0;h<24;h++)horasMap[h]=0;
    ventasHoy.forEach(function(v){
      try{var hr=new Date(v.created_at||v.fecha).getHours();horasMap[hr]=(horasMap[hr]||0)+(v.total||0);}catch(e){}
    });
    var ventasPorHora=[];
    for(var h=0;h<24;h++){if(horasMap[h]>0){ventasPorHora.push({hora:h,total:horasMap[h]});}}

    // ventas por mes
    var mesesMap={};
    ventas.forEach(function(v){
      var m=(v.fecha||'').substring(0,7);
      if(m){mesesMap[m]=(mesesMap[m]||0)+(v.total||0);}
    });
    var ventasPorMes=Object.keys(mesesMap).sort().map(function(k){
      var parts=k.split('-');
      return{mes:parseInt(parts[1]||'1'),anio:parts[0],total:mesesMap[k]};
    });

    // stock bajo para tabla
    var stockBajoTabla=stockBajo.slice(0,10).map(function(p){return{producto:p.nombre,stock:p.stock_actual,stock_min:p.stock_minimo};});

    return{
      ventas_dia:ventasDia,ventas_dia_monto:ventasDiaMonto,ganancias_dia:gananciasDia,
      productos_stock:prods.length,valor_inventario:valorInv,
      stock_bajo:stockBajo.length,productos_agotados:agotados.length,
      clientes_deuda:clientes.filter(function(c){return(c.saldo_pendiente||0)>0;}).length,
      cuentas_bar:cuentasAbiertas,ventas_mes:ventasMesTotal,
      top_productos:topProductos,ventas_por_categoria:Object.values(catMap),
      ventas_por_hora:ventasPorHora,ventas_por_mes:ventasPorMes,
      stock_bajo_tabla:stockBajoTabla
    };
  },

  _handleCaja: function(method,parts,data){
    // parts[0]=caja, [1]=id or 'actual' or 'movimientos', etc
    var id=parts[1]||null;
    var action=parts[2]||null;

    if(method==='GET'&&id==='actual'){
      var abiertas=BridgeDB.get('cajas').filter(function(c){return c.estado==='abierta';});
      return abiertas.length>0?abiertas[0]:{id:null,estado:'cerrada'};
    }
    if(method==='GET'&&!id&&!action){
      var qp=this.currentQueryParams||{};
      if(qp.estado==='cerrada')return BridgeDB.get('cajas').filter(function(c){return c.estado==='cerrada';});
      return BridgeDB.get('cajas');
    }
    if(method==='GET'&&id&&action==='movimientos'){
      var movements = BridgeDB.get('movimientos_caja').filter(function(m){return String(m.caja_id)===String(id);});
      if ((!movements || movements.length === 0) && id) {
        var cajaObj = BridgeDB.getById('cajas', id);
        if (cajaObj && cajaObj.movimientos) {
          return cajaObj.movimientos;
        }
      }
      return movements;
    }
    if(method==='POST'&&!id){
      var cajaNeg=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      var montoInicial=(data||{}).monto_inicial!=null?data.monto_inicial:cajaNeg.balance||0;
      cajaNeg.balance=(cajaNeg.balance||0)-montoInicial;
      cajaNeg.balance_al_cierre=(cajaNeg.balance_al_cierre||0)-montoInicial;
      if(cajaNeg.balance<0)cajaNeg.balance=0;
      if(cajaNeg.balance_al_cierre<0)cajaNeg.balance_al_cierre=0;
      cajaNeg.updated_at=new Date().toISOString();
      BridgeDB._data.config_caja_negocio=cajaNeg;
      BridgeDB._save();
      return BridgeDB.create('cajas',{monto_inicial:montoInicial,estado:'abierta',fecha_apertura:new Date().toISOString(),ingresos:0,egresos:0});
    }
    if(method==='POST'&&id&&action==='movimiento'){
      var mov={caja_id:Number(id),tipo:(data||{}).tipo||'ingreso',concepto:(data||{}).concepto||'',monto:Number((data||{}).monto)||0,metodo_pago:(data||{}).metodo_pago||'efectivo',fecha:new Date().toISOString()};
      var result= BridgeDB.create('movimientos_caja',mov);
      var cajaAct=BridgeDB.getById('cajas',id);
      if(cajaAct){
        if(mov.tipo==='ingreso')cajaAct.ingresos=(cajaAct.ingresos||0)+mov.monto;
        else cajaAct.egresos=(cajaAct.egresos||0)+mov.monto;
        if(!cajaAct.movimientos) cajaAct.movimientos=[];
        cajaAct.movimientos.push(mov);
        BridgeDB.update('cajas',id,{ingresos:cajaAct.ingresos,egresos:cajaAct.egresos,total_ingresos:cajaAct.ingresos,total_egresos:cajaAct.egresos,movimientos:cajaAct.movimientos});
      }
      return result;
    }
    if(method==='PUT'&&id&&action==='movimiento'){
      var movId=(data||{}).movimiento_id||parts[3]||null;
      var cajaAct=BridgeDB.getById('cajas',id);
      if(!cajaAct)throw new Error('Caja no encontrada');
      var found=false;
      if(cajaAct.movimientos){
        for(var i=cajaAct.movimientos.length-1;i>=0;i--){
          if(String(cajaAct.movimientos[i].id)===String(movId)){
            cajaAct.movimientos[i].tipo=data.tipo||cajaAct.movimientos[i].tipo;
            cajaAct.movimientos[i].concepto=data.concepto||cajaAct.movimientos[i].concepto;
            cajaAct.movimientos[i].monto=Number(data.monto)||cajaAct.movimientos[i].monto;
            cajaAct.movimientos[i].metodo_pago=data.metodo_pago||cajaAct.movimientos[i].metodo_pago;
            found=true;break;
          }
        }
      }
      var allMovs=BridgeDB.get('movimientos_caja');
      for(var j=0;j<allMovs.length;j++){
        if(String(allMovs[j].id)===String(movId)){
          allMovs[j].tipo=data.tipo||allMovs[j].tipo;
          allMovs[j].concepto=data.concepto||allMovs[j].concepto;
          allMovs[j].monto=Number(data.monto)||allMovs[j].monto;
          allMovs[j].metodo_pago=data.metodo_pago||allMovs[j].metodo_pago;
          found=true;break;
        }
      }
      if(!found)throw new Error('Movimiento no encontrado');
      BridgeDB._save();
      var ingresosReales=(cajaAct.movimientos||[]).filter(function(m){return m.tipo==='ingreso';}).reduce(function(s,m){return s+(m.monto||0);},0);
      var egresosReales=(cajaAct.movimientos||[]).filter(function(m){return m.tipo!=='ingreso';}).reduce(function(s,m){return s+(m.monto||0);},0);
      BridgeDB.update('cajas',id,{ingresos:ingresosReales,egresos:egresosReales,total_ingresos:ingresosReales,total_egresos:egresosReales,movimientos:cajaAct.movimientos});
      return {success:true,ingresos:ingresosReales,egresos:egresosReales};
    }
    if(method==='DELETE'&&id&&action==='movimiento'){
      var movId=(data||{}).movimiento_id||parts[3]||null;
      var cajaAct=BridgeDB.getById('cajas',id);
      if(!cajaAct)throw new Error('Caja no encontrada');
      if(cajaAct.movimientos){
        cajaAct.movimientos=cajaAct.movimientos.filter(function(m){return String(m.id)!==String(movId);});
      }
      var allMovs=BridgeDB.get('movimientos_caja');
      BridgeDB._data.movimientos_caja=allMovs.filter(function(m){return String(m.id)!==String(movId);});
      BridgeDB._save();
      var ingresosReales=(cajaAct.movimientos||[]).filter(function(m){return m.tipo==='ingreso';}).reduce(function(s,m){return s+(m.monto||0);},0);
      var egresosReales=(cajaAct.movimientos||[]).filter(function(m){return m.tipo!=='ingreso';}).reduce(function(s,m){return s+(m.monto||0);},0);
      BridgeDB.update('cajas',id,{ingresos:ingresosReales,egresos:egresosReales,total_ingresos:ingresosReales,total_egresos:egresosReales,movimientos:cajaAct.movimientos});
      return {success:true,ingresos:ingresosReales,egresos:egresosReales};
    }
    if(method==='PUT'&&id&&action==='cerrar'){
      var cajaObj=BridgeDB.getById('cajas',id);
      if(!cajaObj)throw new Error('Caja no encontrada');
      var movements=BridgeDB.get('movimientos_caja').filter(function(m){return String(m.caja_id)===String(id);});
      if((!movements || movements.length === 0) && cajaObj.movimientos){
        movements = cajaObj.movimientos;
      }
      var ingresosReales=movements.filter(function(m){return m.tipo==='ingreso';}).reduce(function(s,m){return s+(m.monto||0);},0);
      var egresosReales=movements.filter(function(m){return m.tipo==='egreso';}).reduce(function(s,m){return s+(m.monto||0);},0);
      var openTimestamp=cajaObj.fecha_apertura||'';
      var allVentas=BridgeDB.get('ventas');
      console.log('CIERRE DIAG: cajaId='+id+', openTimestamp='+openTimestamp+', totalVentas='+allVentas.length);
      var sessionSales=allVentas.filter(function(v){
        var vCreated=v.created_at||v.fecha||'';
        var match=vCreated>=openTimestamp;
        if(match)console.log('CIERRE DIAG: venta match id='+v.id+', created_at='+vCreated+', total='+v.total+', items='+(v.items||[]).length);
        return match;
      });
      console.log('CIERRE DIAG: sessionSales count='+sessionSales.length);
      var totalCosto=0,totalVenta=0,totalDistribuido=0;
      sessionSales.forEach(function(v){
        if(v.metodo_pago==='fiado'){console.log('CIERRE DIAG: fiado skip id='+v.id);return;}
        totalVenta+=v.total||0;
        totalDistribuido+=(v.monto_distribuido||0);
        var costoItem=(v.items||[]).reduce(function(cSum,item){return cSum+(item.cantidad||1)*(item.precio_compra||0);},0);
        console.log('CIERRE DIAG: venta id='+v.id+', total='+v.total+', costoItem='+costoItem);
        totalCosto+=costoItem;
      });
      var totalConsumosCosto=0;
      var todosProds=BridgeDB.get('productos')||[];
      var sessionConsumos=(BridgeDB.get('autoconsumos')||[]).filter(function(c){
        return (c.fecha||'').substring(0,10) >= (openTimestamp||'').substring(0,10);
      });
      sessionConsumos.forEach(function(cons){
        var prod = todosProds.find(function(p){ return String(p.id)===String(cons.producto_id); });
        totalConsumosCosto += (cons.cantidad||0) * (prod ? (prod.precio_compra||0) : 0);
      });
      console.log('CIERRE DIAG: consumos encontrados='+sessionConsumos.length+', totalConsumosCosto='+totalConsumosCosto);
      var ganancias=totalVenta-totalCosto-totalConsumosCosto;
      console.log('CIERRE DIAG: totalVenta='+totalVenta+', totalCosto='+totalCosto+', ganancias='+ganancias);
      var esperado=(cajaObj.monto_inicial||0)+ingresosReales-egresosReales;
      var montoReal=(data||{}).monto_final_real||0;
      var diferencia=esperado-montoReal; // positivo=faltante, negativo=sobrante
      var updated=BridgeDB.update('cajas',id,{
        estado:'cerrada',fecha_cierre:new Date().toISOString(),
        monto_final_real:montoReal,
        ingresos:ingresosReales,egresos:egresosReales,
        esperado:esperado,diferencia:diferencia,
        ganancias:ganancias,capital_productos:totalCosto,
        consumos_propios:totalConsumosCosto,
        observaciones:(data||{}).observaciones||''
      });
      var cajaNeg2=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      cajaNeg2.balance=(cajaNeg2.balance||0)+(cajaObj.monto_inicial||0)+totalCosto-diferencia;
      cajaNeg2.ganancias_acumuladas=(cajaNeg2.ganancias_acumuladas||0)+ganancias;
      cajaNeg2.balance_al_cierre=cajaNeg2.balance;
      cajaNeg2.updated_at=new Date().toISOString();
      BridgeDB._data.config_caja_negocio=cajaNeg2;
      BridgeDB._save();
      return updated;
    }
    if(method==='PUT'&&id&&!action){
      var cajaObj=BridgeDB.getById('cajas',id);
      if(cajaObj && cajaObj.estado==='cerrada' && (data||{}).estado==='abierta'){
        // Revert config_caja_negocio
        var mi=cajaObj.monto_inicial||0;
        var cp=cajaObj.capital_productos||0;
        var dif=cajaObj.diferencia||0;
        var gan=cajaObj.ganancias||0;
        
        var cajaNeg=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
        cajaNeg.balance=(cajaNeg.balance||0)-(mi+cp-dif);
        cajaNeg.ganancias_acumuladas=(cajaNeg.ganancias_acumuladas||0)-gan;
        if(cajaNeg.balance<0)cajaNeg.balance=0;
        if(cajaNeg.ganancias_acumuladas<0)cajaNeg.ganancias_acumuladas=0;
        cajaNeg.balance_al_cierre=cajaNeg.balance;
        cajaNeg.updated_at=new Date().toISOString();
        
        BridgeDB._data.config_caja_negocio=cajaNeg;
        // Do NOT call _save here because BridgeDB.update below will trigger _save()!
        
        // Clear closure fields from the caja being reopened
        data.fecha_cierre=null;
        data.monto_final_real=null;
        data.ganancias=0;
        data.capital_productos=0;
        data.esperado=0;
        data.diferencia=0;
      }
      return BridgeDB.update('cajas',id,data||{});
    }
    if(method==='DEL'&&id&&!action)return BridgeDB.delete('cajas',id);
    return [];
  },

  _handleUsuarios: function(method,entId,sub,itemId,data){
    if(method==='GET'&&!entId&&!sub)return {usuarios:BridgeDB.get('usuarios')};
    if(method==='GET'&&entId&&!sub)return {usuario:BridgeDB.getById('usuarios',entId)};
    if(method==='GET'&&sub==='roles'&&!itemId)return {roles:BridgeDB.get('roles')};
    if(method==='GET'&&sub==='acciones')return {acciones:BridgeDB.get('user_actions')};
    if(method==='GET'&&entId&&sub==='permisos'){
      var perm= BridgeDB.getById('usuarios',entId);
      return perm?{permiso_ids:perm.permiso_ids||[]}:{permiso_ids:[]};
    }
    if(method==='GET'&&sub==='permisos')return {permisos:BridgeDB.get('permisos')};
    if(method==='GET'&&sub==='roles'&&entId&&itemId==='permisos'){
      var rol=BridgeDB.getById('roles',entId);
      return rol?{permiso_ids:rol.permiso_ids||[]}:{permiso_ids:[]};
    }
    if(method==='POST'&&!entId){
      var newUser=BridgeDB.create('usuarios',data);
      return {usuario:newUser};
    }
    if(method==='POST'&&sub==='roles'){
      var newRol=BridgeDB.create('roles',data);
      return {rol:newRol};
    }
    if(method==='PUT'&&entId&&sub==='permisos'){
      return BridgeDB.update('usuarios',entId,{permiso_ids:data.permiso_ids||[]});
    }
    if(method==='PUT'&&sub==='roles'&&entId&&itemId==='permisos'){
      return BridgeDB.update('roles',entId,{permiso_ids:data.permiso_ids||[]});
    }
    if(method==='PUT'&&entId)return BridgeDB.update('usuarios',entId,data);
    if(method==='DEL'&&entId)return BridgeDB.delete('usuarios',entId);
    return null;
  },

  _handleClientes: function(method,parts,data){
    var id=parts[1]||null;
    var action=parts[2]||null;
    if(method==='GET'&&id&&action==='historial'){
      var cli=BridgeDB.getById('clientes',id);
      if(!cli)return{fiados:[],ventas:[],abonos:[],cliente:null};
      var fiadosCli=BridgeDB.get('fiados').filter(function(f){return String(f.cliente_id)===String(id);});
      var ventasCli=BridgeDB.get('ventas').filter(function(v){return String(v.cliente_id)===String(id);});
      var abonosCli=BridgeDB.get('fiado_abonos').filter(function(a){return String(a.cliente_id)===String(id);});
      return {fiados:fiadosCli,ventas:ventasCli,abonos:abonosCli,cliente:cli};
    }
    if(method==='GET'&&id)return BridgeDB.getById('clientes',id);
    if(method==='GET'){
      if(this.currentQueryParams && this.currentQueryParams.nombre){
        var nameQ = this.currentQueryParams.nombre.trim().toLowerCase();
        return BridgeDB.get('clientes').filter(function(c){
          return (c.nombre||'').trim().toLowerCase() === nameQ;
        });
      }
      return BridgeDB.get('clientes');
    }
    if(method==='POST'){
      var nameClean = (data.nombre||'').trim().toLowerCase();
      var existing = BridgeDB.get('clientes').find(function(c){
        return (c.nombre||'').trim().toLowerCase() === nameClean;
      });
      if(existing) return existing;
      var cMax = data.credito_maximo != null ? data.credito_maximo : (data.creditoMaximo != null ? data.creditoMaximo : 0);
      var sPend = data.saldo_pendiente != null ? data.saldo_pendiente : (data.saldoPendiente != null ? data.saldoPendiente : 0);
      var cliente = BridgeDB.create('clientes',{
        nombre:(data.nombre||'').trim(),
        telefono:data.telefono||'',
        email:data.email||'',
        direccion:data.direccion||'',
        tipo:data.tipo||'Ocasional',
        credito_maximo:cMax,
        creditoMaximo:cMax,
        saldo_pendiente:sPend,
        saldoPendiente:sPend,
        numero_documento:data.numero_documento||'',
        observaciones:data.observaciones||''
      });
      if(sPend > 0){
        BridgeDB.create('fiados',{
          cliente_id:cliente.id,
          monto_original:sPend,
          monto_pendiente:sPend,
          saldo:sPend,
          monto:sPend,
          fecha:Helpers.today(),
          estado:'Pendiente',
          detalle:'Saldo inicial / Deuda anterior cargada'
        });
      }
      return cliente;
    }
    if(method==='PUT'&&id){
      if(data.creditoMaximo !== undefined) data.credito_maximo = data.creditoMaximo;
      if(data.credito_maximo !== undefined) data.creditoMaximo = data.credito_maximo;
      if(data.saldoPendiente !== undefined) data.saldo_pendiente = data.saldoPendiente;
      if(data.saldo_pendiente !== undefined) data.saldoPendiente = data.saldo_pendiente;
      return BridgeDB.update('clientes',id,data);
    }
    if(method==='DEL'&&id){
      var allFiados = BridgeDB.get('fiados') || [];
      var deletedFiados = allFiados.filter(function(f){ return String(f.cliente_id) === String(id); });
      var remainingFiados = allFiados.filter(function(f){ return String(f.cliente_id) !== String(id); });
      BridgeDB._data.fiados = remainingFiados;
      BridgeDB._save('fiados');

      var allAbonos = BridgeDB.get('fiado_abonos') || [];
      var deletedAbonos = allAbonos.filter(function(a){ return String(a.cliente_id) === String(id); });
      var remainingAbonos = allAbonos.filter(function(a){ return String(a.cliente_id) !== String(id); });
      BridgeDB._data.fiado_abonos = remainingAbonos;
      BridgeDB._save('fiado_abonos');

      // Record deletion logs to prevent resurrection during Firestore sync
      BridgeDB._data.deletions = BridgeDB._data.deletions || [];
      deletedFiados.forEach(function(f) {
        var delId = 'fiados_' + f.id;
        if (!BridgeDB._data.deletions.some(function(d){ return d.id === delId; })) {
          BridgeDB._data.deletions.push({ id: delId, col: 'fiados', target_id: f.id, deleted_at: new Date().toISOString() });
        }
      });
      deletedAbonos.forEach(function(a) {
        var delId = 'fiado_abonos_' + a.id;
        if (!BridgeDB._data.deletions.some(function(d){ return d.id === delId; })) {
          BridgeDB._data.deletions.push({ id: delId, col: 'fiado_abonos', target_id: a.id, deleted_at: new Date().toISOString() });
        }
      });
      BridgeDB._save('deletions');

      return BridgeDB.delete('clientes',id);
    }
    return null;
  },

  _handleFiados: function(method,parts,data){
    var action=parts[1]||null;
    var entId=parts[2]||null;
    var sub=parts[3]||null;

    if(method==='GET'&&action==='cliente'&&entId){
      return BridgeDB.get('fiados').filter(function(f){return String(f.cliente_id)===String(entId);});
    }
    if(method==='GET'&&action==='abonos'&&entId){
      return BridgeDB.get('fiado_abonos').filter(function(a){return String(a.cliente_id)===String(entId);});
    }
    if(method==='GET'&&action==='abonos'){
      return BridgeDB.get('fiado_abonos');
    }
    if(method==='GET'){
      return BridgeDB.get('fiados');
    }
    if(method==='POST'&&action==='abono'){
      var clienteId=data.cliente_id;
      var fiadoIds=data.fiado_ids||[];
      var montoTotal=Number(data.monto_total)||0;
      var tipo=data.tipo_amortizacion||'manual';
      var fiadosCliente=BridgeDB.get('fiados').filter(function(f){
        return String(f.cliente_id)===String(clienteId)&&(f.estado==='pendiente'||f.estado==='Pendiente');
      });
      if(fiadoIds.length===0&&fiadosCliente.length===1){
        fiadoIds=[fiadosCliente[0].id];
        montoTotal=montoTotal||(fiadosCliente[0].saldo||fiadosCliente[0].monto_pendiente||fiadosCliente[0].monto||0);
      }
      // Create abono record
      var abono=BridgeDB.create('fiado_abonos',{
        cliente_id:clienteId,fiado_ids:fiadoIds,monto:montoTotal,
        fecha:Helpers.today(),tipo_amortizacion:tipo
      });
      // Apply payment to fiados
      var remaining=montoTotal;
      var targets=fiadosCliente.slice();
      if(tipo==='lifo'){
        targets.sort(function(a,b){var c=(b.fecha||'')>(a.fecha||'')?1:(b.fecha||'')<(a.fecha||'')?-1:0;return c!==0?c:(Number(b.id)||0)-(Number(a.id)||0);});
      }else{
        targets.sort(function(a,b){var c=(a.fecha||'')>(b.fecha||'')?1:(a.fecha||'')<(b.fecha||'')?-1:0;return c!==0?c:(Number(a.id)||0)-(Number(b.id)||0);});
      }
      for(var i=0;i<targets.length&&remaining>0;i++){
        var f=targets[i];
        if(fiadoIds.length>0&&fiadoIds.indexOf(f.id)===-1&&fiadoIds.indexOf(String(f.id))===-1)continue;
        var pend=Number(f.saldo||f.monto_pendiente||f.monto||0);
        if(pend<=0)continue;
        var pay=Math.min(pend,remaining);
        var newSaldo=pend-pay;
        BridgeDB.update('fiados',f.id,{
          saldo:newSaldo,monto_pendiente:newSaldo,saldoPendiente:newSaldo,
          estado:newSaldo<=0?'Pagado':'Pendiente'
        });
        remaining-=pay;
      }
      // Recalculate total client debt
      var allFiados=BridgeDB.get('fiados');
      var totalDeuda=allFiados.filter(function(f){
        return String(f.cliente_id)===String(clienteId)&&(f.estado||'')!=='Pagado';
      }).reduce(function(s,f){return s+(Number(f.saldo||f.monto_pendiente||f.monto||0));},0);
      BridgeDB.update('clientes',clienteId,{saldo_pendiente:totalDeuda});
      // Add money to caja negocio (cash received from credit payment)
      var cajaN=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      cajaN.balance=(cajaN.balance||0)+montoTotal;
      cajaN.balance_al_cierre=(cajaN.balance_al_cierre||0)+montoTotal;
      cajaN.updated_at=new Date().toISOString();
      BridgeDB._data.config_caja_negocio=cajaN;
      BridgeDB._save();
      // Payments go directly to caja negocio, not open daily caja
      /*
      var caAb=BridgeDB.get('cajas').filter(function(c){return c.estado==='abierta';});
      if(caAb.length>0){
        BridgeDB.create('movimientos_caja',{
          caja_id:caAb[0].id,tipo:'ingreso',
          concepto:'Abono Fiado - Cliente #'+clienteId,
          monto:montoTotal,metodo_pago:'efectivo'
        });
        caAb[0].ingresos=(caAb[0].ingresos||0)+montoTotal;
        BridgeDB.update('cajas',caAb[0].id,{ingresos:caAb[0].ingresos});
      }
      */
      return abono;
    }
    if(method==='POST'){
      var fiado = BridgeDB.create('fiados',data);
      if(data.cliente_id){
        var allFiados=BridgeDB.get('fiados');
        var totalDeuda=allFiados.filter(function(f){
          return String(f.cliente_id)===String(data.cliente_id)&&(f.estado||'')!=='Pagado';
        }).reduce(function(s,f){return s+(Number(f.saldo||f.monto_pendiente||f.monto||0));},0);
        BridgeDB.update('clientes',data.cliente_id,{saldo_pendiente:totalDeuda, saldoPendiente:totalDeuda});
      }
      return fiado;
    }
    if(method==='PUT'&&action){
      var res = BridgeDB.update('fiados',action,data);
      if(res && res.cliente_id){
        var allFiados=BridgeDB.get('fiados');
        var totalDeuda=allFiados.filter(function(f){
          return String(f.cliente_id)===String(res.cliente_id)&&(f.estado||'')!=='Pagado';
        }).reduce(function(s,f){return s+(Number(f.saldo||f.monto_pendiente||f.monto||0));},0);
        BridgeDB.update('clientes',res.cliente_id,{saldo_pendiente:totalDeuda, saldoPendiente:totalDeuda});
      }
      return res;
    }
    if(method==='DEL'&&action){
      var old = BridgeDB.getById('fiados',action);
      var res = BridgeDB.delete('fiados',action);
      if(old && old.cliente_id){
        var allFiados=BridgeDB.get('fiados');
        var totalDeuda=allFiados.filter(function(f){
          return String(f.cliente_id)===String(old.cliente_id)&&(f.estado||'')!=='Pagado';
        }).reduce(function(s,f){return s+(Number(f.saldo||f.monto_pendiente||f.monto||0));},0);
        BridgeDB.update('clientes',old.cliente_id,{saldo_pendiente:totalDeuda, saldoPendiente:totalDeuda});
      }
      return res;
    }
    return null;
  },

  _handleDistribuciones: function(method,parts,data){
    var action=parts[1]||null;
    var entId=parts[2]||null;
    var sub=parts[3]||null;

    if(method==='GET'&&action==='balance'){
      var cajaN=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      console.log('BALANCE DIAG: config_caja_negocio type='+typeof cajaN+', isArray='+Array.isArray(cajaN)+', keys='+Object.keys(cajaN).join(','));
      console.log('BALANCE DIAG: balance='+cajaN.balance+', balance_al_cierre='+cajaN.balance_al_cierre+', ganancias_acum='+cajaN.ganancias_acumuladas);
      // Recalculate from closed cajas to ensure correctness if config_caja_negocio seems wrong
      var cajasCerradas = BridgeDB.get('cajas').filter(function(c){return c.estado==='cerrada'&&c.ganancias!=null;});
      cajasCerradas.sort(function(a,b){return (a.fecha_cierre||'')>(b.fecha_cierre||'')?1:-1;});
      var balanceCalc=0, gananciasCalc=0;
      cajasCerradas.forEach(function(c){
        balanceCalc=Math.max(0,balanceCalc-(c.monto_inicial||0));
        balanceCalc+=(c.monto_inicial||0)+(c.capital_productos||0)-(c.diferencia||0);
        gananciasCalc+=c.ganancias||0;
      });
      // Add fiado abonos (cash payments go directly to caja negocio balance)
      var abonos = BridgeDB.get('fiado_abonos')||[];
      abonos.forEach(function(a){balanceCalc+=a.monto||0;});
      // Subtract distributions made
      var dists = BridgeDB.get('distribuciones')||[];
      dists.forEach(function(d){
        if(d.tipo==='distribucion'||d.tipo==='distribucion_facturacion'){
          gananciasCalc-=(d.total||0);
        }
      });
      console.log('BALANCE DIAG: recalculated from cierres: balance='+balanceCalc+', ganancias='+gananciasCalc);
      var distBalance;
      if(!cajaN.balance_al_cierre && (balanceCalc>0 || (cajaN.balance||0)>0)){
        distBalance=balanceCalc>0?balanceCalc:(cajaN.balance||0);
        cajaN.ganancias_acumuladas=gananciasCalc>0?gananciasCalc:(cajaN.ganancias_acumuladas||0);
        cajaN.balance=distBalance;
        cajaN.balance_al_cierre=distBalance;
        BridgeDB._data.config_caja_negocio=cajaN;
        BridgeDB._save();
      }else{
        distBalance=(cajaN.balance_al_cierre!=null)?cajaN.balance_al_cierre:(cajaN.balance||0);
      }
      return {balance:distBalance,ganancias_acumuladas:cajaN.ganancias_acumuladas||0};
    }
    if(method==='GET'&&action==='categorias'){
      return BridgeDB.get('distribuciones_categorias');
    }
    if(method==='GET'&&!action){
      return BridgeDB.get('distribuciones');
    }
    if(method==='POST'&&action==='categorias'){
      return BridgeDB.create('distribuciones_categorias',data);
    }
    if(method==='POST'&&action==='realizar'){
      var items=data.items||[];
      var total=items.reduce(function(s,x){return s+(x.monto||0);},0);
      var cajaN2=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      if(total>(cajaN2.ganancias_acumuladas||0))throw new Error('Total excede ganancias acumuladas disponibles');
      var distribucion={tipo:'distribucion',fecha:Helpers.today(),items:items,total:total,created_at:new Date().toISOString()};
      var result= BridgeDB.create('distribuciones',distribucion);
      cajaN2.ganancias_acumuladas=(cajaN2.ganancias_acumuladas||0)-total;
      if(cajaN2.ganancias_acumuladas<0)cajaN2.ganancias_acumuladas=0;
      cajaN2.updated_at=new Date().toISOString();
      BridgeDB._data.config_caja_negocio=cajaN2;
      BridgeDB._save();
      return result;
    }
    if(method==='POST'&&action==='facturacion'){
      var itemsF=data.items||[];
      var totalF=itemsF.reduce(function(s,x){return s+(x.monto||0);},0);
      var distribucionF={tipo:'distribucion_facturacion',fecha:Helpers.today(),items:itemsF,total:totalF,created_at:new Date().toISOString()};
      return BridgeDB.create('distribuciones',distribucionF);
    }
    if(method==='POST'&&action==='ajustar'){
      var monto=Number(data.monto)||0;
      if(monto===0)return null;
      var cajaN3=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      cajaN3.ganancias_acumuladas=(cajaN3.ganancias_acumuladas||0)+monto;
      if(cajaN3.ganancias_acumuladas<0)cajaN3.ganancias_acumuladas=0;
      cajaN3.updated_at=new Date().toISOString();
      BridgeDB._data.config_caja_negocio=cajaN3;
      BridgeDB._save();
      return {ok:true};
    }
    if(method==='POST'&&action==='ingresar-capital'){
      var monto=Number(data.monto)||0;
      var motivo=data.motivo||'Ingreso de Capital';
      if(monto<=0) throw new Error('El monto debe ser mayor a 0');
      var cajaN=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      cajaN.balance=(cajaN.balance||0)+monto;
      cajaN.balance_al_cierre=(cajaN.balance_al_cierre||0)+monto;
      cajaN.updated_at=new Date().toISOString();
      BridgeDB._data.config_caja_negocio=cajaN;
      BridgeDB._save();
      return {ok:true, balance:cajaN.balance_al_cierre, ganancias_acumuladas:cajaN.ganancias_acumuladas};
    }
    if(method==='POST'&&action==='transferir-fondos'){
      var monto=Number(data.monto)||0;
      var origen=data.origen; // 'ganancias' or 'caja_negocio'
      if(monto<=0) throw new Error('El monto debe ser mayor a 0');
      var cajaN=BridgeDB.getConfigCajaNegocio()||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      if(origen==='ganancias'){
        if(monto>(cajaN.ganancias_acumuladas||0)) throw new Error('El monto supera las ganancias acumuladas');
        cajaN.ganancias_acumuladas=(cajaN.ganancias_acumuladas||0)-monto;
        cajaN.balance=(cajaN.balance||0)+monto;
        cajaN.balance_al_cierre=(cajaN.balance_al_cierre||0)+monto;
      } else if(origen==='caja_negocio'){
        var distBalance=(cajaN.balance_al_cierre!=null)?cajaN.balance_al_cierre:(cajaN.balance||0);
        if(monto>distBalance) throw new Error('El monto supera el balance de la caja negocio');
        cajaN.balance=(cajaN.balance||0)-monto;
        cajaN.balance_al_cierre=(cajaN.balance_al_cierre||0)-monto;
        cajaN.ganancias_acumuladas=(cajaN.ganancias_acumuladas||0)+monto;
      } else {
        throw new Error('Origen de transferencia no válido');
      }
      if(cajaN.balance<0)cajaN.balance=0;
      if(cajaN.balance_al_cierre<0)cajaN.balance_al_cierre=0;
      if(cajaN.ganancias_acumuladas<0)cajaN.ganancias_acumuladas=0;
      cajaN.updated_at=new Date().toISOString();
      BridgeDB._data.config_caja_negocio=cajaN;
      BridgeDB._save();
      return {ok:true, balance:cajaN.balance_al_cierre, ganancias_acumuladas:cajaN.ganancias_acumuladas};
    }
    if(method==='PUT'&&action){
      return BridgeDB.update('distribuciones',action,data);
    }
    if(method==='DEL'&&action==='categorias'&&entId){
      return BridgeDB.delete('distribuciones_categorias',entId);
    }
    if(method==='DEL'&&action){
      return BridgeDB.delete('distribuciones',action);
    }
    return null;
  },

  _handleHistorialVentas: function(method,id,data){
    if(method==='GET'&&!id){
      var qp=this.currentQueryParams||{};
      var ventas=BridgeDB.get('ventas');
      if(qp.desde)ventas=ventas.filter(function(v){return(v.fecha||'')>=qp.desde;});
      if(qp.hasta)ventas=ventas.filter(function(v){return(v.fecha||'')<=qp.hasta;});
      if(qp.estado)ventas=ventas.filter(function(v){return v.estado===qp.estado;});
      return ventas.sort(function(a,b){return(b.fecha||'')>(a.fecha||'')?1:-1;});
    }
    if(method==='GET'&&id)return BridgeDB.getById('ventas',id);
    if(method==='PUT'&&id){
      var oldV=BridgeDB.getById('ventas',id);
      if(!oldV)throw new Error('Venta no encontrada');
      var oldTotal=oldV.total||0;
      // 1. REVERT old stock
      (oldV.items||[]).forEach(function(item){
        if(item.producto_id){
          var p=BridgeDB.getById('productos',item.producto_id);
          if(p)BridgeDB.update('productos',p.id,{stock_actual:(p.stock_actual||0)+(item.cantidad||1)});
        }
      });
      // 2. REVERT old caja income (only if caja still open)
      if(oldV.metodo_pago!=='fiado'){
        var cAb=BridgeDB.get('cajas').filter(function(c){return c.estado==='abierta';});
        if(cAb.length>0){
          cAb[0].ingresos=Math.max(0,(cAb[0].ingresos||0)-oldTotal);
          BridgeDB.update('cajas',cAb[0].id,{ingresos:cAb[0].ingresos});
        }
      }
      // 3. REVERT old fiado debt
      if(oldV.metodo_pago==='fiado'&&oldV.cliente_id){
        var cOld=BridgeDB.getById('clientes',oldV.cliente_id);
        if(cOld)BridgeDB.update('clientes',cOld.id,{saldo_pendiente:Math.max(0,(cOld.saldo_pendiente||0)-oldTotal)});
        // Remove fiado records for this venta
        var allF=BridgeDB.get('fiados').filter(function(f){return String(f.venta_id)!==String(id);});
        BridgeDB._data.fiados=allF;
      }
      // 4. APPLY new stock and calculate new total
      var newData=data||{};
      var newItems=newData.items||[];
      var newTotal=0,newTotalCosto=0;
      newItems.forEach(function(item){
        var cant=Number(item.cantidad||1);
        var pUnit=Number(item.precio_unitario||0);
        newTotal+=cant*pUnit;
        if(item.producto_id){
          var prod=BridgeDB.getById('productos',item.producto_id);
          if(prod){
            var pCompra=Number(item.precio_compra||prod.precio_compra||0);
            newTotalCosto+=cant*pCompra;
            BridgeDB.update('productos',prod.id,{stock_actual:Math.max(0,(prod.stock_actual||0)-cant)});
          }
        }
      });
      // 5. APPLY new caja income
      if(newData.metodo_pago!=='fiado'&&newTotal>0){
        var cAb2=BridgeDB.get('cajas').filter(function(c){return c.estado==='abierta';});
        if(cAb2.length>0){
          cAb2[0].ingresos=(cAb2[0].ingresos||0)+newTotal;
          BridgeDB.update('cajas',cAb2[0].id,{ingresos:cAb2[0].ingresos});
        }
      }
      // 6. APPLY new fiado debt
      if(newData.metodo_pago==='fiado'&&newData.cliente_id&&newTotal>0){
        var cNew=BridgeDB.getById('clientes',newData.cliente_id);
        if(cNew)BridgeDB.update('clientes',cNew.id,{saldo_pendiente:(cNew.saldo_pendiente||0)+newTotal});
        newItems.forEach(function(item){
          BridgeDB.create('fiados',{
            cliente_id:newData.cliente_id,venta_id:id,
            producto_id:item.producto_id,producto_nombre:item.nombre||'',
            cantidad:item.cantidad||1,
            monto_original:(item.cantidad||1)*(item.precio_unitario||0),
            monto:(item.cantidad||1)*(item.precio_unitario||0),
            saldo:(item.cantidad||1)*(item.precio_unitario||0),
            estado:'Pendiente',fecha:newData.fecha||new Date().toISOString().split('T')[0],
            empleado_autorizo:'Admin'
          });
        });
      }
      newData.total_costo=newTotalCosto;
      newData.total=newTotal;
      newData.subtotal=newTotal;
      return BridgeDB.update('ventas',id,newData);
    }
    if(method==='DEL'&&id){
      var ventaDel=BridgeDB.getById('ventas',id);
      if(!ventaDel)throw new Error('Venta no encontrada');
      var delTotal=ventaDel.total||0;
      // 1. REVERT stock
      (ventaDel.items||[]).forEach(function(item){
        if(item.producto_id){
          var p=BridgeDB.getById('productos',item.producto_id);
          if(p)BridgeDB.update('productos',p.id,{stock_actual:(p.stock_actual||0)+(item.cantidad||1)});
        }
      });
      // 2. REVERT caja income
      if(ventaDel.metodo_pago!=='fiado'){
        var cAbD=BridgeDB.get('cajas').filter(function(c){return c.estado==='abierta';});
        if(cAbD.length>0){
          cAbD[0].ingresos=Math.max(0,(cAbD[0].ingresos||0)-delTotal);
          BridgeDB.update('cajas',cAbD[0].id,{ingresos:cAbD[0].ingresos});
        }
      }
      // 3. REVERT fiado debt
      if(ventaDel.metodo_pago==='fiado'&&ventaDel.cliente_id){
        var cD=BridgeDB.getById('clientes',ventaDel.cliente_id);
        if(cD)BridgeDB.update('clientes',cD.id,{saldo_pendiente:Math.max(0,(cD.saldo_pendiente||0)-delTotal)});
        BridgeDB._data.fiados=(BridgeDB.get('fiados')||[]).filter(function(f){return String(f.venta_id)!==String(id);});
      }
      return BridgeDB.delete('ventas',id);
    }
    return null;
  },

  _handleReportes: function(method,tab,id,data){
    var qp=this.currentQueryParams||{};
    if(tab==='ventas'){
      var desde=qp.desde||'',hasta=qp.hasta||'';
      var ventas=BridgeDB.get('ventas').filter(function(v){
        var f=v.fecha||'';
        return (!desde||f>=desde)&&(!hasta||f<=hasta);
      });
      return ventas.sort(function(a,b){return(b.fecha||'')>(a.fecha||'')?1:-1;});
    }
    if(tab==='ganancias'){
      var desdeG=qp.desde||'',hastaG=qp.hasta||'';
      var ventasG=BridgeDB.get('ventas').filter(function(v){
        var f=v.fecha||'';
        return (!desdeG||f>=desdeG)&&(!hastaG||f<=hastaG);
      });
      var catMap={};
      var prods=BridgeDB.get('productos');
      ventasG.forEach(function(v){
        (v.items||[]).forEach(function(item){
          var prod=prods.find(function(p){return String(p.id)===String(item.producto_id);});
          var cat=prod?prod.categoria_nombre:'General';
          if(!catMap[cat])catMap[cat]={categoria:cat,ingresos:0,costo_ventas:0,ganancia_bruta:0};
          var ing=(item.cantidad||1)*(item.precio_unitario||0);
          var cos=(item.cantidad||1)*(item.precio_compra||0);
          catMap[cat].ingresos+=ing;
          catMap[cat].costo_ventas+=cos;
          catMap[cat].ganancia_bruta+=ing-cos;
        });
      });
      return Object.values(catMap);
    }
    if(tab==='inventario'){
      var prodsI=BridgeDB.get('productos');
      var valorCosto=prodsI.reduce(function(s,p){return s+(p.stock_actual||0)*(p.precio_compra||0);},0);
      var valorVenta=prodsI.reduce(function(s,p){return s+(p.stock_actual||0)*(p.precio_venta||0);},0);
      return{
        resumen:{valor_total_costo:valorCosto,valor_total_venta:valorVenta,ganancia_potencial:valorVenta-valorCosto},
        productos:prodsI
      };
    }
    if(tab==='fiados'){
      var desdeF=qp.desde||'',hastaF=qp.hasta||'';
      var fiados=BridgeDB.get('fiados').filter(function(f){
        var d=f.fecha||'';
        return (!desdeF||d>=desdeF)&&(!hastaF||d<=hastaF);
      });
      return fiados.map(function(f){return {fecha:f.fecha,cliente_nombre:f.detalle||'',monto:f.monto_original||0,estado:f.estado};});
    }
    if(tab==='caja'){
      var desdeC=qp.desde||'',hastaC=qp.hasta||'';
      var cajas=BridgeDB.get('cajas').filter(function(c){
        var d=c.fecha_apertura||'';
        return (!desdeC||d>=desdeC)&&(!hastaC||d<=hastaC);
      });
      return cajas.map(function(c){return {fecha:c.fecha_apertura,monto_inicial:c.monto_inicial,ingresos:c.ingresos,egresos:c.egresos,ganancias:c.ganancias,total:c.monto_final_real};});
    }
    if(tab==='distribuciones'){
      var desdeD=qp.desde||'',hastaD=qp.hasta||'';
      var dists=BridgeDB.get('distribuciones').filter(function(d){
        var f=d.fecha||'';
        return (!desdeD||f>=desdeD)&&(!hastaD||f<=hastaD);
      });
      return dists.map(function(d){
        return {
          fecha:d.fecha||d.created_at,tipo:d.tipo||'distribucion',
          ganancia_neta:d.total||0,gastos_operativos:0,
          saldo_distribuible:d.total||0,observaciones:d.observaciones||'',
          items:d.items,id:d.id
        };
      });
    }
    if(tab==='ganancianeta'){
      var desdeGN=qp.desde||'',hastaGN=qp.hasta||'';
      var ventasGN=BridgeDB.get('ventas').filter(function(v){
        var f=v.fecha||'';return (!desdeGN||f>=desdeGN)&&(!hastaGN||f<=hastaGN);
      });
      var ventasBruto=ventasGN.reduce(function(s,v){return s+(v.total||0);},0);
      var costoVentas=ventasGN.reduce(function(s,v){
        return s+(v.items||[]).reduce(function(csi,it){return csi+(it.cantidad||1)*(it.precio_compra||0);},0);
      },0);
      var distsGN=BridgeDB.get('distribuciones').filter(function(d){
        var f=d.fecha||'';return (!desdeGN||f>=desdeGN)&&(!hastaGN||f<=hastaGN);
      });
      var distTotal=distsGN.reduce(function(s,d){return s+(d.total||0);},0);
      var comprasGN=BridgeDB.get('compras').filter(function(c){
        var f=c.fecha||'';return (!desdeGN||f>=desdeGN)&&(!hastaGN||f<=hastaGN)&&c.pagado;
      });
      var gastosOp=comprasGN.reduce(function(s,c){return s+(c.total||0);},0);
      return {ventas_bruto:ventasBruto,costo_ventas:costoVentas,gastos_operativos:gastosOp,distribuciones:distTotal};
    }
    if(tab==='consumos'){
      var desdeCo=qp.desde||'',hastaCo=qp.hasta||'';
      var consumos=BridgeDB.get('autoconsumos')||[];
      var filtered=consumos.filter(function(c){
        var f=c.fecha||'';
        return (!desdeCo||f>=desdeCo)&&(!hastaCo||f<=hastaCo);
      });
      var prodsCo=BridgeDB.get('productos');
      var totalCantidad=0,totalCosto=0;
      var prodMap={};
      filtered.forEach(function(c){
        var prod=prodsCo.find(function(p){return String(p.id)===String(c.producto_id);});
        var costo=(c.cantidad||0)*(prod?prod.precio_compra||0:0);
        totalCantidad+=c.cantidad||0;
        totalCosto+=costo;
        var key=c.producto_nombre||'Sin nombre';
        if(!prodMap[key])prodMap[key]={nombre:key,cantidad:0,costo:0};
        prodMap[key].cantidad+=c.cantidad||0;
        prodMap[key].costo+=costo;
      });
      var productos_top=Object.values(prodMap).sort(function(a,b){return b.cantidad-a.cantidad;}).slice(0,15);
      return {
        consumos: filtered,
        resumen: {
          total_unidades: totalCantidad,
          costo_total: totalCosto,
          total_registros: filtered.length,
          productos_top: productos_top
        }
      };
    }
    return [];
  },

  _calcBarTotals: function(prods){
    var total=0,count=0;
    for(var i=0;i<prods.length;i++){
      if(!prods[i].pagado){
        count++;
        total+=prods[i].subtotal||((prods[i].cantidad||1)*(prods[i].precio_unitario||0));
      }
    }
    return {total:total,count:count};
  },

  _handleSync: async function(method,action,data){
    if(method==='GET'&&action==='status'){
      var db=BridgeDB._getFirestore();
      return {conectado:!!db,ultima_sincronizacion:BridgeDB._data._meta?BridgeDB._data._meta.updated_at:null};
    }
    if(method==='GET'&&action==='update-files'){
      var dbUf=BridgeDB._getFirestore();
      if(!dbUf)return [];
      return dbUf.collection('update_files').get().then(function(snap){
        var files=[];
        snap.forEach(function(doc){
          var d=doc.data();
          if(d.filename&&d.content!=null) files.push({filename:d.filename,content:d.content});
        });
        return files;
      }).catch(function(){return [];});
    }
    if(method==='GET'&&action==='check-update'){
      var dbCu=BridgeDB._getFirestore();
      var actual = (typeof window !== 'undefined' && window.APP_VERSION) || '3.1.7';
      if(!dbCu)return {hay_actualizacion:false,version_actual:actual};
      return dbCu.collection('datos').doc('config_app').get().then(function(doc){
        if(!doc.exists)return {hay_actualizacion:false,version_actual:actual};
        var d=doc.data();var nueva=d.version||actual;
        var hayAct=false;
        if(nueva!==actual){
          var p1=String(nueva).split('.').map(Number);
          var p2=String(actual).split('.').map(Number);
          for(var vi=0;vi<Math.max(p1.length,p2.length);vi++){
            var n1=p1[vi]||0,n2=p2[vi]||0;
            if(n1>n2){hayAct=true;break;}
            if(n1<n2)break;
          }
        }
        return {hay_actualizacion:hayAct,version_actual:actual,version_nueva:nueva,mensaje:d.mensaje||'',forzar:d.forzar||false,release_date:d.release_date||''};
      }).catch(function(){return {hay_actualizacion:false,version_actual:actual};});
    }
    if(method==='POST'&&action==='upload'){
      var dbU=BridgeDB._getFirestore();
      if(!dbU)throw new Error('Firebase no disponible');
      var colls=['categorias','productos','clientes','proveedores','ventas','cajas','movimientos_caja','fiados','fiado_abonos','user_actions','compras','compras_programadas','autoconsumos','visitas_proveedor','distribuciones','distribuciones_categorias','ventas_bar_cuentas','ventas_bar_categorias','ventas_bar_productos','cotizaciones','permisos','roles','usuarios'];
      var total=0;
      
      // First, write to backup_* docs (old behavior)
      var batch=dbU.batch();
      var batchCount=0;
      for(var ci=0;ci<colls.length;ci++){
        var col=colls[ci];
        var arr=BridgeDB._data[col]||[];
        batch.set(dbU.collection('datos').doc('backup_'+col),{lista:arr,updated_at:new Date().toISOString()},{merge:true});
        total+=arr.length;
        batchCount++;
        if(batchCount>=200){await batch.commit();batch=dbU.batch();batchCount=0;}
      }
      var cfg=BridgeDB._data.config_caja_negocio||{balance:0,ganancias_acumuladas:0,balance_al_cierre:0};
      batch.set(dbU.collection('datos').doc('backup_config_caja_negocio'),cfg,{merge:true});
      total++;
      batchCount++;
      if(batchCount>0)await batch.commit();
      
      // Also write to live collection docs (datos/productos, datos/clientes, etc.)
      // so data is immediately available to other PCs via sync
      var liveBatch=dbU.batch();
      var liveCount=0;
      for(var ci2=0;ci2<colls.length;ci2++){
        var col2=colls[ci2];
        var arr2=BridgeDB._data[col2]||[];
        liveBatch.set(dbU.collection('datos').doc(col2),{lista:arr2,updated_at:new Date().toISOString()},{merge:true});
        liveCount++;
        if(liveCount>=200){await liveBatch.commit();liveBatch=dbU.batch();liveCount=0;}
      }
      if(BridgeDB._data.config_caja_negocio){
        liveBatch.set(dbU.collection('datos').doc('config_caja_negocio'),BridgeDB._data.config_caja_negocio,{merge:true});
        liveCount++;
      }
      if(liveCount>0)await liveBatch.commit();
      
      var meta={updated_at:new Date().toISOString(),total_registros:total};
      await dbU.collection('datos').doc('backup_meta').set(meta,{merge:true});
      BridgeDB._data._meta=meta;
      try{localStorage.setItem('bridge_data',JSON.stringify(BridgeDB._data));}catch(e){}
      return {registros:total,ok:true};
    }
    if(method==='POST'&&action==='download'){
      var dbD=BridgeDB._getFirestore();
      if(!dbD)throw new Error('Firebase no disponible');
      var colls=['categorias','productos','clientes','proveedores','ventas','cajas','movimientos_caja','fiados','fiado_abonos','user_actions','compras','compras_programadas','autoconsumos','visitas_proveedor','distribuciones','distribuciones_categorias','ventas_bar_cuentas','ventas_bar_categorias','ventas_bar_productos','cotizaciones','permisos','roles','usuarios'];
      var promises=colls.map(function(col){
        return dbD.collection('datos').doc('backup_'+col).get().then(function(doc){
          if(doc.exists){var d=doc.data();if(d&&d.lista)BridgeDB._data[col]=d.lista;}
        }).catch(function(){});
      });
      promises.push(dbD.collection('datos').doc('backup_config_caja_negocio').get().then(function(doc){
        if(doc.exists){
          var d=doc.data();
          if(d && d.lista && !Array.isArray(d.lista)){
            d = d.lista;
          }
          if(d)BridgeDB._data.config_caja_negocio=d;
        }
      }).catch(function(){}));
      promises.push(dbD.collection('datos').doc('backup_meta').get().then(function(doc){
        if(doc.exists){BridgeDB._data._meta=doc.data();}
      }).catch(function(){}));
      // Also try legacy single-doc backup
      promises.push(dbD.collection('datos').doc('backup').get().then(function(doc){
        if(doc.exists){
          var fb=doc.data();
          if(fb&&fb._data){
            for(var k in BridgeDB._defaults){if(fb._data[k])BridgeDB._data[k]=fb._data[k];}
            if(fb._data.config_caja_negocio){
              var d = fb._data.config_caja_negocio;
              if(d && d.lista && !Array.isArray(d.lista)){
                d = d.lista;
              }
              BridgeDB._data.config_caja_negocio=d;
            }
            if(fb._meta)BridgeDB._data._meta=fb._meta;
          }
        }
      }).catch(function(){}));
      return Promise.all(promises).then(function(){
        BridgeDB._save();
        return {ok:true};
      });
    }
    if(method==='POST'&&action==='publish-update'){
      var dbPu=BridgeDB._getFirestore();
      if(!dbPu)throw new Error('Firebase no disponible');
      
      var p1 = dbPu.collection('datos').doc('config_app').set({
        version:(data||{}).version||'2.1',
        mensaje:(data||{}).mensaje||'Nueva version disponible - refresque la pagina',
        forzar:(data||{}).forzar||false,
        release_date:new Date().toISOString(),
        updated_at:new Date().toISOString()
      },{merge:true});
      
      var proms = [p1];
      var uploadedFiles = (data||{}).files || {};
      for(var filename in uploadedFiles){
        var docName = filename.replace(/\//g, '_');
        proms.push(dbPu.collection('update_files').doc(docName).set({
          filename: filename,
          content: uploadedFiles[filename],
          updated_at: new Date().toISOString()
        }));
      }
      
      return Promise.all(proms).then(function(){
        return {ok:true,version:(data||{}).version||'2.1'};
      });
    }
    return null;
  }
};

// Initialize
BridgeDB.init();

