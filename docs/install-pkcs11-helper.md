# Instalacion del helper PKCS#11 de AduaNext

Esta guia cubre la instalacion del binario `aduanext-pkcs11-helper`
que permite firmar DUAs con el token USB SINPE de Firma Digital
(BCCR). Sin el helper, la app sigue funcionando con archivos `.p12`,
pero BCCR exige el token para DUAs en produccion.

## Resumen

El helper es un proceso nativo Go (VRTV-69) que habla PKCS#11 con el
middleware del token. El cliente Flutter / server Dart lo invoca por
subproceso con JSON por stdio — ver `SubprocessPkcs11SigningAdapter`
en `libs/adapters` (VRTV-70).

El onboarding (VRTV-72) detecta el helper al entrar al paso "Firma
Digital" probando las siguientes rutas en orden:

1. `$PKCS11_HELPER_PATH` (override explicito)
2. `/usr/local/bin/aduanext-pkcs11-helper`
3. `/opt/aduanext/pkcs11-helper`
4. `./aduanext-pkcs11-helper` (cwd del desarrollador)
5. `aduanext-pkcs11-helper` via `PATH`

## Linux (BCCR Firma Digital)

```bash
# 1. Instala el middleware BCCR (Athena ASEPKCS o equivalente).
sudo apt install ifd-gempc athena-asepkcs

# 2. Descarga el helper y copialo a un directorio en PATH.
curl -L -o aduanext-pkcs11-helper \
  https://github.com/vertivolatam/aduanext/releases/latest/download/aduanext-pkcs11-helper-linux-amd64
chmod +x aduanext-pkcs11-helper
sudo mv aduanext-pkcs11-helper /usr/local/bin/

# 3. Verifica.
aduanext-pkcs11-helper --version
```

Ruta tipica del modulo PKCS#11 en BCCR Linux:

```
/usr/lib/x64-athena/ASEP11.so
```

## macOS

BCCR publica un instalador `.pkg` que deja el middleware en
`/Library/Athena/libASEP11.dylib`. Instala el helper con Homebrew:

```bash
brew install vertivolatam/aduanext/pkcs11-helper
```

## Windows

Solo escritorio — el onboarding en el navegador **no** puede detectar
ni invocar el helper porque `Process.run` no existe en Flutter Web.
Descarga la app de escritorio AduaNext (incluye el helper).

## Troubleshooting

* **"Helper binary not found"** — el binario no esta en `PATH` ni en
  ninguna de las rutas estandar. Corre `which aduanext-pkcs11-helper`.
* **"Could not load module"** — ruta del `.so`/`.dylib` incorrecta o
  arquitectura incompatible. Verifica con `file /ruta/al/modulo.so`.
* **"Token not present"** — conecta el token SINPE antes de pulsar
  "Detectar tokens" en el onboarding.

## Audit

Cada invocacion del helper deja trazas en el `AuditLogPort` con el
serial del token + CN del certificado — nunca con el PIN.
