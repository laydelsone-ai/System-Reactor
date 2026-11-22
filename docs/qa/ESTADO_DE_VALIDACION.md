# Estado de validación — WLA-0B Autonomy Trial 0.3.0

## Validado en este entorno

- Integridad estructural y preflight del proyecto empaquetado.
- Los JSON incluidos parsean correctamente.
- Registro Social v0.2.0: 180 personas, 60 del reparto principal, 120 de población de fondo, 40 grupos de hogar, 240 enlaces `same_household_member`, 4 declaraciones sin resolver. No se fabrican residencias.
- El JSON social se reproduce con igualdad estructural desde las fuentes preservadas.
- Bestiario Piso 1: cinco perfiles cotejados contra el CSV de estadísticas fuente.
- Las 12 plantillas de misión coinciden con su fuente.
- PNG, recursos, atlas, iconos adaptativos y tamaños del export preset Android.
- Preflight de versión WLA-0B, presencia de runtime/pruebas y ejecución de `tests/test_autonomy.gd` en CI.

## Pruebas de motor incluidas, todavía no ejecutadas aquí

`tests/test_autonomy.gd` comprueba:

- Inicialización de los 180 modelos sin jugador.
- Desconocidos fuente que permanecen desconocidos (perfil cognitivo, rasgos, household, identidad y ubicación).
- Prohibición de convertir áreas laborales en coordenadas o co-presencia.
- Aptitudes y rasgos conocidos que modifican utilidades; aptitudes desconocidas no reciben bonificación inventada.
- Éxito/fracaso recordado que altera decisiones posteriores.
- Límites sensoriales (la ecolocalización se degrada con ruido).
- Decisiones específicas de especies, movimiento, búsqueda/consumo de recursos y respuesta fisiológica fúngica.
- Cobertura del scheduler de toda la población y reproducibilidad con semilla fija.
- Persistencia por snapshot y reconstrucción desde journal.

## No ejecutado en este entorno

- Import/parsing GDScript con Godot 4.7.2.
- Pruebas `test_contracts.gd`, `test_content_data.gd`, `test_autonomy.gd` dentro de Godot.
- Smoke test de escena.
- Exportación de Android Debug APK.
- Instalación, rendimiento, ciclo de vida, force-stop y recuperación en Android físico.

**Motivo:** el contenedor no incluye el motor Godot y la red de descarga no pudo resolver GitHub. No se declara APK compilada ni prueba GDScript aprobada.

## Verificación en GitHub Actions

`.github/workflows/android.yml` instala Godot 4.7.2 Standard, Java 17 y los componentes Android fijados; importa el proyecto; ejecuta contratos, contenido, autonomía y smoke test; exporta Android Debug y sube APK + SHA-256. WLA-0B.2 solo debe considerarse validado por motor después de que esa ejecución termine correctamente.
