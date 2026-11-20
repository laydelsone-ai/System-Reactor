# World Laboratory Android — Paquete técnico 0.1.0

**Estado:** diseño técnico + scaffold ejecutable inicial, no laboratorio terminado.

Este paquete continúa el universo RPG definido en SR-01 a SR-07. No reemplaza, modifica ni consolida esos documentos normativos. El proyecto todavía no demuestra autonomía completa, simulación masiva ni cumplimiento íntegro de las leyes físicas/arcanas: esta entrega prepara la base técnica y una primera escena de observación.

## Decisiones fijadas

- Android, funcionamiento local y offline.
- Godot **4.7.2-stable**, Standard, GDScript.
- Renderizador Compatibility como punto de partida Android.
- Escena 3D con cámara ortográfica isométrica: experiencia 2.5D.
- Agentes autónomos; no se crea jugador humano en la inicialización.
- Mundo individual con catchup al regresar.
- Persistencia local: snapshot versionado + diario append-only de eventos.
- Sin servidor, cuenta, base de datos remota, API de IA ni permiso de Internet obligatorio.
- GitHub Actions exporta un APK Debug como artefacto descargable.

## Contenido

- `docs/01_ESPECIFICACION_TECNICA.md`: arquitectura, contratos, decisiones, scheduler, catchup, identidad, eventos, assets, seguridad, pruebas y etapas.
- `docs/02_MATRIZ_SR.md`: trazabilidad con SR-01 a SR-07 y límites de lo que esta primera base implementa.
- `docs/03_DECISIONES_TECNICAS.md`: decisiones técnicas asumidas y puntos que quedan como riesgo o configuración.
- `project/`: estructura inicial Godot, código base, escena isométrica de prueba, pruebas de contrato y workflow de GitHub Actions.

## Estado real de esta entrega

Incluye un núcleo inicial de reloj/catchup, generación determinista de entidades de prueba, un ciclo de decisión muy básico, validación de comandos, registro local de eventos, snapshots locales y replay básico de cuatro tipos de eventos, junto con una representación 2.5D de modelos proxy construidos con primitivas. Los modelos proxy **no son los modelos artísticos definitivos**.

No incluye todavía: navegación completa, combate, sistema social, economía avanzada, reproducción histórica, investigación, magia funcional SR-07, evolución/reencarnación funcionales, generadores completos de misiones, mapas grandes terminados ni un sistema cognitivo humano-equivalente.

## Cómo usarlo

1. Descarga y descomprime este paquete.
2. Abre `project/` con Godot 4.7.2 Standard.
3. Ejecuta la escena principal.
4. Para pruebas de contratos, ejecuta desde una terminal con Godot instalado:

   ```bash
   godot --headless --path project -s project/tests/test_contracts.gd
   ```

5. Para compilar Android localmente, configura JDK 17, Android SDK y las plantillas de exportación de Godot 4.7.2. La documentación oficial indica esos requisitos para exportar desde Linux/Windows/macOS: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
6. Para GitHub, sube el contenido de `project/` a la raíz de un repositorio. El workflow `.github/workflows/android.yml` compila y publica el APK Debug en Actions > Artifacts.

## Advertencia de compilación

El paquete se ha generado y verificado estructuralmente, pero este entorno no tiene el ejecutable de Godot ni acceso a descarga de binarios, así que **no he podido ejecutar el parser de Godot ni verificar un APK real** aquí. El workflow de GitHub Actions está preparado para realizar esa verificación cuando se suba el proyecto. No afirmo que el APK ya esté compilado.

## Procedencia

Las reglas de referencia son los archivos incluidos en `RPG_Continuidad_Maestra_SR-01_a_SR-07.zip`, entregado previamente. El ZIP de este paquete no duplica los documentos normativos para evitar crear copias divergentes.
