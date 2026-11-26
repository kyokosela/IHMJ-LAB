# Escalabilidad: evaluación

Status: En revisión
Assign: Sela (hecho con IA)

**Pregunta:** por cómo se ha programado con IA, ¿el proyecto está en riesgo? ¿Hará falta pagar a un desarrollador?

⚠️ **La evaluación la hizo la misma IA que escribió buena parte del código.** Sirve como mapa, no como auditoría
independiente. Revisado el 2026-11-26 sobre `6b5c8ba`: lectura de los cambios de código y comprobaciones en Godot
(guardado, paga y alarma). **No** se revisaron a fondo las escenas, el rendimiento, un ejecutable exportado ni el código del
equipo que no cambió.

## 🚦 Veredicto

**Riesgo medio. No hace falta reescribir.** La base aguanta el tutorial, pero hay problemas que se vuelven caros si la
oficina se construye encima.

## ✅ Lo que está a favor

- Se mantuvo la arquitectura del equipo (managers planos y Resources); `addons/` sin tocar.
- Ítems, recetas, ropa, tareas y eventos se configuran con `.tres`.
- 12 scripts de pruebas (725 comprobaciones, 0 fallas) que avisan si algo se rompe.
- Documentos de diseño y pendientes numerados; los cambios en clases del equipo están marcados con `Completado`.

## 🔴 Riesgos

| # | Riesgo | Gravedad | Evidencia | Arreglo | Tamaño |
|---|---|---|---|---|---|
| 1 | **El guardado no sirve para una semana de juego** | Alta | Probado: solo vuelve el dinero; se pierden día, hora, cordura, energía, efectos y ropa | Que cada sistema guarde lo suyo, guardar al dormir y una prueba | Mediano |
| 2 | **`player_manager.gd` lo hace todo** | Alta a futuro | 1.470 líneas, 110 funciones: efectos, sueño, cordura, hábitos y ropa | Partirlo en varios archivos sin cambiar lo que hace | Mediano |
| 3 | **Errores que las pruebas no vieron** | Media | Probados: el viernes no se paga (800 en vez de 1.000) y la alarma no despierta a la hora elegida ([Efectos](efectos.md)). Además, en el prototipo de trabajo: tardanza distinta al diseño, 27 correos fijos en la evaluación y dos managers huérfanos | Corregirlos con prueba y decidir qué se conserva antes de construir la oficina | Mediano |
| 4 | **Un ejecutable podría fallar** | Media | Estadísticas, eventos, ítems y correos se cargan listando carpetas con `DirAccess`, que en juegos exportados ve archivos `.remap` ([foro de Godot](https://forum.godotengine.org/t/a-proper-way-to-grab-a-list-of-directory-files-that-wont-break-on-export-file-remapping/91983)). El patrón viene del código original y se repitió. **Sin comprobar** | `ResourceLoader.list_directory()` y exportar una vez | Pequeño |
| 5 | **Contenido atado al código** | Media | Cada evento nuevo necesita tocar un `match`; banderas, efectos y tareas son texto libre; muchas frases escritas dentro de los scripts | La oficina como **datos** (`.tres` y CSV) desde el primer día | Continuo |
| 6 | **`integration_action.gd`** | Media | 51 acciones, juego y trampas de prueba mezclados | Una acción por archivo | Mediano |
| 7 | **"Mañana del tutorial" definida de dos formas** | Baja | Repetida en varios scripts (ver [Tutorial](tutorial.md)) | Una sola función | Pequeño |
| 8 | **Sin revisor automático** | Baja | Se borró `gdlint.yml` | Restaurarlo | Pequeño |
| 9 | **Traducción apagada** | Baja ahora | Ids repetidos en los diálogos | Ids únicos antes de traducir | Mediano |

## 💰 ¿Pagar a un desarrollador?

| Opción | Recomendación |
|---|---|
| Que reescriba el juego | **No.** Nada de lo visto lo justifica |
| Revisión puntual de pocas horas | **Sí**, después de arreglar 1–3 y antes de la oficina. Primero pedírsela a un dev del equipo, con esta ficha como guion |
| Seguir solo con IA | Viable **con reglas**: ninguna función sin prueba, cada sistema documentado y alguien que lea el código cada cierto tiempo |

**Señales para volver a evaluar:** un arreglo rompe otra cosa dos veces seguidas, nadie sabe explicar un archivo, o añadir
un correo o un personaje exige tocar código.

## 🛠️ Orden propuesto

1. Guardado completo, con su prueba.
2. Alarma, paga del viernes y limpieza del prototipo de trabajo.
3. Partir `player_manager.gd` (las pruebas vigilan que nada cambie).
4. Preparar la exportación y restaurar el revisor.
5. Construir el piso 1 como datos.
