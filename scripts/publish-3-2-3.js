const https = require('https');
const fs = require('fs');
const path = require('path');

const API_KEY = 'AIzaSyBgloNAS908fXoZ5DWZCMyKZwvtyJw7L_o';
const PROJECT_ID = 'supermercado-el-campesino';

function httpsReq(url, method, data, token) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = { hostname: u.hostname, path: u.pathname + u.search, method, headers: { 'Content-Type': 'application/json' } };
    if (token) opts.headers['Authorization'] = 'Bearer ' + token;
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data, 'utf8');
    const req = https.request(opts, (res) => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => { try { resolve(JSON.parse(b)); } catch(e) { resolve(b); } });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function main() {
  const r = await httpsReq('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + API_KEY, 'POST',
    JSON.stringify({ email: 'pub-' + Date.now() + '@x.com', password: 'Pub123!', returnSecureToken: true }));
  const token = r.idToken;

  // 1. Update config_app
  const cfg = {
    fields: {
      version: { stringValue: '3.2.3' },
      mensaje: { stringValue: 'Editar/eliminar distribuciones con recalculo de ganancias y limpiar datos completo' },
      forzar: { booleanValue: false },
      release_date: { stringValue: new Date().toISOString() },
      updated_at: { stringValue: new Date().toISOString() }
    }
  };
  await httpsReq(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/datos/config_app`, 'PATCH', JSON.stringify(cfg), token);
  console.log('config_app → 3.2.3');

  // 2. Replace all update_files
  const existing = await httpsReq(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/update_files`, 'GET', null, token);
  if (existing.documents) {
    for (const doc of existing.documents) {
      await httpsReq(`https://firestore.googleapis.com/v1/${doc.name}`, 'DELETE', null, token);
    }
    console.log('Cleared old update_files');
  }

  const filesToUpload = ['index.html', 'preload.js', 'main.js', 'package.json', 'css/style.css', 'js/api-bridge.js', 'version.json'];
  const rootDir = __dirname + '/..';
  for (const file of filesToUpload) {
    const content = fs.readFileSync(path.join(rootDir, file), 'utf8');
    const docId = file.replace(/[/\\]/g, '_');
    const docData = { fields: { filename: { stringValue: file }, content: { stringValue: content } } };
    await httpsReq(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/update_files?documentId=${encodeURIComponent(docId)}`, 'POST', JSON.stringify(docData), token);
    console.log('update_files/', docId);
  }
  console.log('SUCCESS');
}
main().catch(e => console.error(e));
