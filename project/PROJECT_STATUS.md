# Estado del proyecto — 0.1.0

## Incluido
- Proyecto Godot con escena principal 3D/cámara isométrica.
- Generación inicial determinista de 64 personajes + 24 criaturas proxy.
- Reloj del mundo y cálculo básico del tiempo ausente.
- Scheduler basado en próximas evaluaciones.
- Ciclo cognitivo demostrativo muy limitado: hambre, fatiga y selección entre comer, recolectar, descansar y patrullar.
- Contrato de comandos con validación de capacidad/recursos e idempotencia.
- Eventos locales con confirmación, difusión y disposición separadas.
- Snapshot local con respaldo, journal NDJSON y replay básico de cuatro tipos de eventos.
- Pruebas automatizadas iniciales para catchup, seed e idempotencia.
- Workflow de GitHub Actions para APK Debug.

## No incluido / no demostrado
- Replay/recuperación transaccional general para todos los dominios aún no implementado.
- No hay autonomía cognitiva profunda ni razonamiento social complejo.
- No hay sistema de percepción sensorial completo, memoria a largo plazo ni aprendizaje real.
- No hay combate, economía, gremios, reproducción ni evolución funcional.
- No hay mundo multi-región terminado, navegación ni mazmorra funcional.
- No hay física/química/magia completas conforme SR-07.
- Los modelos son cápsulas proxy sin assets artísticos, rigging ni animaciones.
- No se ha ejecutado el parser de Godot ni compilado un APK en este entorno.

## Próxima implementación
WLA-0A/0B: importar y compilar en CI, corregir cualquier incidencia real de motor/exportación, validar guardado/recuperación en Android y medir catchup. Después desarrollar agentes con percepción, memoria y trazas completas antes de ampliar los sistemas de mundo.
