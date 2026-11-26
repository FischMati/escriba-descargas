import { chromium } from 'playwright-core';
import assert from 'node:assert/strict';
import { setTimeout as wait } from 'node:timers/promises';

async function connectVersion(version) {
  const until = Date.now() + 150000;
  while (Date.now() < until) {
    for (const host of ['127.0.0.1','[::1]']) {
      try {
        const browser = await chromium.connectOverCDP('http://'+host+':9222',{timeout:1500});
        const page = browser.contexts()[0]?.pages()[0];
        if (page && await page.evaluate(() => window.__TAURI_INTERNALS__.invoke('plugin:app|version')) === version) return page;
      } catch {}
    }
    await wait(1000);
  }
  throw Error('La app no abrió la versión '+version);
}
const page=await connectVersion('0.1.10-1');
const pass='Esta bóveda es de prueba 2026';
const name='Prueba de actualización';

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

await page.getByRole('button',{name:'Buscar actualizaciones'}).click();
const update=page.getByRole('button',{name:'Actualizar a 0.1.10 y reiniciar'});
await update.waitFor({timeout:50000});
await update.click();
console.log('Actualización solicitada desde la app');
const next=await connectVersion('0.1.10');
await next.locator('input[type=password]').fill(pass);
await next.getByRole('button',{name:'Desbloquear',exact:true}).click();
await next.getByRole('button',{name:new RegExp(name)}).first().click();
await next.getByRole('heading',{name}).waitFor();
console.log('El instalador firmado reinició Escriba 0.1.10 y la bóveda conservó su sesión.');
process.exit(0);
