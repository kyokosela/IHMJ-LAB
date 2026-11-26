# Cambios hechos con IA (índice)

Status: En revisión
Assign: Sela (hecho con IA)

Qué cambió en el código desde el último commit del equipo (`b76315f`, Mao, 2026-01-28, *migrate project to 4.6*) hasta
`6b5c8ba` (2026-11-26). Rama: `feat/efectos-en-playermanager`.

## 📊 En números

| Qué | Cantidad |
|---|---|
| Commits | 99 |
| Scripts del juego (`.gd`) | 31 nuevos y 46 modificados · +5.983 / −346 líneas |
| Pruebas automáticas (`Tools/*.gd`) | 12 nuevas · +5.385 líneas |
| Todo el repositorio | 539 archivos (incluye arte, escenas, recursos y diálogos) |
| `addons/` (Dialogic y demás) | **sin tocar** |

**Tres etapas:** febrero 2026 (primera migración con IA: efectos, economía, asistencia, correos) · abril 2026 (pantallas de
trabajo y playground) · noviembre 2026 (apartamento jugable, cocina, ropa, tutorial, pasillo y pruebas).

## 🗂️ Fichas

| Ficha | Qué cubre | ¿En el juego real? |
|---|---|---|
| [Efectos](efectos.md) | `PlayerManager`: motor de efectos, sueño, cordura, ropa puesta | Sí |
| [Eventos y partida nueva](eventos-y-partida.md) | Eventos con hora y zona, banderas, `new_game()` | Sí (historia de relleno apagada) |
| [Interacción y puertas](interaccion-y-puertas.md) | `Interactable`, `InteractableAction`, puertas, `integration_action.gd` | Sí |
| [Zonas](zonas.md) | `ZoneManager`, `World`, cámaras, transiciones, escenas nuevas | Sí |
| [Cocina e inventario](cocina-e-inventario.md) | Cambios dentro de las clases de Ghoko | Sí |
| [Ropa, armario, ducha y espejo](ropa-ducha-espejo.md) | Pantallas de armario, ducha y lavamanos | Sí |
| [Tutorial de la mañana](tutorial.md) | Rutina de despertar a salir | Sí |
| [Trabajo, dinero y computadora](trabajo-y-computadora.md) | Asistencia, economía, correos, portal, arcade, mercado | **Parcial: prototipo** |
| [Guardado, sonido, HUD y depuración](guardado-hud-debug.md) | `SaveManager`, audio, interfaz, F3 | Guardado **incompleto** |
| [Pruebas automáticas](pruebas.md) | Qué comprueba cada script de `Tools/` | — |
| [Escalabilidad](escalabilidad.md) | Evaluación de riesgos y plan | — |

## 🧭 Reglas que sigue el código nuevo

- Managers planos en `Scripts/` y autoloads en `project.godot`. No se migró a componentes.
- Se respetan las clases existentes: los cambios dentro de clases del equipo llevan el comentario `## Completado: ...`
  (buscar `Completado` en el proyecto para verlos).
- La cocina, el almacenamiento y los ítems siguen el sistema de Ghoko; lo nuevo se configura con `.tres` y escenas.
- El diseño manda sobre el código: [`SISTEMA_GAMEPLAY.md`](../Design/SISTEMA_GAMEPLAY.md),
  [`SISTEMA_EFECTOS.md`](../Design/SISTEMA_EFECTOS.md) y pendientes en
  [`DECISIONES_Y_PENDIENTES.md`](../Design/DECISIONES_Y_PENDIENTES.md).

## ⚙️ Cambios en `project.godot` y el repositorio

- Escena principal: `Scenes/World/Apartment.tscn`.
- **7 autoloads nuevos:** `EconomyManager`, `AttendanceManager`, `RelationshipManager`, `NarrativeFlags`,
  `EmailPoolManager`, `NarrativeEventHandler`, `AudioManager`.
- Dialogic: 4 personajes y 22 líneas de tiempo nuevas; **traducción desactivada** (los ids de los `.dtl` se repiten entre
  archivos); `Z` añadida a la acción de avanzar diálogo.
- ⚠️ Se **borró** `.github/workflows/gdlint.yml` (el revisor automático de GDScript que puso Mao) en `7ff0c2f`, para poder
  subir con un token limitado. Conviene restaurarlo.
- Se reemplazó el arte provisional de ropa (blusa/uniforme) y se quitaron los `.tres` de comida duplicados en
  `Resources/Items/Data/Meals/`.
