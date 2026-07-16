const https = require('https');

const API_KEY = 'AIzaSyBgloNAS908fXoZ5DWZCMyKZwvtyJw7L_o';
const PROJECT_ID = 'supermercado-el-campesino';

function httpsReq(url, method, data, token) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = {
      hostname: u.hostname, path: u.pathname + u.search, method,
      headers: { 'Content-Type': 'application/json' }
    };
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
  // Sign in
  const signUpData = JSON.stringify({ email: 'fix-' + Date.now() + '@x.com', password: 'Fix123!', returnSecureToken: true });
  const r = await httpsReq('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + API_KEY, 'POST', signUpData);
  const token = r.idToken;

  // Read existing config_app
  const doc = await httpsReq(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/datos/config_app`,
    'GET', null, token
  );
  console.log('Current config_app:', JSON.stringify(doc.fields?.version?.stringValue || doc));

  // Update config_app to 3.1.8
  const updateData = JSON.stringify({
    fields: {
      version: { stringValue: '3.1.8' },
      mensaje: { stringValue: 'Corregido bucle de actualizacion' },
      forzar: { booleanValue: false },
      release_date: { stringValue: new Date().toISOString() },
      updated_at: { stringValue: new Date().toISOString() }
    }
  });
  const result = await httpsReq(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/datos/config_app`,
    'PATCH', updateData, token
  );
  console.log('Updated config_app version to:', result.fields?.version?.stringValue);

  // Verify all update_files docs have correct filenames
  const files = await httpsReq(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/update_files`,
    'GET', null, token
  );
  if (files.documents) {
    console.log('update_files contains:');
    for (const d of files.documents) {
      console.log(' -', d.fields?.filename?.stringValue || '???');
    }
  }
}
main().catch(e => console.error('FAILED:', e.message));
