// e2e/login_existing_test.js
//
// Test E2E del flow #2: login con cuenta existente verificada con onboarding
// completo → directo a /home.
//
// El script crea un user con profile completo via REST al inicio para
// garantizar un estado predecible. Así no depende de state previo del emulador.
//
// Correr con:
//   node e2e/login_existing_test.js

const { chromium } = require('playwright');
const http = require('http');

const APP_URL = 'http://localhost:5050';
const AUTH_EMULATOR = 'http://127.0.0.1:9099';
const FIRESTORE_EMULATOR = 'http://127.0.0.1:8080';
const PROJECT_ID = 'changaya-dev';

// ---------------------------------------------------------------------------
// HTTP helper (sin dependencias externas)
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

// ---------------------------------------------------------------------------
// Setup: crear user verified + profile completo vía REST
// ---------------------------------------------------------------------------
async function createVerifiedUserWithProfile(email, password, name) {
  // 1. Crear user (endpoint signUp — crea Y devuelve localId)
  const signupRes = await httpRequest(
    'POST',
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    { body: { email, password, returnSecureToken: true } }
  );
  if (signupRes.status !== 200) {
    throw new Error(`signUp failed: ${signupRes.status} ${JSON.stringify(signupRes.body)}`);
  }
  const uid = signupRes.body.localId;

  // 2. Marcar emailVerified + displayName
  await httpRequest(
    'POST',
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:update`,
    { body: { localId: uid, emailVerified: true, displayName: name } }
  );

  // 3. Crear profile en Firestore con onboardingComplete=true
  const profileDoc = {
    fields: {
      uid: { stringValue: uid },
      displayName: { stringValue: name },
      phone: { stringValue: '03624 555666' },
      locality: { stringValue: 'Formosa Capital' },
      photoURL: { nullValue: null },
      onboardingComplete: { booleanValue: true },
    },
  };
  const fsRes = await httpRequest(
    'PATCH',
    `${FIRESTORE_EMULATOR}/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`,
    { body: profileDoc }
  );
  if (fsRes.status !== 200) {
    throw new Error(`Firestore write failed: ${fsRes.status} ${JSON.stringify(fsRes.body)}`);
  }

  return uid;
}

// ---------------------------------------------------------------------------
// Test principal
// ---------------------------------------------------------------------------
async function run() {
  const email = `existing_${Date.now()}@changaya.test`;
  const password = 'Test1234';
  const name = 'Existing User';

  console.log('\n=== ChangaYa Flow #2: Login existente → Home ===');
  console.log(`Email: ${email}`);

  // ---- Setup via REST ----
  console.log('\n[setup] Creando user verified + profile completo...');
  const uid = await createVerifiedUserWithProfile(email, password, name);
  console.log(`   UID: ${uid} ✓`);

  const browser = await chromium.launch({ headless: false, slowMo: 200 });
  const page = await browser.newContext().then((c) => c.newPage());
  page.on('pageerror', (err) => console.log(`[PAGE ERROR] ${err.message}`));

  try {
    // ---- Paso 1: abrir app + habilitar semantics ----
    console.log('\n[1] Abriendo app...');
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flt-semantics-placeholder', { timeout: 30000 });
    await page.evaluate(() => {
      document.querySelector('flt-semantics-placeholder')?.click();
    });
    await page.waitForTimeout(1000);
    await page.waitForFunction(
      () => document.body.innerText.includes('Iniciar sesión'),
      { timeout: 15000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/login-01-login-screen.png' });
    console.log('   app cargada ✓');

    // ---- Paso 2: llenar form de login ----
    console.log('\n[2] Llenando form de login...');
    const emailField = page.locator('input').nth(0);
    await emailField.click();
    await page.keyboard.type(email);

    await page.keyboard.press('Tab');
    await page.keyboard.type(password);

    await page.screenshot({ path: 'e2e/screenshots/login-02-filled.png' });

    // ---- Paso 3: submit ----
    console.log('\n[3] Click "Iniciar sesión"...');
    await page.getByRole('button', { name: 'Iniciar sesión' }).click();

    // ---- Paso 4: esperar /home ----
    console.log('\n[4] Esperando /home...');
    // Bump timeout: el redirect cascade puede tardar unos segundos en
    // re-evaluar cuando el Firestore listener del profile emite.
    await page.waitForFunction(
      () => document.body.innerText.includes('Home — próximamente'),
      { timeout: 30000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/login-03-home.png' });
    console.log('   llegamos a /home ✓');

    console.log('\n✅ Flow #2 completado: login existente → /home directo\n');
  } catch (err) {
    console.error(`\n❌ Fallo: ${err.message}`);
    await page.screenshot({ path: 'e2e/screenshots/login-FAIL.png' });
    process.exitCode = 1;
  } finally {
    await page.waitForTimeout(2000);
    await browser.close();
  }
}

run();
