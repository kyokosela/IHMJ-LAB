# Decisiones, pendientes y hoja de ruta
**Acompaña a [SISTEMA_GAMEPLAY.md](SISTEMA_GAMEPLAY.md) · 2026-11-21**

## Cómo usar esto (para ti, Ramiro)
1. Lee las **decisiones D1–D8** primero (son las que más cambian el juego). El resto puedes aprobarlas de golpe.
2. Si no estás de acuerdo con una: cambia el valor en la tabla de `SISTEMA_GAMEPLAY.md` o dime "D5 al revés". Yo alineo el código.
3. Los **pendientes P1–P14** son cosas que tus documentos nunca definieron: responde las que quieras, en el orden que quieras. **P1, P3, P4, P5, P6 y P12 ya están cerrados** en [SISTEMA_EFECTOS.md](SISTEMA_EFECTOS.md) (huecos E1–E13); revisa esa tabla antes de decidir nada de efectos.

**Cómo decidí cuando tus fuentes se contradecían:** 1) tus respuestas directas (PR#, FJ#) > 2) `Diseño de Gameplay` > 3) `Ficha de acciones`, `Jugabilidad`, `Flujo` > 4) fichas de ítems > 5) documentos de IA. Y cuando una regla específica choca con una general, gana la específica.

---

## 1. Decisiones de unificación (contradicciones resueltas)
| ID | Tema | Qué decían tus fuentes | Decisión | Si no te gusta |
|---|---|---|---|---|
| **D1** | Despertador | Ficha: "chance de despertarse según energía" · PR45/FJ: sin azar, solo permite saltarse el mínimo · Diseño: Insomnio "anula la ayuda del Despertador" | Sin Insomnio: determinista (puedes dormir menos del mínimo). Con Insomnio: solo funciona con chance según energía (25/45/65/80/95 %); si falla, duermes el rango aleatorio del nivel. Reconcilia las tres y es lo que ya hace la alarma | Quitar el chance: con Insomnio el despertador falla siempre |
| **D2** | Café | Ficha de ítem: Hiperactivo 2 h · FJ9: "activa ATENTA… al reactivarse → Insomnio" · Diseño: Café → Hiperactividad 100 % y "café con energía >90 → Insomnio" | Café → **Hiperactividad** 2 h. Si ya hay Hiperactividad (incluida la de energía ≥90) → **Insomnio**. Leí "Atenta" de FJ9 como lapsus de "Hiperactiva": las dos reducen costo de energía y la fila "Hiperactivo + Hiperactivo → Insomnio" lo explica | Si de verdad querías Atenta, cambia la fila del café en §5.3 |
| **D3** | Comida instantánea | Ficha de ítem: 25 % de Estrés · FJ10: 50 % | **50 %** (tu respuesta directa manda) | Cambia el número en §5.4 |
| **D4** | Ducha | Ficha: −5 energía, 25 min, −1 Estrés si hay agua caliente · Flujo: "sube la energía mínimamente" · FJ7: agua fría → Estrés (prob.) y a veces Atenta | −5 energía y 25 min. La sensación de "espabilarse" es la **Atenta breve** del agua fría. El tutorial no tiene agua caliente | Si quieres +energía: cámbialo en §5.3 |
| **D5** | Orden del tutorial | Flujo (Notion, "sin iniciar"): ducha → cepillarse → armario → cocina · `Flow de juego.txt`: ducha → armario → cocina → cepillarse → puerta | `Flow de juego.txt`: cepillarse **después** de comer, porque la comida instantánea ensucia la boca (FJ10) | Invertir los pasos en §8 |
| **D6** | Alquiler | Diseño y Jugabilidad: **miércoles** 17:00 · eventos de la IA: recordatorio jueves y vence viernes | Vence el **miércoles 17:00**. Jueves 18:00 el casero avisa solo si no pagaste; domingo: aviso final o desalojo. Servicios: viernes 13:00 (las "facturas" de Jugabilidad = alquiler + servicios) | — |
| **D7** | Resultados y salario | Diseño: "Finaliza (tabla de resultados/pago) 17:00" · IA: evaluación 15:00, salario 16:00; además el código paga también al cambiar de semana | Viernes **17:00**, una sola vez. La evaluación no cambia el salario; solo el progreso del token | — |
| **D8** | Unidad del Estrés | Ficha: "Estrés −8 % (cama A −6 %, B −2 %)", piso 20 % · Tabla de efectos: niveles I–III | Estrés se mide **solo en niveles**. Dormir con horas completas = −1 nivel; 2 noches seguidas lo anulan; si hubo jornada laboral el piso es nivel I (tu "20 %"). Los bonos de estrés de las camas se traducen en proporción: A +75 %, B +25 % de un −1 extra (E10) | — |
| **D9** | Escalada de niveles y lectura de "(I/II/III)" | Tabla: "Estrés II = I + 1 día" y otra columna "Cordura <30 → 50 %" | Se combinan: sube de nivel si se cumplen los días **y** la cordura, con tirada diaria del 50 %. Calma igual, exigiendo Rutina saludable. Las probabilidades "(I/II/III)" de efectos sin nivel propio usan el nivel del primario activo | — |
| **D10** | Salud | "Estadísticas descartadas" lista la Salud · FJ6: Salud 0 = Game Over; Hambre e Insomnio restan salud | La Salud **existe** (es la muerte). La tabla de rangos y el "Colapso (3–7 días perdidos)" quedan fuera de la demo | — |
| **D11** | Duración del Insomnio | Texto: "de 1 a 6 horas" · tabla por nivel: 4–7 / 2–6 / 0–3 | La tabla (más específica) | — |
| **D12** | Suciedad | Tabla: >24 h · código: 16 h · FJ10: dos formas de quitarla (ducha / dientes) | **24 h** y **dos capas**: cuerpo → ducha, boca → cepillarse | — |
| **D13** | Hambre por esfuerzo | La tabla pone "gastar +80 % de energía 3 veces" como *mitigación* (no tiene sentido) · el código lo usa como *causa* (120) | Lo trato como **causa**: ≥120 de energía gastada desde la última comida | — |
| **D14** | Hiperactividad | Aparece como estado de energía (≥90) y como efecto con causas propias | Un solo efecto con 4 causas: energía ≥90, Atenta, Estrés, café | — |
| **D15** | Calma | "Provocado por Rutina saludable" · el código usa solo la cordura | Ambas vías; la Rutina saludable es obligatoria para escalar. 🟡 Cuenta si cumples las 4 obligatorias | — |
| **D16** | Fin de Estrés III | Tabla: "otorga Insomnio al mitigar por completo" · el código otorga Calma | **Insomnio** (tabla). Calma III anulada → Estrés (ya coincide) | — |
| **D17** | Atenta y Estrés | Diseño: Atenta **reduce** el Estrés en tareas extra · el código **suma** 5 % de riesgo | Diseño | — |
| **D18** | Energía base | Diseño: 45 · recurso del juego: 50 | **45** | — |
| **D19** | Almuerzo | Diseño: 13:00–13:45 · `attendance_manager`: hasta 14:00 | **13:45** | — |
| **D20** | Bus | Diseño: pasa 07:30 y 17:30 · código: cobra S/10 en cualquier momento | Bus solo a esas horas; fuera de horario, a pie con costo creciente (FJ5) | — |
| **D21** | Límites de acciones | Diseño: límites por día, cooldown, General con 3 usos · código: todo repetible sin fin | Se aplica tu regla: Activas con límite diario y cooldown; al agotarse pasan a General | — |
| **D22** | Documentos de IA | `AMBIGUITIES.md` y los planes contradicen tus tablas en varios puntos | Mandan **tus** documentos; los de IA solo rellenan huecos (🟡) | — |
| **D23** | Llegar tarde | Flujo: "Son las 8:05, no vas tarde" · código: tarde si pasa de 08:00 | 🟡 Tolerancia de 10 min (tarde después de 08:10) | Poner 0 y cambiar el texto del Flujo |

---

## 2. Pendientes: lo que tus documentos nunca definieron
| ID | Qué falta | Mi valor por defecto |
|---|---|---|
| **P1** | **Estabilizador de la cordura** (tu propia nota), piso por ramificación y rebalanceo semanal del domingo | ✅ **Cerrado** en [SISTEMA_EFECTOS §2](SISTEMA_EFECTOS.md) (E8) |
| **P2** | **Lista maestra de tareas** del juego (no solo del trabajo) y qué pasa si se dejan sin hacer | — |
| **P3** | Niveles de **Sueño, Atenta, Inapetencia, Hipersomnia** (en tu tabla las filas están vacías) y cómo se mitigan Inapetencia e Hipersomnia. Insomnio exige "Sueño III" | ✅ **Cerrado** (E1–E4) |
| **P4** | **Calma III**: la tabla dice "−8 % de prevención de pérdida de Cordura" (¿12 %?) | ✅ **Cerrado**: 12 % (E6) |
| **P5** | **Debilitamiento**: "30 % diario en L3" (¿de qué efecto?) y "50 % en la 4.ª acción" (¿tras qué?) | ✅ **Cerrado** (E3): L3 = "Agotada", tercera fila de tu tabla de energía |
| **P6** | Lista de **diálogos y acciones agresivas** (tu sección está vacía) y qué es "comida favorita" | ✅ **Cerrado** (E5 Desahogo; E9 Antojo) |
| **P7** | **Azotea**: el evento del sábado choca con "nadie sube salvo para ascender" | fuera de la demo |
| **P8** | Monto de los **servicios públicos** y consecuencia de no pagarlos | — |
| **P9** | Efectos de **Maloliente en las relaciones** (reemplaza al crédito social descartado) | NPCs te evitan |
| **P10** | **Deudas invisibles**: con quién, cuánto y umbrales de Estrés | no implementado |
| **P11** | `IMHJ_Documento_Maestro_v2.md` y `IMHJ_Respuestas_Consolidadas_v1.md` **no están en el repo ni en este PC**. De ahí vienen S/200 por día y algunos horarios | busca el original en la otra máquina |
| **P12** | **Camas A/B**: el bono de estrés (−6 % / −2 %) no tiene traducción a niveles | ✅ **Cerrado** (E10): A +75 %, B +25 % de un −1 extra |
| **P13** | Cómo se consiguen **la cama, el despertador y el teléfono** (Dormir pide "objeto en inventario") | todo jugador tiene cama tipo C y despertador |
| **P14** | Números de **tareas extra / token de ascensión** y su costo de Estrés (dijiste "balancéalo") | 3 tareas extra |

---

## 3. Matriz diseño ↔ código (verificada hoy)
**✅ Ya coincide**
- Energía: umbrales (≥90 Hiperactividad, ≤15 Cansancio, 0 Debilitamiento) y sus efectos.
- Números de los recursos de efecto: Estrés +3/8/15 % de tiempo · Calma −3/6/10 % · Hipersomnia +25 % · Atenta −25 % · Hambre +15 % · Sueño +15 % · Cansancio ×1,5 de tiempo y −75 % de energía · Debilitamiento ×2 y 72 h.
- Éxito laboral con Estrés: 90 / 75 / 50 %. Aparición por cordura: 25 / 50 / 50 %. Estrés y Calma se reducen entre sí.
- Insomnio: rangos 4–7 / 2–6 / 0–3 h, sus disparadores, recuperación en 2 noches, Atenta tras 2 días.
- Sueño: horas mínimas, energía por horas (38/40, ya corregido), camas A/B, una vez al día, alarma con chance solo con Insomnio (D1).
- Trabajo 08:00–17:00 y pausa 13:00. Eventos con diálogo **por zona** y cámara por zona (hecho hoy).

**❌ Difiere o falta** (ordenado por impacto al jugar)
| # | Qué | Dónde está hoy | Fase |
|---|---|---|---|
| 1 | Bañarse hace 30 min, sin energía, sin Estrés, sin cooldown, sin jabón | `integration_action.gd` (`_do_bathe`) | F2 |
| 2 | Todo es repetible sin límite; no existe el tipo General (3 usos) | `Apartment.tscn` (`reusable = true`) | F2 |
| 3 | La puerta del tutorial solo exige ducha y ropa (faltan comer y cepillarse) | `tutorial.gd` | F2 |
| 4 | Calma no usa Rutina saludable | `player_manager.gd` | F3 |
| 5 | Escalada de niveles automática por días, sin tirada 50 % ni umbral de cordura | `player_manager.gd` (`_check_level_escalation`) | F3 |
| 6 | Estrés III mitigado otorga Calma (debe ser Insomnio) | `player_manager.gd` (`_grant_opposite_primary_effect`) | F1 |
| 7 | Atenta suma 5 % de riesgo de Estrés (debe reducirlo) | `interactable_task.gd` | F1 |
| 8 | Suciedad a las 16 h y un solo efecto (sin capas cuerpo/boca) | `game_manager.gd` (`new_game`) | F1 / F3 |
| 9 | Energía base 50 (debe ser 45) | `Resources/Stats/stats/stat_energy.tres` | F1 |
| 10 | Almuerzo hasta 14:00 (debe ser 13:45) | `attendance_manager.gd` | F1 |
| 11 | Hiperactividad solo por energía ≥90 y café; faltan Atenta y Estrés | `player_manager.gd` | F3 |
| 12 | Inapetencia es un efecto sin números (no reduce éxito ni energía al comer) | `Resources/Effects/Effects/inapetencia.tres` | F3 |
| 13 | El evento `RENT` (miércoles 17:00) no dispara nada; el cobro lo hacen eventos del jueves y viernes | `Resources/Events/` + `narrative_event_handler.gd` | F4 |
| 14 | El salario se paga el viernes 16:00 **y** al cambiar de semana | `narrative_event_handler.gd` + `attendance_manager.gd` | F4 |
| 15 | Advertencias de renta suben por pagos fallidos, no por días; sin deudas invisibles (dinero nunca <0) | `economy_manager.gd` | F4 |
| 16 | Bus siempre disponible a S/10, sin horarios 07:30 / 17:30 | `zone_manager.gd` | F4 |
| 17 | Tolerancia de llegada (D23) | `attendance_manager.gd` | F4 |
| 18 | Guardado solo al final del día: no verificado (hay guardado de depuración con Shift+S/L) | `game_manager.gd` | F5 |

---

## 4. Hoja de ruta (una fase a la vez, cada una con prueba automática)
| Fase | Qué se hace | Cómo lo verifico |
|---|---|---|
| **F1 · Números en un solo sitio** | Un archivo `game_rules.gd` con todas las constantes etiquetadas con el § de este documento; migrar las dispersas. Arreglar #6, #7, #8 (24 h), #9, #10 | Prueba que lee `game_rules` y comprueba cada valor contra este documento |
| **F2 · Fichas de acción** | Recurso `ActionSheet` con **tu plantilla** (tipo, costes, elimina/aplica, límite diario, cooldown) y un solo ejecutor. Migrar Bañarse, Cepillarse, Cambiarse, Comer, Dormir e Inspeccionar. Tutorial completo con sus 4 pasos | Ducharse dos veces seguidas: la segunda entra en cooldown; no se sale sin los 4 pasos |
| **F3 · Efectos completos** | Implementar [SISTEMA_EFECTOS.md](SISTEMA_EFECTOS.md): Rutina saludable, escalada con tirada y umbral, Suciedad en dos capas, niveles de Atenta/Hipersomnia/Inapetencia/Sueño, Desahogo, estabilizadores de cordura (rebote, tope, piso), deuda de sueño con tope y los ítems Pastillas/Medicina/Mentas/Antojo | Reproducir en el juego real los perfiles de `Tools/simulacion_efectos.gd` y comparar resultados |
| **F4 · Calendario y economía** | Alquiler el miércoles y avisos, servicios, pago único el viernes 17:00, bus por horario, deudas invisibles, tolerancia 08:10 | Recorrer la semana con y sin pagar y comparar con §7 |
| **F5 · Guardado y pantalla** | Guardado al dormir; HUD con efectos, hora, energía, día y dinero | Guardar, cargar y comparar estado |

**Costo en tokens (plan Pro):** cada fase cabe en sesiones cortas. Sonnet para F1–F4; Haiku para ajustar números; Opus solo si F3 se atasca. Antes de cada fase leo **solo** `CLAUDE.md` y la parte de este documento que toca.

**Estado de lo ya hecho hoy:** arranque en el apartamento · zoom y cámara por zona · tecla Z para todo · reloj arriba · eventos por zona · correcciones de crash y repeticiones (todo sin commitear).
