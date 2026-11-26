# Pruebas automáticas

Status: Completado
Assign: Sela (hecho con IA)

Cada script abre el juego real, hace cosas y comprueba resultados. Imprime `FALLA` por cada error y el total al final.
Última corrida completa (2026-11-26): **826 comprobaciones, 0 fallas**.

## Cómo correr una

Desde la carpeta del proyecto:

```powershell
& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_efectos.gd
```

(Cambiar la ruta de Godot según el equipo.)

| Script | Comprueba |
|---|---|
| `probar_efectos.gd` | Motor de efectos con reloj y cambio de día reales |
| `simulacion_efectos.gd` | Simula semanas para validar los números del diseño |
| `probar_flujo.gd` | Zonas, pantallas, diálogos, asistencia, apartamento |
| `probar_crafteos.gd` | Cocina: nada se duplica ni se pierde |
| `probar_ropa.gd` | Ropa y armario |
| `probar_espejo.gd` | Lavamanos y cepillado |
| `probar_tutorial.gd` | La mañana completa |
| `probar_voy_tarde.gd` | Avisos pasadas las 07:30 |
| `probar_alarma.gd` | Despertador: pantalla, hora de despertar, Insomnio y deuda de sueño |
| `probar_paga.gd` | Paga semanal: viernes 17:00, una sola vez, descuentos y casos límite |
| `probar_guardado.gd` | Guardar al despertar y cargar: todo vuelve igual (también la estufa cocinando), tras ir a la oficina y volver, desde la oficina y tras cerrar y abrir el juego (segundo proceso) |
| `probar_cuarto.gd` | Paredes, muebles y puertas de casa y edificio |
| `jugar_manana.gd` | Juega la mañana con teclas y ratón; puede guardar fotos |
| `probar_torpe.gd` | Insiste en todo y desordena la cocina |
| `probar_mono.gd` | Teclas y clics al azar: atascos y paredes atravesadas |

## ⚠️ Límites

- El guardado, la paga y la alarma tenían errores sin detectar: ya tienen su prueba. Las que duermen apagan el guardado
  automático (`GameManager.autosave_enabled`) o usan otra ranura, para no pisar la partida del jugador.
- Algunas dependen de posiciones exactas: mover un mueble obliga a actualizar la prueba.
- Los diálogos solo reciben teclas con `Input.parse_input_event`.
- Ninguna prueba un ejecutable exportado.
