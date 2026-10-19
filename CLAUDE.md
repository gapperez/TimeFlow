# TimeFlow — notas para seguir el desarrollo

App de iPad (también corre en iPhone) con cronómetro y temporizador que se ven en una **pastilla flotante**
encima de otras apps, inspirada en la pastilla de temporizador de Android. Idioma de la UI y de los comentarios: español.

## Decisiones tomadas (y por qué)

- **No se puede escribir en la barra de estado del iPad** (junto a la hora): iPadOS no lo permite a apps de terceros.
  Por eso se usa **Picture in Picture (PiP)**, lo más parecido.
- PiP solo admite video, así que la pastilla se **dibuja como cuadros de video**: `PillRenderer` genera un
  `CMSampleBuffer` (600×180 px, proporción 10:3) y `PiPController` lo encola en un `AVSampleBufferDisplayLayer`.
  Solo se redibuja cuando cambia lo que se muestra (`PillSnapshot`).
- PiP necesita sesión de audio `.playback` (con `.mixWithOthers` para no cortar la música) y el modo de fondo
  `audio` en `Config/TimeFlow-Info.plist`.
- El botón pausa/play de la ventanita llama a `TimerEngine` vía `AVPictureInPictureSampleBufferPlaybackDelegate`.
  El rango de tiempo es infinito para que el sistema no muestre barra de avance.
- `canStartPictureInPictureAutomaticallyFromInline = true`: si el usuario sale de la app con el tiempo corriendo, la pastilla se abre sola.
- `TimerEngine` guarda fechas (no cuenta ticks), así el tiempo es exacto aunque la app esté en segundo plano.
- **Live Activity** (pantalla de bloqueo) en el target `TimeFlowWidgets`; usa `Text(timerInterval:)` para que el
  sistema actualice el tiempo sin la app. En iPad requiere iPadOS 26.
- Aviso al terminar el temporizador con notificación local (`TimerAlerts`).
- Diseño: fondo oscuro, aro **morado** = temporizador, **verde** = cronómetro, **naranja** = terminado.
  El usuario pidió la pastilla **pequeña**, del tamaño de la de su teléfono Android.

## Estructura

- `TimeFlow/` — app: `TimeFlowApp`, `ContentView`, `TimerEngine`, `PiPController` (+ `PiPSourceView`), `PillRenderer`,
  `LiveActivityManager`, `TimerAlerts`, `Assets.xcassets` (ícono).
- `TimeFlowWidgets/` — extensión con la Live Activity.
- `Shared/` — compartido por ambos targets: `TimerMode`, `TimeFormat`, `TimerActivityAttributes`.
- `Config/` — `Info.plist` de cada target (se combinan con los generados por Xcode).
- El proyecto usa carpetas sincronizadas de Xcode 16 (`PBXFileSystemSynchronizedRootGroup`): los archivos nuevos
  dentro de esas carpetas entran solos al target, sin tocar `project.pbxproj`.

## Compilar y verificar

```sh
xcodebuild build -project TimeFlow.xcodeproj -scheme TimeFlow \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

GitHub Actions (`.github/workflows/build.yml`) corre lo mismo en cada push. Requiere Xcode 16 o más reciente.
Para instalar en el iPad: ver `README.md` (firmar ambos targets con el Apple ID del usuario).

## Estado

- [x] Proyecto inicial: compila en CI (Xcode 16.4).
- [ ] **Probar en un iPad real** — nunca se ha ejecutado en un dispositivo. Revisar:
  - que la ventanita PiP se abra (botón y al salir de la app) y que el botón pausa/play funcione;
  - el tamaño mínimo que iPadOS permite para la ventanita (¿queda tan pequeña como se quería?);
  - que el tiempo siga corriendo bien con la app en segundo plano;
  - la Live Activity en la pantalla de bloqueo (iPadOS 26) y el aviso al terminar.
- [ ] Ajustes de diseño según lo que el usuario vea en su iPad.

## Ideas pendientes (no pedidas todavía)

- Guardar el estado para que el tiempo sobreviva si se cierra la app a la fuerza.
- Vueltas (laps) en el cronómetro.
- Elegir colores de la pastilla.
