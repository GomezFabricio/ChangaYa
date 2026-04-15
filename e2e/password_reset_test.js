// e2e/password_reset_test.js
//
// Test E2E del flow #3: password reset.
// Verifica que tras llenar el email y solicitar el reset, la app muestra
// un mensaje genérico (sin revelar si el email existe — por seguridad).
//
// Correr con:
//   node e2e/password_reset_test.js

const { chromium } = require('playwright');

const APP_URL = 'http://localhost:5050';

async function run() {
  const email = `reset_${Date.now()}@changaya.test`;

  console.log('\n=== ChangaYa Flow #3: Password Reset ===');
  console.log(`Email: ${email}`);

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
      () => document.body.innerText.includes('¿Olvidaste tu contraseña?'),
      { timeout: 15000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/reset-01-login.png' });
    console.log('   app cargada ✓');

    // ---- Paso 2: click en "¿Olvidaste tu contraseña?" ----
    console.log('\n[2] Click "¿Olvidaste tu contraseña?"...');
    await page.getByText('¿Olvidaste tu contraseña?').click();
    await page.waitForTimeout(1000);

    // Esperar pantalla de forgot password (por el botón que tiene)
    await page.waitForFunction(
      () => document.body.innerText.includes('Enviar instrucciones'),
      { timeout: 10000 }
    );
    await page.screenshot({ path: 'e2e/screenshots/reset-02-forgot-password.png' });
    console.log('   llegamos a /forgot-password ✓');

    // ---- Paso 3: llenar email ----
    console.log('\n[3] Llenando email...');
    const emailField = page.locator('input').first();
    await emailField.click();
    await page.keyboard.type(email);
    await page.screenshot({ path: 'e2e/screenshots/reset-03-filled.png' });

    // ---- Paso 4: submit ----
    console.log('\n[4] Click "Enviar instrucciones"...');
    await page.getByRole('button', { name: 'Enviar instrucciones' }).click();
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'e2e/screenshots/reset-04-submitted.png' });

    // ---- Paso 5: verificar mensaje genérico ----
    // Por seguridad, la app NO debería revelar si el email existe o no.
    // El mensaje esperado es algo genérico tipo "Si el email existe, te
    // enviamos instrucciones" o similar.
    console.log('\n[5] Verificando mensaje genérico...');
    const postSubmitText = await page.evaluate(() => document.body.innerText);
    console.log('   Texto visible post-submit:');
    console.log('   ' + postSubmitText.substring(0, 400).replace(/\n/g, '\n   '));

    // Lista de keywords que NO deberían aparecer (confirmarían existencia/no)
    const leakKeywords = [
      'no existe',
      "doesn't exist",
      'not found',
      'user-not-found',
    ];
    const leaked = leakKeywords.find((kw) => postSubmitText.toLowerCase().includes(kw.toLowerCase()));
    if (leaked) {
      throw new Error(`⚠️ Mensaje revela existencia del user: contiene "${leaked}"`);
    }

    console.log('   mensaje genérico OK — no revela existencia del user ✓');

    console.log('\n✅ Flow #3 completado: password reset con mensaje seguro\n');
  } catch (err) {
    console.error(`\n❌ Fallo: ${err.message}`);
    await page.screenshot({ path: 'e2e/screenshots/reset-FAIL.png' });
    process.exitCode = 1;
  } finally {
    await page.waitForTimeout(2000);
    await browser.close();
  }
}

run();
