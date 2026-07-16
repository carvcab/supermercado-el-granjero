const https = require('https');
const fs = require('fs');
const path = require('path');

const API_KEY = 'AIzaSyBgloNAS908fXoZ5DWZCMyKZwvtyJw7L_o';
const PROJECT_ID = 'supermercado-el-campesino';

function httpsRequest(url, method, data, token) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = {
      hostname: u.hostname,
      path: u.pathname + u.search,
      method: method,
      headers: { 'Content-Type': 'application/json' }
    };
    if (token) opts.headers['Authorization'] = 'Bearer ' + token;
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data, 'utf8');
    const req = https.request(opts, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(body)); }
        catch (e) { resolve(body); }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function signIn() {
  // Try to sign in with a known admin email - we need to create a test account first
  // Use signUp to create a temporary account (Firebase Auth allows this with API key)
  const signUpData = JSON.stringify({
    email: 'temp-update-' + Date.now() + '@example.com',
    password: 'TempPass123!',
    returnSecureToken: true
  });
  const result = await httpsRequest(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    'POST', signUpData
  );
  if (result.error) throw new Error('Auth error: ' + JSON.stringify(result.error));
  console.log('Signed in as:', result.email);
  return result.idToken;
}

async function uploadFiles(token) {
  const filesToUpload = [
    'index.html', 'preload.js', 'main.js', 'package.json',
    'css/style.css', 'js/api-bridge.js', 'version.json'
  ];
  const rootDir = __dirname + '/..';

  // First, get existing documents to delete
  const getRes = await httpsRequest(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/update_files`,
    'GET', null, token
  );
  if (getRes.documents) {
    for (const doc of getRes.documents) {
      const docName = doc.name;
      await httpsRequest(
        `https://firestore.googleapis.com/v1/${docName}`,
        'DELETE', null, token
      );
      console.log('Deleted:', docName.split('/').pop());
    }
  }

  // Upload each file
  for (const file of filesToUpload) {
    const filePath = path.join(rootDir, file);
    const content = fs.readFileSync(filePath, 'utf8');
    const docId = file.replace(/[/\\]/g, '_');

    const document = {
      fields: {
        filename: { stringValue: file },
        content: { stringValue: content }
      }
    };

    await httpsRequest(
      `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/update_files?documentId=${encodeURIComponent(docId)}`,
      'POST', JSON.stringify(document), token
    );
    console.log('Uploaded:', file);
  }

  const versionData = JSON.parse(fs.readFileSync(path.join(rootDir, 'version.json'), 'utf8'));
  console.log('Published version:', versionData.version);
}

signIn().then(uploadFiles).then(() => {
  console.log('SUCCESS: Update files published to Firestore');
}).catch(err => {
  console.error('FAILED:', err.message);
});
