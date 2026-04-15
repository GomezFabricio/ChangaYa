// e2e/auth_flow_test.js
//
// Test E2E del flow #1 (registro → verify email → complete profile → home)
// contra la app Flutter web en Chrome, usando Playwright.
//
// REQUISITOS:
//   1. Firebase Emulator Suite corriendo:
//      firebase emulators:start --only auth,firestore,storage,functions
//   2. Flutter web servido en http://localhost:5050:
//      flutter run -t lib/main_dev.dart -d chrome --web-port=5050
//   3. Chromium instalado: npx playwright install chromium
//
// Correr con:
//   node e2e/auth_flow_test.js
//
// Documentado en docs/troubleshooting.md — parte del plan de E2E web.

const { chromium } = require('playwright');
const http = require('http');

const APP_URL = 'http://localhost:5050';
const AUTH_EMULATOR = 'http://127.0.0.1:9099';
const PROJECT_ID = 'changaya-dev';

// ---------------------------------------------------------------------------
// Helpers para la REST API del Auth Emulator (sin dependencias externas)
// ---------------------------------------------------------------------------

function httpRequest(method, url, { body, headers = {} } = {}) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = http.request(
      {
        hostname: u.hostname,
        port: u.port,
        path: u.pathname + u.search,
        method,
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer owner',
          ...headers,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () =>
          resolve({ status: res.statusCode, body: data ? JSON.parse(data) : null })
        );
      }
    );
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function findUidByEmail(email) {
  const res = await httpRequest(
    'POST',
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:query`,
    { body: { returnUserInfo: true } }
  );
  if (res.status !== 200) throw new Error(`query failed: ${res.status}`);
  const user = (res.body.userInfo || []).find((u) => u.email === email);
  return user ? user.localId : null;
}

async function markEmailVerified(uid) {
  const res = await httpRequest(
    'POST',
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:update`,
    { body: { localId: uid, emailVerified: true } }
  );
  if (res.status !== 200) throw new Error(`update failed: ${res.status}`);
}

// ---------------------------------------------------------------------------
// Test principal
// ---------------------------------------------------------------------------

async function run() {
  const email = `e2e_${Date.now()}@changaya.test`;
  const password = 'Test1234';
  const name = 'E2E Test User';
  const phone = '03624 987654';
  const locality = 'Formosa Capital';

  console.log('\n=== ChangaYa Flow #1 E2E ===');
  console.log(`Email: ${email}`);

  const browser = await chromium.launch({ headless: false, slowMo: 200 });
  const context = await browser.newContext();
  const page = await context.newPage();

  // Flutter web loggea mucho — filtramos errores de consola relevantes
  page.on('pageerror', (err) => console.log(`[PAGE ERROR] ${err.message}`));

  try {
    // ---- Paso 1: abrir app + habilitar semantics tree ----
    console.log('\n[1] Abriendo app...');
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    // Flutter web renderiza a canvas (canvaskit) por default. Para que Playwright
    // pueda interactuar con el DOM, hay que habilitar el semantics tree.
    // El placeholder está fuera del viewport — lo activamos vía JS.
    await page.waitForSelector('flt-semantics-placeholder', { timeout: 30000 });
    await page.evaluate(() => {
      const el = document.querySelector('flt-semantics-placeholder');
      if (el) el.click();
    });
    await page.waitForTimeout(1000);

    // Ahora los elementos están en el DOM con ARIA. Esperamos el texto.
    await page.waitForFunction(
      () => document.body.innerText.includes('Registrate'),
      { timeout: 15000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/01-login.png' });
    console.log('   app cargada + semantics habilitado ✓');

    // ---- Paso 2: navegar a register ----
    console.log('\n[2] Click en "Registrate"...');
    await page.getByText('Registrate', { exact: true }).click();
    await page.waitForFunction(
      () => document.body.innerText.includes('Crear cuenta'),
      { timeout: 10000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/02-register.png' });

    // ---- Paso 3: llenar formulario de registro ----
    console.log('\n[3] Llenando form...');
    // Flutter web expone text fields como <input>. Los buscamos por sus labels.
    // Estrategia: Tab desde el primer campo.
    const nameField = page.locator('input').nth(0);
    await nameField.click();
    await page.keyboard.type(name);

    await page.keyboard.press('Tab');
    await page.keyboard.type(email);

    await page.keyboard.press('Tab');
    await page.keyboard.type(password);

    // El campo de contraseña tiene un IconButton de visibilidad (ojo) que
    // captura el siguiente Tab. Hacemos doble Tab para saltarlo.
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.type(password);

    // Checkbox de términos
    await page.getByText('Acepto los términos y condiciones').click();

    await page.screenshot({ path: 'e2e/screenshots/03-register-filled.png' });

    // ---- Paso 4: submit ----
    console.log('\n[4] Click "Crear cuenta"...');
    await page.getByRole('button', { name: 'Crear cuenta' }).click();

    // ---- Paso 5: esperar /verify-email ----
    console.log('\n[5] Esperando /verify-email...');
    await page.waitForFunction(
      () => document.body.innerText.includes('Verificá tu email'),
      { timeout: 15000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/04-verify-email.png' });
    console.log('   llegamos a /verify-email ✓');

    // ---- Paso 6: marcar verified via REST ----
    console.log('\n[6] Marcando email verified via REST...');
    const uid = await findUidByEmail(email);
    if (!uid) throw new Error('No se encontró el UID del user creado');
    console.log(`   UID: ${uid}`);
    await markEmailVerified(uid);
    console.log('   emailVerified=true ✓');

    // ---- Paso 7: tap "Ya verifiqué mi email" ----
    console.log('\n[7] Click "Ya verifiqué mi email"...');
    await page.getByText('Ya verifiqué mi email').click();
    await page.waitForFunction(
      () => document.body.innerText.includes('Completá tu perfil'),
      { timeout: 15000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/05-complete-profile.png' });
    console.log('   llegamos a /complete-profile ✓');

    // ---- Paso 8: llenar perfil ----
    console.log('\n[8] Llenando perfil...');
    const phoneField = page.locator('input').first();
    await phoneField.click();
    await page.keyboard.type(phone);

    // Dropdown de localidad
    await page.getByText('Seleccioná tu localidad').click();
    await page.waitForTimeout(800);
    await page.screenshot({ path: 'e2e/screenshots/06a-dropdown-open.png' });

    // Flutter web no expone los items del DropdownMenu vía semantics tree
    // consistentemente. Fallback: click por coordenadas en el primer item
    // del overlay (que es "Formosa Capital", primera localidad en el array).
    // El overlay empieza ~48px desde el top y cada item tiene 48px de altura.
    await page.mouse.click(400, 80);
    await page.waitForTimeout(500);

    await page.screenshot({ path: 'e2e/screenshots/06-profile-filled.png' });

    // ---- Paso 9: guardar perfil ----
    console.log('\n[9] Click "Guardar perfil"...');
    await page.getByRole('button', { name: 'Guardar perfil' }).click();

    // ---- Paso 10: esperar /home ----
    console.log('\n[10] Esperando /home...');
    await page.waitForFunction(
      () => document.body.innerText.includes('Home — próximamente'),
      { timeout: 15000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/07-home.png' });
    console.log('   llegamos a /home ✓');

    console.log('\n✅ Flow #1 completado exitosamente en web\n');
  } catch (err) {
    console.error(`\n❌ Fallo en el flow: ${err.message}`);
    await page.screenshot({ path: 'e2e/screenshots/FAIL.png' });
    process.exitCode = 1;
  } finally {
    await page.waitForTimeout(2000);
    await browser.close();
  }
}

run();
