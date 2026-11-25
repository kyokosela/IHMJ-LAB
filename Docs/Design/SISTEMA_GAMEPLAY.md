# Sistema de Gameplay — "I Hate My Job"
**Versión unificada v1 · borrador para tu revisión · 2026-11-21**

> Esta es la **única fuente de verdad** del gameplay. Si algo se cambia aquí, el código se alinea a este documento (no al revés).
> Donde tus documentos se contradecían, decidí yo y lo dejé anotado en [DECISIONES_Y_PENDIENTES.md](DECISIONES_Y_PENDIENTES.md) (**D1…**). Lo que nunca definiste son los **P1…**.

**Leyenda:** ✅ tal cual tus documentos · 🔧 unifiqué o interpreté (ver D#) · 🟡 valor provisional (no lo definiste tú; ajústalo) · 🔴 abierto (necesita tu decisión)

**Fuentes, de mayor a menor autoridad:** 1) tus respuestas directas (`preguntas.txt` = **PR#**, y las respuestas globales de `Flow de juego.txt` = **FJ#**; allí la numeración repite el 10 tres veces: comida instantánea, casero y reloj de fichar) · 2) `Diseño de Gameplay` (estadísticas, efectos, eventos) · 3) `Ficha de acciones`, `Jugabilidad`, `Flujo (gameplay)` · 4) fichas de ítems del Notion (traen formato de asistente de IA) · 5) documentos generados por IA (planes, `AMBIGUITIES.md`): solo rellenan huecos.

---

## 1. La estructura: cómo encaja todo

```
              ┌─────────── CORDURA (el dial maestro) ───────────┐
              │  decide qué efectos aparecen y con qué prob.    │
   ACCIONES ──┼─► gastan TIEMPO y ENERGÍA ─► cambian ESTADOS ───┤
   (fichas)   │                              (ítems, ropa)      │
              ▼                                                 ▼
        EFECTOS PRIMARIOS: Estrés ⇄ Calma (niveles I–III)
              │  según su nivel aumentan la probabilidad de
              ▼
        EFECTOS SECUNDARIOS: Hambre · Hiperactividad · Suciedad · Sueño ·
                             Insomnio · Inapetencia · Atenta · Hipersomnia · Debilitamiento
              │  modifican costos de acciones, tiempo, eventos y diálogos
              ▼
        EVENTOS (día + hora + ZONA) ─► consecuencias: trabajo, dinero, narrativa
```

**Las 8 reglas del sistema**
1. El tiempo **solo avanza cuando el jugador actúa**; cada acción consume un bloque definido en minutos.
2. Todo cambio de estado nace de una **acción**, un **evento** o el **paso del tiempo**. Nada más.
3. Un efecto activo se **conserva** hasta cumplir su condición de eliminación (FJ1).
4. Todo efecto se describe con la misma plantilla: **Causas · Niveles · Impacto · Mitigación · Secuelas**.
5. Toda acción se describe con la misma ficha: **Tipo · Costes · Elimina/Aplica · Restricciones · Reacciones**.
6. **Estrés y Calma no coexisten**: el que llega reduce un nivel del otro.
7. Los efectos son **declarativos**: modifican costos y probabilidades; no cambian estadísticas "por detrás".
8. Los eventos con diálogo ocurren en una **zona** concreta; si Mayui no está, esperan a que llegue (solo ese día).

---

## 2. Tiempo y calendario

### 2.1 Reloj ✅
- Día de 1440 min. Franjas: **Madrugada** 00:00–05:59 (nocturno) · **Mañana** 06:00–11:59 · **Tarde** 12:00–18:59 · **Noche** 19:00–23:59 (nocturno).
- Semana LUN→DOM; el día 1 es **lunes**; el prólogo dura 7 días; mes de 30 días. Sábado y domingo no hay trabajo.
- 🔧 Si una acción hace pasar varias horas (dormir, viajar), se disparan en orden todos los eventos cuya hora se cruzó.

### 2.2 Horarios fijos ✅
| Cuándo | Qué | Hora | Dónde |
|---|---|---|---|
| Todos los días | Tiendas abren / cierran | 07:00 / 22:00 | Barrio y zona comercial |
| Todos los días | Bus Apartamento → Empresa | 07:30 | Parada del barrio |
| Todos los días | Bus Empresa → Apartamento | 17:30 | Parada de la empresa |
| Lun–Vie | Inicio del trabajo (fichar en la PC, FJ11) | 08:00 | Oficina |
| Lun–Vie | Pausa / Reanuda | 13:00 / 13:45 | Oficina |
| Lun–Vie | Fin de la jornada | 17:00 | Oficina |
| Miércoles | **Vence el alquiler** | 17:00 | Lobby (casero) 🔧 D6 |
| Viernes | Servicios públicos | 13:00 | — |
| Viernes | Tabla de resultados y **pago del salario** | 17:00 | Oficina 🔧 D7 |

### 2.3 Guardado y pantalla ✅
- Guardar **solo al final del día** (al dormir), para evitar el "día perfecto" abusando de los saves (PR75).
- HUD: efectos activos, hora, energía, día y dinero (PR76, sujeto a cambios).

---

## 3. Estadísticas

### 3.1 Energía — base **45** · tope 100 · mínimo 0 ✅
| Energía | Estado | Regla |
|---|---|---|
| 100–90 | **Hiperactiva** (efecto Hiperactividad) | las acciones cuestan 10 % menos energía |
| 89–16 | Normal | solo efectos externos la modifican |
| 15–1 | **Agotada** (efecto Cansancio) | costo de energía −75 %, pero el tiempo de las acciones ×1,5 |
| 0 | **Debilitamiento** | efecto Debilitamiento; Mayui se desmaya donde esté y duerme con la fórmula de sueño (FJ3) |

Se gasta con cada acción (según su ficha) y al caminar entre zonas (§5.5). Se recupera durmiendo (§5.4) y comiendo (§5.3).

### 3.2 Cordura — base **50** · tope 100 · mínimo 0 ✅
| Rango | Estado | Qué significa |
|---|---|---|
| 100–60 | **Dócil** | Esclavo modelo |
| 59–40 | **Neutral** | Eres consciente del sistema |
| 39–0 | **Perturbado** | Ya no puedes pretender ser parte de esta sociedad |

- Es el **dial maestro**: reparte las probabilidades de los efectos y desbloquea diálogos y decisiones distintas.
- Se mueve despacio: la afectan eventos, ítems, diálogos y efectos problemáticos (p. ej. Debilitamiento); una buena rutina de sueño ayuda poco. **Dañarla cuesta más que mejorarla** (FJ2).
- Cordura 0 habilita la acción de tirarse por el balcón (muerte, FJ6).
- Al llegar a una ruta ramificada no puede bajar del nivel que tenía al ramificarse (punto de no retorno); se rebalancea cada fin de semana con eventos determinísticos.
- ✅ El "estabilizador razonable" que pedías (P1) está definido y probado en [SISTEMA_EFECTOS.md §2](SISTEMA_EFECTOS.md): daño amortiguado, tope diario, rebote desde el fondo, piso del prólogo y rebalanceo del domingo.

### 3.3 Salud — base **100** · tope 100 · mínimo 0 🔧 D10
- En la demo solo baja por: Hambre prolongada (−5 cada 4 h tras 24 h), Insomnio + Hiperactividad (−5) y eventos peligrosos (robo, accidente…).
- **Salud 0 = muerte = Game Over.** Es la única forma de perder (FJ6).
- La tabla de rangos (Deteriorado → Colapso) queda fuera de la demo.

### 3.4 Dinero → ver §6.

---

## 4. Efectos

> El sistema de efectos completo vive en **[SISTEMA_EFECTOS.md](SISTEMA_EFECTOS.md)**: es la fuente de verdad (causas, niveles, impacto, mitigación, secuelas, estabilizadores de cordura y validación por simulación). Aquí solo el resumen.

| Familia | Efectos |
|---|---|
| **Primarios** (eje emocional) | Estrés ⇄ Calma |
| **Derivados** | Insomnio · Inapetencia · Atenta ⇄ Hipersomnia (eje de percepción) |
| **Necesidades** | Hambre · Suciedad · Sueño |
| **Energía** (eje de ritmo) | Hiperactividad ⇄ Cansancio ⇄ Debilitamiento |

**Reglas clave:** niveles I–III con escalada uniforme · un efecto se conserva hasta mitigarlo (FJ1) · Estrés y Calma se reducen entre sí · una mitigación no baja más de 2 niveles por día · todo vuelve a la cordura al cerrar el día.

---

## 5. Acciones

### 5.1 Tipos ✅
| Tipo | Qué es | Regla |
|---|---|---|
| **General** (Inspeccionar) | revela información o diálogo sin afectar al jugador | al agotar los diálogos consume 1 bloque de tiempo · luego repite el último diálogo · **3 usos** por objeto, y entra en cooldown (otro bloque de tiempo) |
| **Activa** (bañarse, dormir, cocinar…) | modifica el estado del mundo o del personaje | consume un tiempo fijo · bloquea el input · **límite de usos por día** · al usarse entra en **cooldown** y mientras dure funciona como una acción General |
| **Pasiva** (lavadora, estufa…) | inicia un proceso que avanza con el tiempo | no consume tiempo propio · permite hacer otras cosas · exige condiciones previas (no hay estufa sin comida) |

🔧 "Ciclo" = día (los límites se reinician al cambiar de día). El cooldown se mide en horas de juego (D21).

### 5.2 Ficha estándar (todas las acciones usan esta plantilla)
`Nombre · Tipo · Costes (tiempo, energía, estrés, dinero) · Elimina · Aplica · Restricciones (previas, límite por día, cooldown) · Reacciones del mundo · Umbrales narrativos`

### 5.3 Catálogo
| Acción | Tipo | Tiempo | Energía | Elimina / Aplica | Restricciones y cooldown |
|---|---|---|---|---|---|
| **Dormir** | Activa | ≥ mínimo (§5.4) | + según horas | −1 nivel de Estrés · Insomnio si duerme menos del mínimo | 1 vez al día · cama (🟡 tipo C por defecto) · guarda la partida |
| **Bañarse** | Activa | 25 min | −5 | Elimina Suciedad (cuerpo) · agua caliente: −1 Estrés · agua fría: Estrés (prob.) y Atenta breve (D4) | requiere jabón (usos limitados) · cooldown 5 h |
| **Cepillarse** | Activa | 🟡 5 min | 🟡 0 | Elimina Suciedad (boca) · 🟡 +2 Salud (prob., una vez al día) | pasta con usos (A 12 · B 8 · C 5) · ✅ una vez al día |
| **Cambiarse** (armario) | Activa | ✅ 2 min | 🟡 0 | Cambia la ropa (limpia / sucia / mojada / seca) | uniforme obligatorio para trabajar |
| **Cocinar** | Pasiva/Activa | 2 min por crafteo + receta | −1 por crafteo | Genera comida y bebida (§5.4) | requiere utensilios de la estación |
| **Comer** | Activa | 🟡 10 min | — | según el ítem (§5.4) | con Inapetencia: éxito −50 % |
| **Beber café** | Activa | 🟡 5 min | — | Hiperactividad 2 h (caliente = más efectivo) | si ya hay Hiperactividad → Insomnio (D2) |
| **Inspeccionar** | General | 1 bloque al agotar | — | solo diálogo | 3 usos por objeto → cooldown |
| **Esperar** | Pasiva | 🟡 bloques de 15 min | — | mitiga Hiperactividad | — |
| **Trabajar** (PC) | Activa | por tarea | por tarea | tareas por correo (trivia, tecleo, clasificación, diferencias · PR2) | solo en horario · fallar una tarea te hace tardar más (PR54) · Estrés baja el éxito |
| **Viajar** | Activa | §5.5 | §5.5 | — | §5.5 |
| **Comprar** | Activa | 🟡 | — | dinero ↔ ítems | tiendas 07:00–22:00 · sin fondos → Estrés |
| **Apostar** (arcade) | Activa | 🟡 | — | ganar: anula Estrés · perder: anula Calma | fin de semana |
| **Lavar / tender ropa** | Pasiva | según lavadora | — | Sucio→Limpio · Mojado→Seco | requiere jabón |

Inventario: **2 manos** (2 slots); manos ocupadas bloquean ciertas interacciones (PR60).

### 5.4 Dormir, comer y beber

**Horas mínimas de sueño según la energía al dormir** ✅
| Energía | 1–15 % | 16–30 % | 31–50 % | 51–70 % | 71–100 % |
|---|---|---|---|---|---|
| Horas mínimas | 10 h | 9 h | 8 h | 7 h | 6 h |

**Energía que da el sueño** ✅: 1 h → 5 · 2 h → 8 · 3 h → 10 · 4 h → 12 · 5 h → 15 · 6 h → 20 · 7 h → 30 · 8 h → 35 · 9 h → 38 (tope suave) · 10 h → 40 (tope duro).

**Camas** ✅: **A** −1 h de sueño obligatorio y +10 % de energía efectiva · **B** −30 min y +5 % · **C** sin cambios. (Su bono de estrés → [SISTEMA_EFECTOS](SISTEMA_EFECTOS.md) E10: al dormir, la cama A suma un 75 % de probabilidad de un −1 extra de Estrés y la B un 25 %.)

**Despertador / Teléfono con alarma** 🔧 D1: sin Insomnio, permite elegir dormir **menos** que el mínimo (sin él, Mayui nunca despierta antes). Con Insomnio su ayuda queda anulada: solo funciona con una probabilidad según la energía (≤20: 25 % · ≤40: 45 % · ≤60: 65 % · ≤80: 80 % · ≤100: 95 % 🟡); si falla, duerme un número aleatorio de horas de su nivel de Insomnio ([SISTEMA_EFECTOS §3.2](SISTEMA_EFECTOS.md)).

**Comida y bebida**
| Ítem | Energía | Elimina | Aplica | Preparación |
|---|---|---|---|---|
| **Comida instantánea** | +10 | Hambre | **50 % Estrés** (D3) · Suciedad (boca) · −1 nivel de Calma | agua caliente 5 min (estufa) + caja |
| **Comida casera** | +30 | Hambre | −1 nivel de Estrés si está caliente · cuenta para la Rutina saludable | bolsa + tabla + olla + estufa 45 min; dura 8 h fresca |
| **Café** | 🟡 +10 si está frío | — | Hiperactividad 2 h | agua 25 min (estufa) o 35 min (nevera) + café + taza; dura 6 h |

### 5.5 Moverse entre zonas
- **A pie** ✅ FJ5: cada escena recorrida cuesta energía y tiempo **crecientes**; el cálculo se reinicia al volver a la última escena recorrida. (Base 2 de energía y 5 min, valores del código.)
- **Bus** 🔧 D20: solo pasa a las 07:30 (Apto→Empresa) y 17:30 (Empresa→Apto); cuesta S/10 y ahorra tiempo y energía frente a caminar.
- **Riesgo en la calle** 🟡: 10 % base de ser sorprendida (−5 Cordura, +10 min, Estrés); Atenta lo reduce 50 %, Hipersomnia lo duplica.

---

## 6. Economía
| Concepto | Valor | Fuente |
|---|---|---|
| Moneda | Savia (S/) | ✅ |
| Dinero inicial | S/350 | 🟡 |
| Salario | S/200 por día laborado (L–V) = S/1000/semana · se paga el viernes 17:00 | 🟡 monto (viene del Documento Maestro v2, que no está en el repo, P11) · ✅ viernes · 🔧 D7 |
| Alquiler | S/230 · vence el miércoles 17:00 · se paga al casero en el Lobby | 🟡 / 🔧 D6 |
| Bus | S/10 por viaje | 🟡 |
| Servicios públicos | viernes 13:00 (monto 🔴 P8) · RootNet (internet) va dentro de las facturas | ✅ PR6 |

**Reglas**
- El dinero visible nunca es negativo; pueden existir **deudas invisibles** (banco, matones, amigos) que, cuanto más suben, más Estrés causan (FJ4). 🔴 P10
- **Llegar tarde** (después de 08:10; 🟡 tolerancia de 10 min porque tu Flujo dice que a las 8:05 "no vas tarde", D23) = llamado de atención acumulable (🟡 −S/20). **Irse antes sin permiso** = llamado + pérdida de parte del día (🟡 −S/50). **Faltas:** 1.ª y 2.ª avisos · 3.ª recorte de salario (🟡 −S/100) · 4.ª **despido** (PR49).
- **Horas extra:** no se pagan; cumplen la meta del día pero añaden efectos negativos (PR52). **3 o más tareas extra al día** dan el token de ascensión (PR20).
- **Evaluación del viernes:** pantalla de resultados + correo semanal (PR64–65). No cambia el salario; solo el progreso del token.
- **Alquiler impago:** jueves 18:00 el casero avisa (si no pagaste) · domingo: aviso final o desalojo el lunes.

---

## 7. Eventos y calendario semanal (por zona)

**Regla de entrega:** el evento se dispara a su hora; si Mayui no está en la zona indicada, queda pendiente y se entrega al llegar. Si no llega ese mismo día, se descarta.

| Día | Hora | Evento | Zona |
|---|---|---|---|
| Lun (1) | 07:30 | Casero se presenta: explica cuánto y cuándo cobra (FJ10b) | **Lobby** |
| Lun (1) | 15:30 | Veda aparece | **Oficina** |
| Mar (2) | 09:00 | Email de Veda (solo bandera) | — |
| Mar (2) | 13:20 | Madina, cafetería (solo en la pausa) | **Oficina** |
| Mié (3) | 13:30 | Madina, tensión (solo en la pausa) | **Oficina** |
| Mié (3) | 17:00 | **Vence el alquiler** | **Lobby** |
| Jue (4) | 09:00 | Aviso de Veda (banderas de restricción nocturna y encuesta) | — |
| Jue (4) | 13:15 | Madina, objeto M-88 (solo en la pausa) | **Oficina** |
| Jue (4) | 15:30 | Mirada de Veda (bandera) | — |
| Jue (4) | 18:00 | Casero: 1.ª advertencia (solo si no pagó) | **Lobby** |
| Vie (5) | 13:00 | Servicios públicos | — |
| Vie (5) | 17:00 | Tabla de resultados + salario | **Oficina** |
| Vie (5) | 22:00 | Email M-88 (solo si hubo la nota de Madina) | — |
| Sáb (6) | 10:00 / 14:00 | Mercado y Arcade abiertos | Comercial |
| Dom (7) | 11:00 | Madina, advertencia de lavandería (si relación ≥ 2) | 🔴 |
| Dom (7) | 12:00 | Casero: aviso final / desalojo (solo si no pagó) | **Lobby** |
| Dom (7) | 17:00 | Preparación de la semana + rebalanceo de cordura (🔴 P1) | **Apartamento** |

Las zonas de esta tabla las asigné yo según tu diseño (casero en el edificio, Veda y Madina en la empresa, preparación de la semana en casa). Cámbialas aquí o en `event_zones` (`narrative_event_handler.gd`).

Fuera de la demo: el evento del "Piso 2" (placeholder de IA, tu doc lo marca como contenido a rehacer) y el evento de la azotea del sábado (🔴 P7).

---

## 8. Tutorial de la mañana ✅ (FJ + `Flow de juego.txt`)
Mayui despierta junto a la cama, temprano y a oscuras. Aparece la **lista de tareas** y los efectos iniciales **Maloliente** y **Hambre**; el jugador puede explorar toda la casa, pero Mayui siempre intenta redirigirlo.

1. **Ducharse** — silueta tras la cortina; sin agua caliente ("Qué frío"): Estrés (prob.) y a veces Atenta breve (D4). Sale en toalla (cambia el sprite).
2. **Armario** — debe elegir el **uniforme**; otras prendas → diálogo que la redirige. Ruge el estómago: la manda a la cocina.
3. **Cocina y nevera** — hay café ya hecho en la cafetera (se calienta); en la nevera: 3 comidas instantáneas, café y 2 bolsas de ingredientes. Cualquier ítem que no sea la comida instantánea → diálogo que la redirige. Se prepara en la cocina (agua caliente 5 min) y se come con el café.
4. **Cepillarse** (lavamanos) — porque la comida instantánea deja la boca sucia (D5). El espejo permite "revisar" la cordura solo de forma narrativa/visual, nunca con un medidor.
5. **Salir** — solo se permite con los 4 pasos cumplidos. Al bajar al **Lobby**, el casero la intercepta y explica cuánto y cuándo se cobra. Luego va al trabajo (bus 07:30 o a pie): llegar a las 8:05 todavía no es tarde (D23).
