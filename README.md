# Escriba para Windows

Escriba graba una conversación entre dos personas y la transcribe en tu PC. También resume y
responde preguntas sobre lo que se dijo, con un modelo de IA que corre en la misma PC.

### [Descargar la última versión](https://github.com/FischMati/escriba-descargas/releases/latest)

En la página de la versión, dentro de **Assets**, bajá `Escriba_…_x64-setup.exe`.

> **Estado:** versión preliminar. Todavía no tiene una auditoría externa del cifrado ni un
> instalador firmado. Hasta entonces, no conviene usarla con datos sensibles reales.

## Qué necesitás

- Windows 10 u 11 de 64 bits.
- Un procesador con AVX2: Intel Core de 4.ª generación (2013) o posterior, o AMD Ryzen.
- 16 GB de memoria RAM (recomendado).
- Unos 7 GB libres en el disco: la primera vez, la app descarga los modelos de IA (≈6 GB).
- Internet para instalar y para descargar los modelos. Después transcribe y resume sin
  conexión.

Una placa de video hace que la transcripción y el resumen salgan más rápido, pero no hace falta.

## Instalar

1. Bajá el instalador desde [la última versión](https://github.com/FischMati/escriba-descargas/releases/latest).
2. Abrilo. Como todavía no está firmado, Windows muestra «Windows protegió tu PC»: tocá
   **Más información → Ejecutar de todas formas**. Se instala solo para tu usuario y no pide
   permisos de administrador.
3. Permití el micrófono: **Configuración → Privacidad y seguridad → Micrófono → Permitir que
   las aplicaciones de escritorio accedan al micrófono**.

La app no se actualiza sola: las versiones nuevas se publican en esta página.

## Primer uso

1. Creá tu bóveda con tu nombre y una contraseña larga. **Guardá el código de recuperación**
   en un lugar seguro: sin la contraseña y sin ese código, las sesiones no se pueden recuperar.
2. Cuando la app lo pida, descargá los modelos de IA (≈6 GB). La descarga se puede pausar y
   retomar.
3. Creá una sesión, tocá **Grabar** y, al final, **Terminar**. El texto aparece mientras se
   habla.

Los primeros 30 días son de prueba. Después, para grabar y usar la IA hace falta una licencia,
que se activa en **Ajustes → Licencia**. Las sesiones guardadas se pueden leer siempre.

## Privacidad

- El audio se transcribe en tu PC y no se guarda.
- Las sesiones quedan cifradas en el disco: para abrirlas hacen falta tu contraseña y un
  secreto que Windows guarda para tu usuario.
- Los modelos de IA corren en procesos aislados, sin acceso a internet.
- Compartir una sesión con otra persona es opcional y va cifrado de extremo a extremo. El
  servidor que pasa los mensajes no ve el contenido ni los nombres; sí ve tamaños, horarios y
  direcciones IP.

## Comprobar que el instalador es el original

Cada versión se publica acá con el SHA-256 del instalador, y GitHub no permite cambiar los
archivos de una versión ya publicada. Para comparar, abrí PowerShell y escribí (con el nombre
del archivo que bajaste):

```powershell
Get-FileHash "$HOME\Downloads\Escriba_0.1.0_x64-setup.exe"
```

Tiene que dar el mismo SHA-256 que muestra la página de la versión (mayúsculas o minúsculas da
igual). Con [GitHub CLI](https://cli.github.com) también se puede comprobar la certificación
que firma GitHub al publicar:

```powershell
gh release verify-asset v0.1.0 "$HOME\Downloads\Escriba_0.1.0_x64-setup.exe" --repo FischMati/escriba-descargas
```

El código de Escriba no es público por ahora: esta página solo publica los instaladores.
