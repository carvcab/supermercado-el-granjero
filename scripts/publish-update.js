const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const fs = require('fs');
const path = require('path');

initializeApp({ projectId: 'supermercado-el-campesino' });
const db = getFirestore();

async function publish() {
  const filesToUpload = [
    'index.html',
    'preload.js',
    'main.js',
    'package.json',
    'css/style.css',
    'js/api-bridge.js',
    'version.json'
  ];

  const rootDir = path.join(__dirname, '..');

  // Clear existing update_files
  const existing = await db.collection('update_files').get();
  const batch = db.batch();
  existing.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  console.log('Cleared existing update_files collection');

  // Upload each file
  for (const file of filesToUpload) {
    const filePath = path.join(rootDir, file);
    const content = fs.readFileSync(filePath, 'utf8');
    const docId = file.replace(/[/\\]/g, '_');
    await db.collection('update_files').doc(docId).set({
      filename: file,
      content: content
    });
    console.log('Uploaded:', file);
  }

  // Also update version.json for direct check
  const versionData = JSON.parse(fs.readFileSync(path.join(rootDir, 'version.json'), 'utf8'));
  console.log('Published version:', versionData.version);

  // Update config_app document
  await db.collection('datos').doc('config_app').set({
    version: versionData.version,
    mensaje: versionData.mensaje || '',
    updated_at: new Date().toISOString()
  }, { merge: true });
  console.log('Updated config_app to version:', versionData.version);
}

publish().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
