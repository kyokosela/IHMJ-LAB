# Sistema de Efectos — "I Hate My Job"
**Versión completa v1 · validada por simulación · borrador para tu revisión · 2026-11-21**

> Es la **fuente de verdad de los efectos** (sustituye al §4 de [SISTEMA_GAMEPLAY.md](SISTEMA_GAMEPLAY.md)). Parte de tu tabla de efectos, cierra todos sus huecos con lo que ya existía en tus documentos, y fue **probada con una simulación** ([Tools/simulacion_efectos.gd](../../Tools/simulacion_efectos.gd)) para comprobar que no hay trampas sin salida.

**Leyenda:** ✅ viene de tus documentos · 🔧 unifiqué (ver D# de [DECISIONES_Y_PENDIENTES.md](DECISIONES_Y_PENDIENTES.md)) · 🟡 **lo completé yo** derivándolo de tus números (ver E# en §8) · 🔴 abierto

---

## 0. Resumen en una página

**Qué quedó cerrado.** Tu tabla tenía filas vacías (Atenta, Hipersomnia, Sueño), mitigaciones en blanco (Inapetencia, Hipersomnia), un "30 % en L3" y un "50 % en la 4.ª acción" sin explicar (Debilitamiento), diálogos agresivos sin escribir, ítems de medicina que no existían y el "estabilizador de cordura" pendiente. Todo eso está resuelto en §3 y §8 usando tus propios números como semilla.

**La idea que lo ordena:** 4 familias y 3 ejes opuestos.

```
 PRIMARIOS (emoción, los reparte la CORDURA)       Estrés  ⇄  Calma            ← eje emocional
      │ según su nivel provocan
 DERIVADOS (consecuencias)       Insomnio · Inapetencia · Atenta ⇄ Hipersomnia   ← eje de percepción
 NECESIDADES (decaen con el tiempo)   Hambre · Suciedad · Sueño      → se resuelven con acciones
 ENERGÍA (automáticos por el valor)   Hiperactividad ⇄ Cansancio ⇄ Debilitamiento ← eje de ritmo
      └──► y todo vuelve a la CORDURA (bucle cerrado, §2)
```

**Cómo se comprobó.** Simulé 3000 semanas por perfil (modelo / neutro / caótico), en modelo simplificado a nivel de día:

| Resultado | Modelo | Neutro | Caótico |
|---|---|---|---|
| Cordura día 1 → día 7 (media) | 52 → **74** | 52 → **55** | 46 → **13** (día 6) → 24 |
| Llega a Estrés II (alguna vez en la semana) | 0 % | 1 % | 73 % |
| Llega a Insomnio III (alguna vez en la semana) | 0 % | 0 % | 73 % |
| Muere en la semana | 0 % | 0 % | 3 % |

- Un jugador cuidadoso **mejora**, uno descuidado **se desploma a mitad de semana** (tu "crashout") y el neutro **se mantiene estable**.
- **Salida de la crisis:** desde el peor estado posible, un jugador que se cuida sale en **86 % de los casos, en una mediana de 6 días**, usando ~6 pastillas (≈ un alquiler). Quien sigue igual de descuidado **no** sale: nada lo salva solo.
- **Todo efecto es alcanzable:** Estrés III en el 17 % de las semanas caóticas (51 % a 21 días); Calma III en el 80 % del modelo a 21 días; Hipersomnia en el 67 %. Calma III e Hipersomnia **no** aparecen en la semana del prólogo (necesitan cordura >80): son para después de la demo.

La simulación **encontró y corrigió** tres incoherencias de mi primer borrador: una trampa sin salida (recuperar cordura era mucho más lento que perderla, lo contrario de tu respuesta FJ2), una deuda de sueño sin tope (llegaba a 144 h) y la cordura cayendo a 0 por simple descuido.

---

## 1. Estructura y reglas del motor

### 1.1 Familias
| Familia | Efectos | Cómo nacen | Cómo se van |
|---|---|---|---|
| **Primarios** | Estrés · Calma | tirada diaria según Cordura, o causa activa | mitigación explícita (FJ1); se reducen entre sí |
| **Derivados** | Insomnio · Inapetencia · Atenta · Hipersomnia | de un primario, de la cordura o de un hábito | al desaparecer su causa (+ mitigaciones propias) |
| **Necesidades** | Hambre · Suciedad · Sueño | por el paso del tiempo | con la acción que las resuelve |
| **Energía** | Hiperactividad · Cansancio · Debilitamiento | por el valor de la energía (y café, etc.) | al salir del rango o al vencer |

### 1.2 Ejes opuestos (exclusión mutua)
- **Emocional:** Estrés ⟂ Calma ✅ — el que llega **no se activa** y reduce 1 nivel del otro.
- **Percepción:** Atenta ⟂ Hipersomnia 🟡 — misma regla (uno nace de Insomnio, el otro de Calma III).
- **Ritmo:** Hiperactividad ⟂ Cansancio ⟂ Debilitamiento 🟡 — por energía solo puede haber uno; Debilitamiento no se reemplaza (solo medicina o vencer).

### 1.3 Reglas del motor
| # | Regla |
|---|---|
| **R1** | **Persistencia** ✅ (FJ1): un efecto se conserva hasta cumplir su condición de eliminación. Los *derivados* (Atenta, Hipersomnia, Inapetencia) se van cuando se va su causa. |
| **R2** | **Causas múltiples:** un efecto permanece mientras quede al menos una causa activa o su duración. |
| **R3** | **Niveles y escalada uniforme** 🔧: II tras 1 día en I; III tras 2 días más en II (días contados al despertar). En los primarios además se exige el umbral de cordura y una tirada del 50 % (D9). Máximo +1 nivel por día. |
| **R4** | **Mitigación:** "−1 nivel" o "anula". Un primario no baja más de **2 niveles por día** 🟡 (evita que se resuelva todo de golpe). |
| **R5** | **Exclusión de ejes** (§1.2). |
| **R6** | **Tiradas diarias:** las probabilidades "porcentuales" se tiran una vez al despertar. |
| **R7** | **Causa activa** (acción o evento): efecto inmediato; si el efecto ya existe, **acelera** su escalada (+1 día). |
| **R8** | **Topes de modificadores** 🟡: el tiempo de una acción nunca baja de ×0,5 ni sube de ×3; el costo de energía nunca baja de ×0,25 ni sube de ×2. Sin tope, los modificadores se multiplican sin control (con todos activos saldría ×5). |
| **R9** | **Orden de resolución:** ver §6. |
| **R10** | **Feedback:** cada efecto tiene icono con su nivel en el HUD; la cordura **nunca** se muestra como número, se ve en el espejo y en los ojos secos de Mayui ✅. |

---

## 2. Cordura: el bucle cerrado

Sin esto el sistema estaba abierto: la cordura decidía los efectos, pero casi nada devolvía al juego una consecuencia sobre la cordura. Ahora se cierra al final de cada día.

### 2.1 Balance diario
| | Concepto | Valor |
|---|---|---|
| **+** | Día con Rutina saludable | +3 🟡 |
| **+** | Día libre (sáb/dom) con ≥2 de las 4 acciones de rutina | +3 🟡 |
| **+** | Domingo: rebalanceo semanal ✅ | si Cordura <50: recupera el 25 % de lo que le falta 🟡 |
| **−** | Sueño (nivel I / II / III) | −3 / −5 / −8 (tu −8 % es el nivel III) |
| **−** | Adquirir Debilitamiento (FJ2: "efectos problemáticos como WEAK") | −5 una vez |
| **−** | Ser sorprendida en la calle | −5 |
| **−** | Cada ciclo de desahogo (§3, Estrés) | −2 |
| **±** | Eventos narrativos | el valor lo define cada evento (fuera de este sistema) |

### 2.2 Estabilizadores 🟡 (tu pendiente P1)
| Estabilizador | Valor | Para qué |
|---|---|---|
| **Daño amortiguado** | las pérdidas se multiplican por 0,75 | FJ2: "es más difícil afectarla que beneficiarla" |
| **Calma protege** ✅ | −5 / −8 / −12 % de la pérdida (nivel I / II / III) | premia la rutina |
| **Tope diario** | no se pierden más de 10 puntos por día | evita caídas en picada |
| **Rebote** | las ganancias valen ×2 con Cordura <30 y ×1,5 con <40 | **sin esto no hay salida**: recuperar era más lento que caer |
| **Piso del prólogo** | en la semana de la demo la cordura no baja de 10 (solo un evento narrativo puede llevarla a 0 y habilitar el balcón, FJ6) | descuidarte no debe matarte |
| **Piso de ruta** ✅ | al ramificarse una ruta no baja del nivel que tenía | tu punto de no retorno |

### 2.3 Qué ve el jugador ✅
Nunca un número: el **espejo** del lavamanos, la **música**, los diálogos y el aspecto de Mayui (ojos más secos con menos cordura; tomate que se descompone, con hongos oscuros al "pudrirse").

---

## 3. Catálogo de efectos
Cada ficha usa tu plantilla: **Causas · Niveles · Impacto · Mitigación · Secuelas**.

### 3.1 PRIMARIOS

#### ESTRÉS — niveles I–III · eje emocional
**Causas.** *Por cordura* (tirada diaria, si no hay Estrés ni Calma) ✅: Cordura <40 → 25 % · <30 → 50 % · <20 → 50 % → nace Estrés I.
*Activas* (inmediatas) 🟡: comida instantánea (50 %, D3) · agua fría (50 %, solo en el tutorial) · pérdida apostando · fondos insuficientes al pagar o comprar · **exceso de trabajo** (≥3 tareas extra en el día; Atenta sube el umbral a 4/5/6) · **rutinas desordenadas** (día con ≤1 de las 4 acciones de rutina) · ser sorprendida en la calle · eventos específicos.
**Escalada** 🔧 D9: I→II tras 1 día en I con Cordura <30 (50 %) · II→III tras 2 días en II con Cordura <20 (50 %).

| Nivel | Tiempo en acciones | Éxito laboral | Diálogos y acciones |
|---|---|---|---|
| I | +3 % ✅ | −10 % ✅ | pensamientos intrusivos |
| II | +8 % ✅ | −25 % ✅ | los agresivos reemplazan a algunos regulares · aparecen **opciones agresivas** |
| III | +15 % ✅ | −50 % ✅ | **solo** diálogos y acciones agresivas (§Desahogo) |

**Mitigación** (cada una cuenta para el tope de −2 niveles/día):
| Fuente | Efecto |
|---|---|
| Dormir apropiadamente | −1 nivel; **cama A: +75 %** de un −1 extra, **cama B: +25 %** (E10) · si hubo jornada laboral el piso es nivel I · 2 noches seguidas lo **anulan** (solo en día libre) |
| Rutina saludable | −1 nivel (en vez de dar Calma, por la exclusión) |
| Comida casera caliente · baño con agua caliente · Antojo | −1 nivel cada uno |
| Apostar y ganar | **anula** |
| Compra cara (≥S/100 con ≥S/500 de saldo) | −1 nivel |
| Café caliente | 1 de 6 veces, −1 nivel 🟡 (ya estaba en el código) |
| Desahogo | ver abajo |

**Secuelas.** Tazas y platos se rompen 25 % al usarlos, en cualquier nivel ✅ (ficha del ítem) · al mitigarlo **por completo desde nivel III → Insomnio** ✅ · Estrés III: 50 % Desmayo y 50 % Inapetencia por día ✅.

**DESAHOGO** (tus "acciones y diálogos agresivos", E5) 🟡
- Estrés I: solo pensamientos intrusivos. **II:** aparecen opciones agresivas (insultar, golpear, culpar a alguien: el "libertinaje" de Mayui) y hay **1 estallido espontáneo por día** ("Mayui decide gritar de la nada"). **III:** toda interacción es agresiva (3 ciclos al día); si una interacción falla, debe ventilarse en ese momento.
- Cada ciclo suma 1. **3 ciclos → −1 nivel de Estrés.**
- **Costo de cada ciclo:** −2 Cordura (se aleja de la sociedad) · −5 de relación con el NPC objetivo · en horario laboral 25 % de llamado de atención · contra objetos, rotura de tazas/platos (25 %).
- Es el diseño de tu doc llevado hasta el final: el estallido **alivia** el estrés pero te empuja hacia el "Perturbado".

#### CALMA — niveles I–III · eje emocional
**Causas.** **Rutina saludable** ✅ (activa: nace Calma I; si ya hay, +1 día; si hay Estrés, éste baja 1 nivel) · eventos especiales ✅ · *por cordura* ✅: >60 → 25 % · >70 → 50 % · >80 → 50 % (tirada diaria).
**Rutina saludable** (se evalúa al cerrar el día) 🟡 E7: las **4 obligatorias**: comida casera ≥1 vez · dormir apropiadamente la noche anterior **sin despertador** · dinero mínimo para comida y deudas · bañarse. **Jugar o apostar es comodín:** con 3 de 4 + jugar, el día cuenta (a Mayui le gusta el gambling).
**Escalada** 🔧 D9: I→II tras 1 día con rutina y Cordura >70 (50 %) · II→III tras otro día con rutina y Cordura >80 (50 %).

| Nivel | Tiempo | Cordura protegida | Diálogos y reacciones |
|---|---|---|---|
| I | −3 % ✅ | 5 % ✅ | 30 % más amistosos ✅ |
| II | −6 % ✅ | 8 % ✅ | 80 % más amistosos ✅ · menor reacción a sorpresas (+20 % de prob. de ser sorprendida 🟡) |
| III | −10 % ✅ | **12 %** 🟡 E6 | respuestas pasivas ✅ · sorpresas +40 % 🟡 |

**Mitigación** ✅: ser sorprendida en la calle · recibir daño · apostar y perder (**anulan**) · no cumplir las tareas obligatorias · no cubrir deudas · no dormir apropiadamente · comer comida instantánea (**−1 nivel**).
**Secuelas** ✅: Calma III → 50 % Hipersomnia por día · puede abandonar el trabajo al azar (🟡 50 % cuando una acción cumpla condiciones de Estrés) · anularla por completo desde III → **Estrés**.

### 3.2 DERIVADOS

#### INSOMNIO — niveles I–III
**Causas** ✅: Cordura <30 · dormir menos del mínimo (tu Ficha) · Hiperactividad reactivada · Café con Hiperactividad activa (D2) · Sueño III + un día sin dormir apropiadamente · Estrés III mitigado por completo.
**Nivel** (se recalcula al despertar) ✅: **I** base · **II** = Cordura <30 + 2 noches malas seguidas · **III** = Cordura <15 + 2 noches malas seguidas.
**Impacto:** esa noche duerme **como máximo** un número aleatorio de horas: I 4–7 · II 2–6 · III 0–3 ✅ (D11) · anula la ayuda del despertador (D1).
**Mitigación:** **Pastillas para dormir** 🟡 (esa noche duerme las horas mínimas y baja 1 nivel; si era I, lo elimina) · dormir apropiadamente 2 noches seguidas (**anula**) ✅.
**Secuelas** ✅: con Hiperactividad, −5 Salud · tras 2 días → Atenta.
> Con Cordura <30 vuelve a aparecer a la mañana siguiente: la salida real es **subir la cordura** (§2) mientras las pastillas cubren las noches.

#### INAPETENCIA — niveles I–III 🟡 E1
**Causas:** Cordura <30 · Estrés III → tirada diaria 50 % ✅ → nace I. Escala I→II tras 1 día y II→III tras 2 más mientras siga la causa; **se va cuando desaparece la causa** (E4).
**Impacto** (tu fila = nivel III): **comer** tiene éxito −20 / −35 / **−50 %** y recupera −10 / −18 / **−25 %** de energía.
**Provoca** ✅: Hambre con probabilidad 15 / 35 / 70 % (tirada diaria).
**Mitigación:** además de su causa, el **Antojo** quita 1 nivel 🟡.

#### ATENTA — niveles I–III · eje de percepción 🟡 E1
**Causas:** **Insomnio con 2+ días** (su nivel = el del Insomnio) ✅ · agua fría (Atenta I, 1 h) ✅ FJ7.
**Impacto** (tu fila = nivel III): sorpresa en la calle −20 / −35 / **−50 %** · tiempo −10 / −18 / **−25 %** · el umbral de "exceso de trabajo" sube de 3 a 4 / 5 / 6 tareas extra.
**Provoca** ✅: Hiperactividad 10 / 25 / 50 % (tirada diaria). **Se va** al eliminarse el Insomnio.

#### HIPERSOMNIA — niveles I–III · eje de percepción 🟡 E1
**Causas:** Calma III → tirada diaria 50 % ✅. Escala por días como la Inapetencia; **se va al bajar Calma de III**.
**Impacto** (tu fila = nivel III): sorpresa en la calle +40 / +70 / **+100 %** · tiempo +10 / +18 / **+25 %** · Estrés posible en cada acción 4 / 7 / 10 % 🟡.
**Provoca** ✅: Sueño 15 / 30 / 60 % (tirada diaria, nace con deuda de 12 h).
**Mitigación** 🟡 E4: el **Café** quita 1 nivel (una vez al día).

### 3.3 NECESIDADES

#### HAMBRE
**Causas** ✅: **>6 h sin comer** (100 %; el reloj corre también durmiendo: despierta con hambre, como en tu tutorial) · Inapetencia 15 / 35 / 70 % · 🔧 **≥120 de energía gastada** desde la última comida (D13).
**Impacto** ✅: costos de energía **+15 %** · Salud **−5 cada 4 h tras 24 h** con hambre.
**Mitigación:** comer (casera, instantánea o Antojo); con Inapetencia el éxito baja (arriba).
**Secuela** ✅ 🟡: si el hambre duró ≥24 h, durante las 4 h siguientes comer falla el 20 %.

#### SUCIEDAD (Maloliente) — dos capas 🔧 D12
**Causas.** *Cuerpo:* >24 h sin bañarse · ropa mojada >6 h. *Boca:* >24 h sin cepillarse · **comida instantánea**.
**Impacto:** los NPCs te evitan (🟡 50 % se niegan a conversar) · tu influencia o relación **−15 %** ✅ (el "−15 % de crédito social") · fichar sucia: 25 % de llamado de atención 🟡 · acceso prohibido a algunos sitios (🔴 P9).
**Mitigación** ✅: **cuerpo → Bañarse · boca → Cepillarse** · las **Mentas** anulan la boca 3 h 🟡 · pasta de calidad (A 12 · B 8 · C 5 usos).
**Secuela** ✅: durante 6 h tras limpiarte, los NPCs mantienen distancia.

#### SUEÑO — niveles por deuda 🟡 E1
**Causas** ✅: **>16 h despierta** (nace con 12 h de deuda) · Hipersomnia (15 / 30 / 60 %) · 🔧 déficit oculto de sueño ≥6 h (aparece con esa deuda).
**Niveles:** **I** 1–12 h · **II** 13–24 h · **III** 25–36 h de deuda (**tope 36 h**, hallazgo de la simulación: sin tope llegaba a 144 h).
**Impacto** (tu fila = nivel III): tiempo +6 / +10 / **+15 %** · Cordura al cierre del día −3 / −5 / **−8**.
**Mitigación** ✅: **cada noche de ≥6 h paga hasta 6 h de deuda** (12 h = 2 noches, tu regla; las pastillas ayudan). III necesita hasta 6 noches.
**Secuela** ✅ 🟡: 4 h después de pagarla, la sorpresa en la calle sube 10 % ("−10 % de percepción").
**Provoca:** Insomnio si es nivel III y hay un día sin dormir apropiadamente ✅.

### 3.4 ENERGÍA

#### HIPERACTIVIDAD
**Causas** ✅ 🔧 D14: **Energía ≥90** · Atenta (10/25/50 %) · Estrés (15/30/60 %) · **Café** (100 %). **Duración:** mientras la energía ≥90; las demás causas 2 h 🟡.
**Impacto** ✅: costo de energía **−10 %** · velocidad **+15 %**. **Secuela** ✅: −15 % de éxito en tareas de precisión (contar, teclear) mientras dura.
**Mitigación** ✅: **Esperar** (30 min) elimina la que no viene de la energía 🟡.
**Combo** ✅: reactivarse estando activa → **Insomnio**; con Insomnio previo, −5 Salud.

#### CANSANCIO (energía 1–15) ✅
Costo de energía **−75 %**, tiempo **×1,5**. Se va al subir la energía. **Riesgo** 🟡 E3: estando Agotada, **30 % por día** y **50 % en la 4.ª acción seguida** de caer en Debilitamiento (son tus "30 % en L3" y "50 % en la 4.ª acción": **L3 = la 3.ª fila de tu tabla de energía, Agotada**).

#### DEBILITAMIENTO
**Causas** ✅ 🟡: Energía **0** (100 %) · los dos riesgos de Agotada (arriba). **Duración 72 h.**
**Impacto** ✅: tiempo **×2** · cada interacción gasta +1 de energía. **Secuela** ✅: las acciones pesadas cuestan **+20 % de energía** durante esos 3 días. Al adquirirlo: **−5 Cordura** (FJ2).
**Mitigación** ✅: **Medicina** (anula).

#### DESMAYO (evento, no efecto) 🟡 E12
**Causas:** Energía 0 · Estrés III (50 % por día) ✅. **Resultado:** Mayui se desmaya donde esté y duerme con la fórmula de sueño (FJ3); pierde el resto del día (falta si es laboral; los eventos del día se descartan); no cuenta como "dormir apropiadamente".

---

## 4. Matriz de interacciones
| Combinación | Resultado |
|---|---|
| Estrés ⟂ Calma | el nuevo no se activa y reduce 1 nivel del otro |
| Atenta ⟂ Hipersomnia | igual |
| Hiperactividad ⟂ Cansancio ⟂ Debilitamiento | por energía solo uno; Debilitamiento no se reemplaza |
| Hiperactividad reactivada | → **Insomnio** |
| Insomnio + Hiperactividad | **−5 Salud** |
| Insomnio + 2 días | → **Atenta** (mismo nivel) |
| Cordura <30 **o** Estrés III | → **Inapetencia** (50 %/día) |
| Inapetencia + Hambre | comer falla más (éxito −20/−35/−50 %) |
| Calma III | → **Hipersomnia** (50 %/día) → **Sueño** |
| Sueño III + 1 día sin dormir bien | → **Insomnio** |
| Estrés III mitigado por completo | → **Insomnio** |
| Calma III anulada por completo | → **Estrés** |
| Energía ≤15 | 30 %/día y 50 % en la 4.ª acción → **Debilitamiento** |
| Hambre + Debilitamiento | los costos suman (+15 % y +1) |

## 5. Ítems que tocan efectos 🟡 (E9) — a escala del mercado actual (comida S/25–60, jabón S/10–35)
| Ítem | Precio | Efecto |
|---|---|---|
| **Pastillas para dormir** | S/40 | esa noche duerme las horas mínimas · −1 nivel de Insomnio · cuenta como "dormir apropiadamente" |
| **Medicina** | S/60 | anula el Debilitamiento |
| **Mentas** | S/5 | anulan la Suciedad de la boca 3 h |
| **Antojo** (snack de tienda; sustituye a "comida favorita", P6) | S/20 | +10 energía · −1 nivel de Estrés · −1 nivel de Inapetencia · no cuenta como comida preparada |
| Café | — | ver Hiperactividad; quita 1 nivel de Hipersomnia |
| Comida casera / instantánea · jabón · pasta | ya definidos | ver SISTEMA_GAMEPLAY §5.4 |

## 6. Orden de resolución
1. **Al despertar (chequeo diario)**, en este orden: ① escalada de lo que ya existe (Estrés, Calma) → ② aparición o reducción por cordura (Estrés ⇄ Calma) → ③ Insomnio (nivel) y Atenta → ④ Inapetencia e Hipersomnia → ⑤ tiradas que dependen de niveles (Hambre, Sueño, Hiperactividad) → ⑥ Debilitamiento (Agotada) y Desmayo (Estrés III).
2. **Durante el día:** cada acción aplica sus costos con los modificadores (tope R8), sus causas activas y su mitigación; avanzan los temporizadores (hambre 6 h, suciedad 24 h, vigilia 16 h, duraciones).
3. **Al cerrar el día:** Rutina saludable → balance de cordura (§2) → vigilia (deuda de sueño).
4. **Al dormir:** horas según Insomnio, energía, pago de deuda, mitigación de Estrés (con su piso).

## 7. Validación por simulación
**Cómo repetirla:** `Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/simulacion_efectos.gd` (agrega `-- --traza` para ver una partida día a día). Los números del documento están en el bloque `R` al inicio del script: **cámbialos, vuelve a correr y mira qué pasa.** Dime el cambio y yo la ejecuto.

**Criterios de coherencia (todos cumplidos):**
| # | Criterio | Resultado |
|---|---|---|
| 1 | Jugador cuidadoso mejora; descuidado empeora; neutro estable | ✅ 74 / 55 / 13 de cordura |
| 2 | Hay salida desde el peor estado | ✅ 86 %, mediana 6 días, ~6 pastillas |
| 3 | Sin salida solo con los mismos hábitos | ✅ el caótico no sale (0 %) |
| 4 | Todo efecto se alcanza | ✅ (Estrés III 51 %, Calma III 80 %, Hipersomnia 67 % a 21 días) |
| 5 | La muerte es rara | ✅ 3 % del caótico, solo por inanición |
| 6 | Cordura no llega a 0 por descuido en el prólogo | ✅ piso 10 |

**Supuestos (🟡, ajustables):** economía de energía simplificada (desgaste ≈ 94 en día laboral, 82 libre, 80 el día 1) mientras no existan tus tablas de costo por acción; las camas A/B y la Suciedad social no se simularon; perfiles: *modelo* (rutina completa, no toma café con energía alta, usa pastillas y medicina), *neutro* (descuida algo) y *caótico* (duerme poco, come instantáneo, trabaja de más, apuesta).

## 8. Huecos cerrados (E#) y lo que sigue abierto
| ID | Hueco en tu diseño | Cómo lo cerré |
|---|---|---|
| **E1** | Tablas de Atenta, Hipersomnia, Inapetencia y Sueño sin niveles | 3 niveles; **tu fila = nivel III** y los niveles I y II son el 40 % y el 70 % (redondeado). Sueño por deuda de horas. **Sin arte nuevo:** conservan su icono único hecho a mano; el nivel es interno (se ve en el panel de depuración y en el tooltip) |
| **E2** | ¿De qué nivel dependen las probabilidades "(I/II/III)"? | del efecto que las provoca (Atenta ← Insomnio; Inapetencia, Hipersomnia por días) |
| **E3** | "30 % en L3" y "50 % en la 4.ª acción" (Debilitamiento) | L3 = fila 3 de tu tabla de energía (Agotada): 30 % diario y 50 % en la 4.ª acción seguida |
| **E4** | Mitigación en blanco (Inapetencia, Hipersomnia) | se van con su causa; Antojo −1 (Inapetencia); Café −1 (Hipersomnia) |
| **E5** | Diálogos agresivos sin escribir | Desahogo: ciclos, costos y niveles (§3) |
| **E6** | Calma III "−8 %" | 12 % (5 → 8 → 12) |
| **E7** | Umbral de Rutina saludable | las 4 obligatorias; jugar = comodín |
| **E8** | Estabilizador de cordura (P1) | daño ×0,75 · tope −10/día · rebote ×2/×1,5 · piso 10 · Calma protege · rebalanceo del domingo (§2.2) |
| **E9** | Medicina y pastillas no existían | ítems con precio (§5); necesitan icono (placeholder hasta que haya arte) |
| **E10** | Bono de estrés de las camas (P12) | proporción de tu Ficha: base −1 nivel; **A +75 %** (6/8) y **B +25 %** (2/8) de un −1 extra |
| **E11** | Duraciones | Hiperactividad no energética 2 h · Atenta por agua fría 1 h · Debilitamiento 72 h |
| **E12** | Qué es el Desmayo | evento: sueño forzado, pierdes el día |
| **E13** | Deuda de sueño sin tope | tope 36 h (hallazgo de la simulación) |

**Siguen abiertos (🔴), ya sin bloquear nada:** P2 lista maestra de tareas · P7 azotea · P8 monto de servicios · P9 efectos de Maloliente sobre relaciones y accesos · P10 deudas invisibles · P11 Documento Maestro v2 · P13 cómo se consiguen cama y despertador · P14 números de tareas extra · y una nueva: ¿hay **agua caliente** después del tutorial? (supuse que sí desde el día 2).
