# IHMJ-LAB — "I Hate My Job"

Prototipo personal en Godot 4.6 / GDScript. Simulador de supervivencia laboral
(Mayui: casa, trabajo de oficina, estrés/cordura/energía, economía, diálogos).
Todo el contenido del juego (UI, diálogos, emails) va en **español**.

## META ACTUAL (solo una)
**Tutorial de la mañana jugable de principio a fin:**
despertar -> asearse (ducha) -> uniforme (armario) -> cocinar/comer -> lavarse dientes -> salir.
Diseño: `Docs/Design/Flow de juego.txt`. Hasta cerrar esta meta, NO se amplía nada más
(ni playground, ni minijuegos, ni ciudad, ni contenido narrativo nuevo).

## ESTADO (actualizar al cerrar cada sesión)
- El proyecto importa y arranca sin errores graves (verificado en consola).
- La pantalla del tutorial AÚN NO está asignada como escena principal.
- Existe `Scenes/Playground_Integration.tscn` (herramienta de pruebas, desordenada). Congelada.
- Pendiente menor: 3 `.tres` con UID duplicado (`home_meal`, `ingredients_bag`, `ingredients_unpack`).
- Próximo paso: ver `NEXT.md` si existe.

## REGLAS
1. Pasos pequeños: una cosa por vez, verificarla corriendo Godot, y recién ahí un commit.
2. Nunca declarar algo "terminado" sin haber ejecutado el juego o la comprobación.
3. Mantener la arquitectura actual: managers planos en `Scripts/`, autoloads en `project.godot`.
   No reestructurar a componentes (la migración al repo principal es futura y requiere consenso).
4. Reglas de diseño resueltas: `Docs/AMBIGUITIES.md` manda sobre documentos viejos.
5. No modificar `.gd` cuando la tarea es solo contenido (`.tres`, `.dtl`, textos).
6. Verificar que existen los `.dtl` (`DialoguePlugin/TIMELINE/`) antes de llamar `Dialogic.start()`.
7. No usar git worktrees aislados; trabajar en la rama activa del repo.
8. Documentos históricos de IA (planes, handoffs) están en `Docs/archive/`: NO leerlos salvo
   que la tarea lo pida expresamente. Son largos y se contradicen entre sí.
9. Para el usuario: explicar sin jerga, pedir una sola cosa por vez.

## ENTORNO (Windows)
- Godot 4.6: `D:\Tools\Godot-4.6\Godot_v4.6-stable_win64.exe` (consola: `..._console.exe`)
- Git: `C:\Program Files\Git\cmd\git.exe` (puede no estar en PATH).
- Remoto: github.com/kyokosela/IHMJ-LAB
- Verificar sin abrir el editor (PowerShell, desde el proyecto):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . --import`
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . --quit-after 600`
  Buscar líneas `SCRIPT ERROR` / `ERROR`. Ruido conocido e ignorable: aviso del dock "EditorView" de Dialogic.
- Si algo no se refleja en Godot: cerrar Godot, borrar la carpeta oculta `.godot/` y reabrir.

## MODELOS (plan Pro, ahorrar tokens)
- Sonnet: trabajo diario (código, arreglos, conectar sistemas).
- Haiku: cambios mecánicos (renombrar, números, textos, llenar `.tres`).
- Opus: solo diseño de estructura o bugs que Sonnet no resuelve en 2 intentos.
- Sesiones cortas y con un objetivo; no releer documentos largos al inicio.
