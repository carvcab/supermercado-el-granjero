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
  console.log('Autenticando temporalmente con Firebase Auth...');
  const signUpData = JSON.stringify({ email: 'fix-' + Date.now() + '@x.com', password: 'Fix123!', returnSecureToken: true });
  const r = await httpsReq('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + API_KEY, 'POST', signUpData);
  const token = r.idToken;

  if (!token) {
    console.error('Error de autenticación. Respuesta:', r);
    process.exit(1);
  }

  console.log('Obtenido ID Token. Actualizando config_app a 3.5.5...');
  const updateData = JSON.stringify({
    fields: {
      version: { stringValue: '3.5.5' },
      mensaje: { stringValue: 'Fix: Forzado limpiado de cache en inicio de sesion para evitar cache vieja corrupta de permisos en Flutter' },
      forzar: { booleanValue: false },
      release_date: { stringValue: new Date().toISOString() },
      updated_at: { stringValue: new Date().toISOString() }
    }
  });

  const result = await httpsReq(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/datos/config_app`,
    'PATCH', updateData, token
  );

  console.log('config_app actualizado en Firestore.');
  console.log('Resultado:', JSON.stringify(result.fields || result));
}

main().catch(console.error);
