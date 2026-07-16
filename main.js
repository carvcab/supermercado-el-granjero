const { app, BrowserWindow, Menu, ipcMain, protocol, net, screen } = require('electron');
const path = require('path');
const fs = require('fs');
const https = require('https');
const http = require('http');
const { pathToFileURL } = require('url');

app.commandLine.appendSwitch('disable-gpu-rasterization');

const FIREBASE_URL = 'https://supermercado-el-campesino.web.app';

function getPackagedVersion() {
  try {
    const pkgPath = path.join(app.getAppPath(), 'package.json');
    const pkgData = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    if (pkgData && pkgData.version) return pkgData.version;
  } catch (e) {}
  return '0.0.0';
}

function getUpdateVersion() {
  const updatePkgPath = path.join(app.getPath('userData'), 'update', 'package.json');
  if (fs.existsSync(updatePkgPath)) {
    try {
      const pkgData = JSON.parse(fs.readFileSync(updatePkgPath, 'utf8'));
      if (pkgData && pkgData.version) return pkgData.version;
    } catch (e) {}
  }
  const updateVerPath = path.join(app.getPath('userData'), 'update', 'version.json');
  if (fs.existsSync(updateVerPath)) {
    try {
      const verData = JSON.parse(fs.readFileSync(updateVerPath, 'utf8'));
      if (verData && verData.version) return verData.version;
    } catch (e) {}
  }
  return '0.0.0';
}

function esMayorOIgualVersion(v1, v2) {
  const p1 = String(v1).split('.').map(Number);
  const p2 = String(v2).split('.').map(Number);
  for (let i = 0; i < Math.max(p1.length, p2.length); i++) {
    const n1 = p1[i] || 0;
    const n2 = p2[i] || 0;
    if (n1 > n2) return true;
    if (n1 < n2) return false;
  }
  return true;
}

// Dynamic bootstrap check to run updated main.js if it exists in AppData/update/
const updateDir = path.join(app.getPath('userData'), 'update');
if (app.isPackaged && __dirname !== updateDir) {
  const packagedVer = getPackagedVersion();
  const updateVer = getUpdateVersion();
  
  const shouldClear = updateVer !== '0.0.0' && esMayorOIgualVersion(packagedVer, updateVer);
  if (shouldClear) {
    console.log(`Packaged version (${packagedVer}) is newer or equal to AppData update (${updateVer}). Clearing update folder...`);
    try {
      fs.rmSync(updateDir, { recursive: true, force: true });
    } catch (e) {
      console.error('Failed to clear update folder:', e);
    }
  } else {
    const updateMainPath = path.join(updateDir, 'main.js');
    if (fs.existsSync(updateMainPath)) {
      try {
        require(updateMainPath);
        return; // Stop execution of the current file (bootstrap)
      } catch (e) {
        console.error('Failed to load updated main.js, falling back to original:', e);
        // Don't clear update folder - the update itself may be fine but have a transient error
      }
    }
  }
}

// Register 'app' protocol as privileged before app is ready
protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { standard: true, secure: true, supportFetchAPI: true } }
]);

let mainWindow = null;

function downloadFile(url, destPath) {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    const file = fs.createWriteStream(destPath);
    
    file.on('error', (err) => {
      file.close();
      fs.unlink(destPath, () => {});
      reject(err);
    });

    protocol.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        return downloadFile(response.headers.location, destPath).then(resolve).catch(reject);
      }
      if (response.statusCode !== 200) {
        file.close();
        fs.unlink(destPath, () => {});
        return reject(new Error(`HTTP ${response.statusCode}`));
      }
      response.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      file.close();
      fs.unlink(destPath, () => {});
      reject(err);
    });
  });
}

function getCurrentVersion() {
  // 1. Check update/package.json first (after a successful update)
  const updatePkgPath = path.join(app.getPath('userData'), 'update', 'package.json');
  if (fs.existsSync(updatePkgPath)) {
    try {
      const pkgData = JSON.parse(fs.readFileSync(updatePkgPath, 'utf8'));
      if (pkgData && pkgData.version) return pkgData.version;
    } catch (e) {}
  }
  // 2. Check update/version.json
  const updateVerPath = path.join(app.getPath('userData'), 'update', 'version.json');
  if (fs.existsSync(updateVerPath)) {
    try {
      const verData = JSON.parse(fs.readFileSync(updateVerPath, 'utf8'));
      if (verData && verData.version) return verData.version;
    } catch (e) {}
  }
  // 3. Fallback to installed package.json (read via fs, not require, to avoid cache)
  try {
    const pkgPath = path.join(app.getAppPath(), 'package.json');
    const pkgData = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    if (pkgData && pkgData.version) return pkgData.version;
  } catch (e) {}
  return '0.0.0';
}

function setupIPC() {
  ipcMain.handle('get-version', () => getCurrentVersion());

  function esMayorVersion(vNueva, vActual) {
    const p1 = String(vNueva).split('.').map(Number);
    const p2 = String(vActual).split('.').map(Number);
    for (let i = 0; i < Math.max(p1.length, p2.length); i++) {
      const n1 = p1[i] || 0;
      const n2 = p2[i] || 0;
      if (n1 > n2) return true;
      if (n1 < n2) return false;
    }
    return false;
  }

  ipcMain.handle('check-update', async () => {
    const httpModule = FIREBASE_URL.startsWith('https') ? https : http;
    return new Promise((resolve) => {
      const url = `${FIREBASE_URL}/version.json?t=${Date.now()}`;
      httpModule.get(url, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            const info = JSON.parse(data);
            const currentVersion = getCurrentVersion();
            resolve({
              hay_actualizacion: esMayorVersion(info.version, currentVersion),
              version_nueva: info.version,
              version_actual: currentVersion,
              mensaje: info.mensaje || ''
            });
          } catch(e) {
            resolve({ hay_actualizacion: false, error: 'invalid response' });
          }
        });
      }).on('error', () => {
        resolve({ hay_actualizacion: false, error: 'network error' });
      });
    });
  });

  ipcMain.handle('relaunch', () => {
    app.relaunch();
    app.exit(0);
  });

  ipcMain.handle('aplicar-update', async (event, filesList) => {
    try {
      const updateDir = path.join(app.getPath('userData'), 'update');
      // Clear old update folder to prevent stale/corrupt files from blocking
      if (fs.existsSync(updateDir)) {
        try { fs.rmSync(updateDir, { recursive: true, force: true }); } catch(e) {}
      }
      fs.mkdirSync(updateDir, { recursive: true });

      const filesToUpdate = [
        'index.html',
        'preload.js',
        'main.js',
        'package.json',
        'css/style.css',
        'js/api-bridge.js',
        'version.json'
      ];

      // Save Firestore files if provided
      const savedFiles = new Set();
      if (filesList && Array.isArray(filesList) && filesList.length > 0) {
        for (let i = 0; i < filesList.length; i++) {
          const item = filesList[i];
          if (mainWindow) {
            mainWindow.webContents.send('update-progress', { 
              stage: 'downloading', 
              file: item.filename,
              current: i + 1,
              total: filesToUpdate.length
            });
          }
          const destPath = path.join(updateDir, item.filename);
          const subDir = path.dirname(destPath);
          if (!fs.existsSync(subDir)) fs.mkdirSync(subDir, { recursive: true });
          fs.writeFileSync(destPath, item.content, 'utf8');
          savedFiles.add(item.filename);
        }
      }

      // ALWAYS download from Firebase Hosting files that are still missing
      // (including version.json and package.json which are never optional)
      for (let i = 0; i < filesToUpdate.length; i++) {
        const file = filesToUpdate[i];
        if (savedFiles.has(file)) continue; // already saved from Firestore
        if (mainWindow) {
          mainWindow.webContents.send('update-progress', { 
            stage: 'downloading', 
            file: file,
            current: i + 1,
            total: filesToUpdate.length
          });
        }
        const url = `${FIREBASE_URL}/${file}?t=${Date.now()}`;
        const destPath = path.join(updateDir, file);
        const subDir = path.dirname(destPath);
        if (!fs.existsSync(subDir)) fs.mkdirSync(subDir, { recursive: true });
        await downloadFile(url, destPath);
      }

      if (mainWindow) {
        mainWindow.webContents.send('update-progress', { stage: 'complete' });
      }

      return { success: true };
    } catch(e) {
      console.error('Update failed:', e);
      return { success: false, error: e.message };
    }
  });
}

app.whenReady().then(() => {
  function getMimeType(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    switch (ext) {
      case '.html': return 'text/html; charset=utf-8';
      case '.js': return 'application/javascript; charset=utf-8';
      case '.css': return 'text/css; charset=utf-8';
      case '.json': return 'application/json; charset=utf-8';
      case '.png': return 'image/png';
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.gif': return 'image/gif';
      case '.svg': return 'image/svg+xml';
      case '.woff': return 'font/woff';
      case '.woff2': return 'font/woff2';
      case '.ttf': return 'font/ttf';
      case '.eot': return 'application/vnd.ms-fontobject';
      default: return 'application/octet-stream';
    }
  }

  // Protocol handler for app:// to support dynamic local updates
  protocol.handle('app', (request) => {
    try {
      const url = new URL(request.url);
      const relativePath = url.pathname;
      const decodedPath = decodeURIComponent(relativePath);
      let filePath = decodedPath.startsWith('/') ? decodedPath.slice(1) : decodedPath;
      if (!filePath || filePath === '/') {
        filePath = 'index.html';
      }

      const updatePath = path.join(app.getPath('userData'), 'update', filePath);
      if (fs.existsSync(updatePath) && fs.statSync(updatePath).isFile()) {
        const content = fs.readFileSync(updatePath);
        return new Response(content, {
          headers: { 'content-type': getMimeType(filePath) }
        });
      }

      const defaultPath = path.join(app.getAppPath(), filePath);
      if (fs.existsSync(defaultPath) && fs.statSync(defaultPath).isFile()) {
        const content = fs.readFileSync(defaultPath);
        return new Response(content, {
          headers: { 'content-type': getMimeType(filePath) }
        });
      }

      return new Response('File not found: ' + filePath, { status: 404 });
    } catch (err) {
      console.error('Protocol error:', err);
      return new Response('Protocol error', { status: 500 });
    }
  });

  setupIPC();

  const win = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 800,
    minHeight: 500,
    backgroundColor: '#f4f6f5',
    icon: path.join(app.getAppPath(), 'assets', 'icon.ico'),
    title: 'Supermercado El Granjero',
    show: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });
  mainWindow = win;
  Menu.setApplicationMenu(null);

  // Handle default zoom based on screen size + custom user zoom persistence
  const zoomFilePath = path.join(app.getPath('userData'), 'zoom-level.json');
  let savedZoom = 1.0;
  try {
    const { width } = screen.getPrimaryDisplay().workAreaSize;
    if (width < 1200) {
      savedZoom = 0.85;
    } else if (width < 1400) {
      savedZoom = 0.90;
    }
  } catch (err) {
    console.error('Failed to calculate screen dimensions for default zoom:', err);
  }

  if (fs.existsSync(zoomFilePath)) {
    try {
      const zoomData = JSON.parse(fs.readFileSync(zoomFilePath, 'utf8'));
      if (zoomData && typeof zoomData.zoomFactor === 'number') {
        savedZoom = zoomData.zoomFactor;
      }
    } catch (e) {
      console.error('Error reading saved zoom level:', e);
    }
  }

  // Set the zoom factor on creation
  win.webContents.setZoomFactor(savedZoom);

  // Handle zoom shortcuts (Ctrl+Plus, Ctrl+Minus, Ctrl+0) and save changes
  win.webContents.on('before-input-event', (event, input) => {
    if (input.type === 'keyDown' && input.control) {
      if (input.key === '=' || input.key === '+') {
        const currentZoom = win.webContents.getZoomFactor();
        const newZoom = Math.min(3.0, currentZoom + 0.1);
        win.webContents.setZoomFactor(newZoom);
        try { fs.writeFileSync(zoomFilePath, JSON.stringify({ zoomFactor: newZoom })); } catch(e){}
        event.preventDefault();
      } else if (input.key === '-') {
        const currentZoom = win.webContents.getZoomFactor();
        const newZoom = Math.max(0.3, currentZoom - 0.1);
        win.webContents.setZoomFactor(newZoom);
        try { fs.writeFileSync(zoomFilePath, JSON.stringify({ zoomFactor: newZoom })); } catch(e){}
        event.preventDefault();
      } else if (input.key === '0') {
        win.webContents.setZoomFactor(1.0);
        try { fs.writeFileSync(zoomFilePath, JSON.stringify({ zoomFactor: 1.0 })); } catch(e){}
        event.preventDefault();
      }
    }
  });
  
  // Load using the app:// custom protocol instead of file://
  win.loadURL('app://local/index.html');
  
  // Open window maximized to fit the user's monitor resolution exactly and prevent cut-off issues
  win.once('ready-to-show', () => {
    win.maximize();
    win.show();
  });
});

app.on('window-all-closed', () => app.quit());
