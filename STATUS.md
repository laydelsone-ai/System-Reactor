# Estado 0.1.1

- La escena estática tiene fondo, cámara, luz, suelo y panel HUD declarados en TSCN.
- main.gd agrega una región cuadriculada y 24 modelos proxy (18 humanoides y 6 criaturas).
- Hay decisiones simples demostrativas por hambre/fatiga y desplazamiento aleatorio limitado.
- Catchup aún no está plenamente aplicado a todas las entidades; el código solo calcula/registrar un candidato al reabrir. No confundir esto con catchup causal completo.
- El guardado actual contiene un resumen mínimo, no la historia íntegra del mundo.
- No demuestra autonomía avanzada, memoria, reproducción completa del Chronicle, navegación, combate o mundo a gran escala.
- Este parche requiere un nuevo build de Actions y una prueba física en Android.
