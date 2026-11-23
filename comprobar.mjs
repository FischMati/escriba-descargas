import { chromium } from 'playwright-core';
import assert from 'node:assert/strict';
import { setTimeout as wait } from 'node:timers/promises';
const version = process.argv[2];
let browser;
for (let i = 0; i < 45 && !browser; i++) {
  try { browser = await chromium.connectOverCDP('http://127.0.0.1:9222', {timeout: 2000}); }
  catch { await wait(1000); }
}
assert.ok(browser, 'WebView2 abrió su ventana');
const page = browser.contexts()[0].pages()[0];
const name = 'Prueba de actualización';
const pass = 'Esta bóveda es de prueba 2026';
if (version === '0.1.1') {
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
  await page.getByRole('button',{name:'Bloquear',exact:true}).click();
} else {
  await page.locator('input[type=password]').fill(pass);
  await page.getByRole('button',{name:/Desbloquear|Abrir bóveda/}).click();
  await page.getByRole('button',{name:new RegExp(name)}).first().click();
  await page.getByRole('heading',{name}).waitFor();
  await page.getByRole('button',{name:'Grabar',exact:true}).click();
  await page.locator('.toast-error').waitFor();
  await page.getByRole('button',{name:'Grabar',exact:true}).waitFor();
  await page.getByRole('button',{name:'Registro de diagnóstico'}).click();
  await page.getByRole('textbox',{name:'Eventos técnicos'}).waitFor();
}
console.log('Verificación completa', version);
await browser.close();
