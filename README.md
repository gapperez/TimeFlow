# TimeFlow

Cronómetro y temporizador para iPad que se quedan a la vista en una **pastilla flotante** pequeña, encima de cualquier app, sin ocupar la pantalla.

- **Pastilla flotante**: tiempo + aro de progreso con pausa/play. Se mueve a cualquier esquina, se achica o se esconde al borde.
  - Aro **morado** = temporizador (cuenta regresiva).
  - Aro **verde** = cronómetro (cuenta hacia arriba).
- **Se abre sola**: si sales de la app con el tiempo corriendo, la pastilla aparece automáticamente.
- **Pausa desde la pastilla**: tocas la pastilla y usas el botón de pausa/play.
- **Pantalla de bloqueo** (Live Activity): ves el tiempo sin desbloquear.
- **Aviso con sonido** cuando termina el temporizador, aunque la app esté cerrada.

## Cómo instalarla en tu iPad

Necesitas una Mac con **Xcode 16 o más reciente** y tu Apple ID.

1. Descarga el proyecto: en GitHub, botón **Code → Download ZIP** (o `git clone`).
2. Abre `TimeFlow.xcodeproj` con Xcode.
3. Firma la app (una sola vez):
   - En el panel izquierdo, haz clic en el proyecto **TimeFlow** (ícono azul).
   - En **Targets**, elige **TimeFlow** → pestaña **Signing & Capabilities** → en **Team** elige tu Apple ID
     (si no aparece: *Add an Account…*).
   - Repite lo mismo con el target **TimeFlowWidgets**.
   - Si Xcode dice que el *Bundle Identifier* ya está en uso, cámbialo por otro único
     (por ejemplo `com.tunombre.timeflow` y `com.tunombre.timeflow.widgets`; el segundo debe empezar igual que el primero).
4. Conecta el iPad con cable a la Mac y desbloquéalo. Acepta "Confiar en esta computadora".
5. Arriba en Xcode, elige tu iPad como destino y presiona **▶ (Run)**.
6. La primera vez, en el iPad:
   - Activa el **Modo de desarrollador**: *Ajustes → Privacidad y seguridad → Modo de desarrollador* (el iPad se reinicia).
   - Autoriza la app: *Ajustes → General → VPN y gestión de dispositivos* → tu Apple ID → **Confiar**.
7. Abre TimeFlow y acepta las notificaciones (para el aviso al terminar).

> Con un Apple ID gratis, la app deja de abrir a los **7 días**; vuelve a presionar ▶ en Xcode para renovarla.
> Con la cuenta de desarrollador de Apple (99 USD/año) dura un año y se puede instalar con TestFlight.

## Cómo se usa

1. Elige **Cronómetro** o **Temporizador** (para el temporizador, fija el tiempo con las ruedas o los atajos de 1–60 min).
2. Toca **Iniciar**.
3. Toca **Ventanita flotante**, o simplemente sal de la app: la pastilla queda encima de lo que estés usando.
4. Para esconderla, deslízala hacia el borde de la pantalla; queda una pestañita para sacarla.

## Límites conocidos

- iPadOS **no permite** que apps de terceros pongan nada en la barra de estado (junto a la hora). Por eso se usa la
  ventanita flotante (Picture in Picture), que es lo más parecido.
- iPadOS fija un **tamaño mínimo** para las ventanitas flotantes; la pastilla puede verse algo más grande que en el boceto.
- La Live Activity en la pantalla de bloqueo requiere **iPadOS 26** o posterior en iPad.
- Si cierras la app a la fuerza (deslizándola hacia arriba), el tiempo se pierde.

## Estructura

| Carpeta | Contenido |
|---|---|
| `TimeFlow/` | La app: pantalla principal, lógica del tiempo, pastilla flotante, avisos |
| `TimeFlowWidgets/` | Live Activity de la pantalla de bloqueo |
| `Shared/` | Código que usan las dos (modos, formato de tiempo, datos de la Live Activity) |
| `Config/` | `Info.plist` de la app y del widget |
| `.github/workflows/build.yml` | Compila el proyecto en una Mac de GitHub en cada cambio |


