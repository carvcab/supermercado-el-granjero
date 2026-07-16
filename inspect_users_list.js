const fs = require('fs');

const raw = JSON.parse(fs.readFileSync('users_raw.json', 'utf8'));

if (raw && raw.fields && raw.fields.lista && raw.fields.lista.arrayValue && raw.fields.lista.arrayValue.values) {
  const users = raw.fields.lista.arrayValue.values;
  console.log('Total users:', users.length);
  users.forEach((item, index) => {
    if (item.mapValue && item.mapValue.fields) {
      const f = item.mapValue.fields;
      console.log(`User ${index}:`, {
        id: f.id ? (f.id.integerValue || f.id.stringValue || f.id.doubleValue) : 'N/A',
        username: f.username ? f.username.stringValue : 'N/A',
        nombre_completo: f.nombre_completo ? f.nombre_completo.stringValue : 'N/A',
        activo: f.activo ? f.activo.booleanValue : 'N/A',
        rol: f.rol ? f.rol.stringValue : 'N/A',
        password: f.password ? f.password.stringValue : 'N/A',
        hasFoto: !!f.foto
      });
    }
  });
} else {
  console.log('Could not find users list in raw JSON!');
}
