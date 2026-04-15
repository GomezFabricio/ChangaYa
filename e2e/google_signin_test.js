// e2e/google_signin_test.js
//
// Test E2E del Google Sign-In en web contra el Firebase Auth Emulator.
//
// En web, `signInWithPopup(GoogleAuthProvider)` abre un popup hacia el
// emulador que sirve una UI fake de autenticación de Google. Playwright
// la automatiza.
//
// REQUISITOS (mismos que auth_flow_test.js):
//   - Firebase Emulator Suite corriendo
//   - Flutter web en localhost:5050
//
// Correr con:
//   node e2e/google_signin_test.js

const { chromium } = require('playwright');

const APP_URL = 'http://localhost:5050';

async function run() {
  console.log('\n=== ChangaYa Google Sign-In E2E (web) ===');

  const browser = await chromium.launch({ headless: false, slowMo: 200 });
  const context = await browser.newContext();
  const page = await context.newPage();
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
    await page.screenshot({ path: 'e2e/screenshots/google-01-login.png' });
    console.log('   app cargada ✓');

    // ---- Paso 2: click "Continuar con Google" + captura popup ----
    console.log('\n[2] Click "Continuar con Google"...');
    const [popup] = await Promise.all([
      page.waitForEvent('popup', { timeout: 15000 }),
      page.getByText('Continuar con Google').click(),
    ]);
    await popup.waitForLoadState('domcontentloaded');
    await popup.waitForTimeout(1500); // emulator UI hydrate
    await popup.screenshot({ path: 'e2e/screenshots/google-02-popup.png' });
    console.log(`   popup abierto: ${popup.url()}`);

    // ---- Paso 3: interactuar con la UI del emulator ----
    // La UI del Auth Emulator ofrece: lista de users existentes + "Add new account"
    // Buscamos el botón "Auto-generate user information" o "Add new account"
    console.log('\n[3] Buscando botón "Add new account" en el popup...');

    // Dump del texto visible del popup para debug
    const popupText = await popup.evaluate(() => document.body.innerText);
    console.log('   Texto del popup (primeros 500 chars):');
    console.log('   ' + popupText.substring(0, 500).replace(/\n/g, '\n   '));

    // Intento 1: botón "Add new account"
    try {
      await popup
        .getByRole('button', { name: /add new account/i })
        .click({ timeout: 5000 });
      console.log('   click "Add new account" ✓');
    } catch {
      console.log('   "Add new account" no encontrado — probando alternativa');
    }

    await popup.waitForTimeout(1000);
    await popup.screenshot({ path: 'e2e/screenshots/google-03-popup-after-click.png' });

    // Intento 2: si hay un botón "Auto-generate user information"
    try {
      await popup
        .getByRole('button', { name: /auto.?generate/i })
        .click({ timeout: 5000 });
      console.log('   click "Auto-generate" ✓');
    } catch {
      console.log('   "Auto-generate" no encontrado');
    }

    await popup.waitForTimeout(500);
    await popup.screenshot({ path: 'e2e/screenshots/google-04-popup-filled.png' });

    // Intento 3: submit / sign in with Google
    try {
      await popup
        .getByRole('button', { name: /sign.?in/i })
        .click({ timeout: 5000 });
      console.log('   click "Sign in" ✓');
    } catch {
      console.log('   "Sign in" no encontrado');
    }

    // ---- Paso 4: esperar cierre del popup + navegación de la app ----
    console.log('\n[4] Esperando cierre del popup...');
    await popup.waitForEvent('close', { timeout: 15000 }).catch(() => {
      console.log('   popup no cerró — continúa para ver estado');
    });

    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'e2e/screenshots/google-05-after-popup.png' });

    // ---- Paso 5: ver dónde terminó la app ----
    const finalText = await page.evaluate(() => document.body.innerText);
    if (finalText.includes('Completá tu perfil')) {
      console.log('\n✅ Login con Google exitoso → /complete-profile (user nuevo)');
    } else if (finalText.includes('Home — próximamente')) {
      console.log('\n✅ Login con Google exitoso → /home (user existente con onboarding completo)');
    } else if (finalText.includes('Verificá tu email')) {
      console.log('\n⚠️ Login con Google → /verify-email (debería ser verified por Google?)');
    } else {
      console.log('\n❓ Estado inesperado de la app');
      console.log('   Primeros 300 chars del texto:');
      console.log('   ' + finalText.substring(0, 300).replace(/\n/g, '\n   '));
    }
  } catch (err) {
    console.error(`\n❌ Fallo: ${err.message}`);
    await page.screenshot({ path: 'e2e/screenshots/google-FAIL.png' });
    process.exitCode = 1;
  } finally {
    await page.waitForTimeout(2000);
    await browser.close();
  }
}

run();
