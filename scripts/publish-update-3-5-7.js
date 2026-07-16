const https = require('https');
const fs = require('fs');
const path = require('path');

const API_KEY = 'AIzaSyBgloNAS908fXoZ5DWZCMyKZwvtyJw7L_o';
const PROJECT_ID = 'supermercado-el-campesino';

function httpsReq(url, method, data, token) {
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
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => {
        try { resolve(JSON.parse(b)); }
        catch (e) { resolve(b); }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function main() {
  const rootDir = path.join(__dirname, '..');
  const versionPath = path.join(rootDir, 'version.json');
  if (!fs.existsSync(versionPath)) {
    throw new Error('version.json not found in root directory');
  }
  const versionData = JSON.parse(fs.readFileSync(versionPath, 'utf8'));
  const version = versionData.version;
  const mensaje = versionData.mensaje;

  console.log(`Starting publication process for version: ${version}`);
  console.log(`Message: "${mensaje}"`);

  console.log('Authenticating temporarily with Firebase Auth REST API...');
  const signUpData = JSON.stringify({
    email: 'publish-' + Date.now() + '@x.com',
    password: 'PublishPassword123!',
    returnSecureToken: true
  });
  const r = await httpsReq(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`, 'POST', signUpData);
  const token = r.idToken;

  if (!token) {
    throw new Error('Authentication failed: ' + JSON.stringify(r));
  }
  console.log('Successfully authenticated.');

  // 1. Clean up old update files
  console.log('Retrieving existing update_files from Firestore...');
  const getRes = await httpsReq(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/update_files`,
    'GET', null, token
  );
  if (getRes.documents && getRes.documents.length > 0) {
    console.log(`Found ${getRes.documents.length} old file(s). Deleting...`);
    for (const doc of getRes.documents) {
      const docName = doc.name;
      await httpsReq(
        `https://firestore.googleapis.com/v1/${docName}`,
        'DELETE', null, token
      );
      console.log(`Deleted old file doc: ${docName.split('/').pop()}`);
    }
  } else {
    console.log('No old update files found to delete.');
  }

  // 2. Upload new update files
  const filesToUpload = [
    'index.html', 'preload.js', 'main.js', 'package.json',
    'css/style.css', 'js/api-bridge.js', 'version.json'
  ];

  console.log('Uploading new update files...');
  for (const file of filesToUpload) {
    const filePath = path.join(rootDir, file);
    if (!fs.existsSync(filePath)) {
      throw new Error(`Required file not found: ${filePath}`);
    }
    const content = fs.readFileSync(filePath, 'utf8');
    const docId = file.replace(/[/\\]/g, '_');

    const document = {
      fields: {
        filename: { stringValue: file },
        content: { stringValue: content }
      }
    };

    const uploadRes = await httpsReq(
      `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/update_files?documentId=${encodeURIComponent(docId)}`,
      'POST', JSON.stringify(document), token
    );
    if (uploadRes.error) {
      throw new Error(`Failed to upload ${file}: ` + JSON.stringify(uploadRes.error));
    }
    console.log(`Uploaded: ${file}`);
  }

  // 3. Update config_app
  console.log('Updating config_app document in Firestore...');
  const updateData = JSON.stringify({
    fields: {
      version: { stringValue: version },
      mensaje: { stringValue: mensaje },
      forzar: { booleanValue: false },
      release_date: { stringValue: new Date().toISOString() },
      updated_at: { stringValue: new Date().toISOString() }
    }
  });

  const configRes = await httpsReq(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/datos/config_app`,
    'PATCH', updateData, token
  );
  if (configRes.error) {
    throw new Error('Failed to update config_app: ' + JSON.stringify(configRes.error));
  }
  console.log('Successfully updated config_app to version:', configRes.fields?.version?.stringValue);

  console.log('\nSUCCESS: All updates published successfully to Firestore!');
}

main().catch(err => {
  console.error('\nFAILED:', err.message || err);
  process.exit(1);
});
