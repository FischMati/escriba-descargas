import { chromium } from 'playwright-core';
import assert from 'node:assert/strict';
import { setTimeout as wait } from 'node:timers/promises';
const version = process.argv[2];
let browser;
for (let i = 0; i < 45 && !browser; i++) {
  for (const host of ['127.0.0.1', '[::1]']) {
    try { browser = await chromium.connectOverCDP('http://' + host + ':9222', {timeout: 2000}); break; }
    catch {}
  }
  if (!browser) await wait(1000);
}
assert.ok(browser, 'WebView2 abrió su ventana');
const page = browser.contexts()[0].pages()[0];
const name = 'Prueba de actualización';
const pass = 'Esta bóveda es de prueba 2026';
if (version === '0.1.6') {
  await page.getByPlaceholder('Ej.: Laura Ruiz').fill('Prueba');
  await page.locator('input[type=password]').nth(0).fill(pass);
  await page.locator('input[type=password]').nth(1).fill(pass);
  await page.getByRole('button',{name:'Crear bóveda'}).click();
  await page.getByLabel('Lo guardé en un lugar seguro').check();
  await page.getByRole('button',{name:'Empezar'}).click();
  await page.getByRole('button',{name:'Nueva sesión'}).first().click();
  await page.getByPlaceholder('Ej.: Reunión con Juan').fill(name);
  await page.getByRole('button',{name:'Crear sesión'}).click();
  await page.getByRole('heading',{name}).waitFor();
  await page.getByRole('button',{name:'Mi cuenta'}).click();
  await page.getByRole('button',{name:'Bloquear',exact:true}).click();
} else {
  await page.locator('input[type=password]').fill(pass);
  await page.getByRole('button',{name:/Desbloquear|Abrir bóveda/}).click();
  await page.getByRole('button',{name:new RegExp(name)}).first().click();
  await page.getByRole('heading',{name}).waitFor();
  await page.getByRole('button',{name:'Grabar',exact:true}).click();
  await page.locator('.toast-error').waitFor();
  await page.getByRole('button',{name:'Grabar',exact:true}).waitFor();
  const result = await page.evaluate(async () => {
    const invoke = window.__TAURI_INTERNALS__.invoke;
    const settings = await invoke('settings_get');
    await invoke('settings_set', { settings: {...settings, whisperModel:'ggml-tiny.bin', useGpu:false} });
    const models = await invoke('models_status');
    if (!models.whisper.present) throw new Error('Falta el modelo de prueba');
    const meetings = await invoke('meetings_list');
    const meeting = meetings.find(m => m.title === 'Prueba de actualización');
    if (!meeting) throw new Error('No se conservó la sesión');
    let error = '';
    try {
      await invoke('recording_start', {meetingId:meeting.id});
    } catch (e) {
      error = String(e);
    }
    if (!error) {
      await invoke('recording_stop');
      for (let i = 0; i < 120 && (await invoke('app_status')).recordingMeeting; i++) {
        await new Promise(r => setTimeout(r, 250));
      }
    }
    const state = await invoke('app_status');
    const after = await invoke('models_status');
    return {error, recording:state.recordingMeeting, sandbox:after.sandbox, launchError:after.launchError};
  });
  if (result.error) assert.match(result.error, /No se encontró un micrófono|No se pudo abrir el micrófono|No se pudo iniciar la captura/i);
  assert.ok(!result.recording && result.sandbox && !result.launchError, JSON.stringify(result));
  console.log('El motor cargó desde la aplicación instalada.', result.error || 'Grabación iniciada y detenida.');
  assert.equal(await page.locator('html').getAttribute('data-theme'), 'dark');
  await page.getByRole('button',{name:'Mi cuenta'}).click();
  const appearance = page.getByLabel('Apariencia');
  await appearance.selectOption('light');
  assert.equal(await page.locator('html').getAttribute('data-theme'), 'light');
  await appearance.selectOption('dark');
  await page.getByRole('button',{name:'Registro de diagnóstico'}).click();
  assert.equal(await page.getByText('Ver el texto que vas a copiar').count(), 0);
  await page.getByRole('button', {name:'Copiar registro'}).waitFor();
  await page.getByRole('dialog').locator('button[aria-label="Cerrar"]').click();
  await page.getByRole('button',{name:'Sesiones',exact:true}).click();
  await page.getByRole('button',{name:'Vincular a otra persona',exact:true}).click();
  const pairing = page.getByRole('dialog',{name:'Vincular a otra persona'});
  await pairing.getByRole('button',{name:'Tengo un código'}).click();
  await pairing.getByPlaceholder('XXXXX-XXXXX-XXXXX-XXXXX').waitFor();
  console.log('Índice conserva el acceso a contactos, apariencia y diagnóstico.');
}
console.log('Verificación completa', version);
await browser.close();
