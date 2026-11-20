# World Laboratory Android — Fix 0.1.1

Esta entrega intenta corregir la pantalla gris/negra observada en Android.

## Qué se cambió

- La escena principal declara directamente `WorldEnvironment`, `Camera3D`, luz, suelo y HUD. No dependen de que `main.gd` los cree en `_ready()`.
- El fondo usa un color explícito, no `BG_SKY` sin un recurso Sky asociado.
- La cámara ortográfica está declarada en la escena y marcada como actual.
- Se añadió una escena visible con edificios/proxies geométricos y un grupo de agentes de prueba.
- El HUD incluye una etiqueta de arranque declarada en `.tscn`; si el script falla todavía debería verse el HUD y el entorno estático.
- El script escribe marcadores `WLA_BOOT_OK` y `WLA_RUNTIME_ERROR` en el log y muestra los errores de inicio en la interfaz cuando puede.

## Importante: no afirmar de más

Esto es una corrección diagnóstica y una escena de laboratorio temprana, no el juego completo ni una prueba de autonomía avanzada. Los modelos son cápsulas/esferas provisionales. El movimiento de agentes en este paquete es una demostración simple de agentes por necesidades, no el comportamiento definitivo de SR-03.

## Instalación en GitHub

Sube el **contenido de `project/`** a la raíz del repositorio `System-Reactor`, reemplazando al menos `project.godot`, `scenes/main.tscn` y `scripts/app/main.gd`. Conserva el workflow que ya está funcionando; se incluye una copia del workflow conocido como referencia.

Después confirma el cambio y descarga el nuevo APK de Actions.

## Qué observar en el siguiente APK

1. Debe aparecer un fondo azul oscuro, suelo verde cuadriculado, edificios/cubos de prueba y modelos proxy.
2. Debe verse un panel superior con `WORLD LABORATORY` y estado de arranque.
3. Si aparece el panel rojo `ERROR DE INICIALIZACIÓN`, copia su texto.
4. Si vuelve a salir toda la pantalla gris, el APK probablemente no está ejecutando esta escena o se está usando otra carpeta/preset. En ese caso necesitamos el logcat del proceso `org.worldlaboratory.android`.

## Honestidad de validación

En este entorno no está instalado Godot 4.7.2 ni se ha podido exportar un APK. El ZIP y su estructura sí se validan, pero este parche aún requiere la siguiente compilación GitHub Actions y una prueba real en tu teléfono.
