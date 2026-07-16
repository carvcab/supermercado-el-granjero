const https = require('https');

const API_KEY = 'AIzaSyBgloNAS908fXoZ5DWZCMyKZwvtyJw7L_o';
const PROJECT_ID = 'supermercado-el-campesino';

function httpsReq(url, method, data, token) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = { hostname: u.hostname, path: u.pathname + u.search, method, headers: { 'Content-Type': 'application/json' } };
    if (token) opts.headers['Authorization'] = 'Bearer ' + token;
    const req = https.request(opts, (res) => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => { try { resolve(JSON.parse(b)); } catch(e) { resolve(b); } });
    });
    req.on('error', reject);
    req.end();
  });
}

async function main() {
  const r = await httpsReq('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + API_KEY, 'POST',
    JSON.stringify({ email: 'pub-' + Date.now() + '@x.com', password: 'Pub123!', returnSecureToken: true }));
  const token = r.idToken;

  const doc = await httpsReq(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/datos/usuarios`, 'GET', null, token);
  console.log(JSON.stringify(doc, null, 2));
}
main().catch(e => console.error(e));
