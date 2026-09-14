# Claude Account Switcher

App de menu bar para macOS que permite cambiar rápido entre dos cuentas de
[Claude Code](https://claude.com/claude-code) (por ejemplo, personal y laboral) sin
repetir el flujo completo de login — incluyendo el código de verificación por correo —
cada vez.

## Cómo funciona

1. Por cada cuenta, corres `claude setup-token` una sola vez (pasando por el login
   normal, incluido el código de correo si tu organización lo pide). Esto genera un
   token OAuth de larga duración — el mecanismo oficial de Claude Code para
   autenticación sin login interactivo (pensado originalmente para CI/CD).
2. Pegas ese token en la app, que lo guarda en el macOS Keychain usando
   `Security.framework` directamente (nunca como archivo plano ni como argumento de
   proceso).
3. Al elegir una cuenta desde el menú, la app abre una nueva ventana de Terminal con
   `CLAUDE_CODE_OAUTH_TOKEN` cargado para esa cuenta y lanza `claude` — sin pasar por
   el navegador ni por ningún código de verificación.

El token viaja del Keychain a la Terminal a través de un FIFO (named pipe): nunca se
escribe a disco. `open()` en modo no bloqueante para escritura solo tiene éxito cuando
ya hay un lector esperando (la Terminal, vía `cat`), así que los bytes fluyen directo
por un pipe del kernel entre ambos procesos.

Este mecanismo no toca ni interfiere con el login normal de `claude login` — es
paralelo y no destructivo.

## Requisitos

- macOS 13+
- Swift 5.9+ (Xcode Command Line Tools)
- Una suscripción de Claude (Pro/Max/Team) por cada cuenta que quieras vincular

## Build

```bash
./build.sh
open ".build/Claude Account Switcher.app"
```

## Stack

SwiftUI (`MenuBarExtra`), Security.framework, AppleScript (para abrir Terminal.app).
Sin dependencias externas.
