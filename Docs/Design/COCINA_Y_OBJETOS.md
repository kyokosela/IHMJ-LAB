# Cocina, objetos y estados
**Lo que el juego hace HOY** (comprobado el 2026-11-24) y, al final, una propuesta para discutir.

## 1. Cómo se usa la cocina
- **Almacenamiento:** 2 alacenas (12 casillas), a temperatura ambiente. Todavía no hay una nevera que enfríe.
- Los objetos se **arrastran**. **Clic derecho** (o doble clic) sobre un objeto en tus manos = usarlo (comer, beber).
- **Cada estación acepta solo lo suyo** (2026-11-25): tabla de picar, la bolsa de ingredientes (útil "cuttable"); estufa, la olla con algo dentro ("cookware"); fregadero, la olla. El resultado de Combinar solo sale. Si algo no va, no se mueve y Mayui lo dice. En las estaciones no hay cuadro: se suelta sobre la hornilla, la pila o la tabla.
- **Estaciones** (estufa, fregadero, tabla): reciben un objeto, su botón hace la receta y **el resultado se queda ahí**.
- **Fregadero** (2026-11-26): la olla queda **dentro de la pila** y se ve lo que lleva (agua, ingredientes o comida; dibujos provisionales). Con la olla vacía el botón dice **Usar** (cae el agua 1 segundo y se llena); si lleva algo, dice **Vaciar**: lo de dentro **se bota y no se recupera** (P92).
- **Combinar:** dos casillas arriba y el resultado en la de abajo. No combina otra vez hasta que saques el resultado.
- **Todo se queda donde lo dejas** al salir de la cocina, también lo que esté en Combinar.
- **El reloj solo avanza cuando haces acciones.** Mientras una receta con tiempo corre, **Esperar** (en la estufa) avisa cuánto tiempo pasará y, si aceptas, adelanta el reloj hasta que termine.

## 2. Con qué empiezas
| Objeto | Cantidad | Para qué |
|---|---|---|
| Comida instantánea (caja) | **1** | con agua caliente se prepara; así como está no se come |
| Olla | 1 | guarda ingredientes, comida o agua |

En casa **no hay bolsas de ingredientes** (Ramiro, 2026-11-26): gastada la instantánea, la comida se comprará en la zona comercial (P90). La receta de la comida casera sigue en el sistema.

Los dibujos son **provisionales** (en `Assets/Items`); la olla y la taza cambian según lo que llevan. El nombre de cada objeto sale al pasar el cursor. El cuadro rosa y negro es "sin imagen": quedan la cafetera, el café y el agua sueltos (P38).

## 3. Recetas conectadas
| Dónde | Pones | Sale | Tiempo |
|---|---|---|---|
| Tabla de picar | bolsa de ingredientes | ingredientes picados | al instante |
| Combinar | olla **vacía** + ingredientes picados | olla con ingredientes | al instante |
| Estufa | olla con ingredientes picados | olla con **comida casera caliente** | 45 min |
| Fregadero | olla **vacía** | olla con agua | al instante |
| Estufa | olla con agua que no esté caliente | olla con agua caliente | **5 min** (P28) |
| Combinar | olla con agua **caliente** + caja de comida instantánea | comida instantánea (la olla vuelve vacía) | al instante |
| Fregadero (**Vaciar**) | olla con cualquier cosa dentro | olla vacía (lo de dentro se bota) | al instante |

**Comida casera, paso a paso** (hoy sin bolsas en casa): bolsa → tabla de picar → Combinar (olla + ingredientes) → estufa (45 min) → pasa la olla a tus manos → clic derecho para comer.

## 4. ¿Y el agua?
Sirve para la **comida instantánea** (agua caliente + caja). La comida casera pide la olla vacía, y el **café** de tu dev (agua + bolsa de café → cafetera → taza) existe en archivos pero **no está conectado** a esta cocina (usa un objeto antiguo "olla con agua", y no hay bolsa de café ni taza). Beber el agua no hace nada (P43).

## 5. Qué pasa al comer
| Comes | Energía | Además |
|---|---|---|
| Comida casera | **+42** (tu diseño dice +30, P58) | quita Hambre · cuenta como comida casera · caliente: −1 Estrés · completa la tarea de cocinar |
| Ingredientes picados **sin cocinar** | no se pueden comer | ni sueltos ni dentro de la olla |
| Bolsa sin picar | no se puede | — |

Con Inapetencia, comer puede fallar y da menos energía. El café (Hiperactividad; caliente: 1 de 6 veces −1 Estrés; frío: +10 de energía) está programado pero no se consigue.

**Comida instantánea** (2026-11-25): olla al fregadero → **Usar** (agua) → estufa **5 min** → **Combinar** la olla con agua caliente y la **caja** → sale la comida instantánea (la olla vuelve vacía). Comerla: +10 de energía, quita el Hambre, 50 % de Estrés y −1 de Calma; en el escritorio Mayui dice "No sabe a nada.".

**Pendiente (P91, idea de Ramiro):** la instantánea sale ya en un plato sin pedirlo. Más adelante: comer desde la olla podrá ensuciar la ropa y a Mayui; en plato limpio no; en plato sucio sí.

## 6. Estados de los objetos
| Estado | Valores | Para qué sirve | ¿Funciona? |
|---|---|---|---|
| Preparación | sin preparar → preparado → cocinado | decide qué recetas se pueden | ✅ |
| Temperatura | caliente · normal · frío | la comida caliente baja Estrés | ❌ la comida nunca se enfría; el agua se "calienta sola" con las horas |
| Frescura | buena · mala · podrida | todavía nada | ❌ la comida nunca se daña; el agua se pudre en 1 hora |
| Calidad | A · B · C | energía al comer (42 · 37,5 · 30) | ⚠️ comida e ingredientes quedan en A por defecto |
| Ropa: limpia/sucia, seca/mojada | | efectos en Mayui | ✅ |
| Roto | taza (15 %) | — | la taza no está en la cocina; la rotura aún no mira el Estrés |

**Para tu dev (causa de los ❌, P59):** `ItemBehavior.apply_enviroment` recibe las *propiedades* del ambiente (`temperature`) en vez de sus *condiciones* (`warm`), así que los modificadores nunca se aplican; `home_meal` no tiene `base_decay_time` y su temperatura no tiene `can_decay`; agua y café quedan con `base_decay_time` = 1; `can_decay` vive en el recurso de comportamiento, que comparten varios objetos.

## 7. Propuesta de balance (🟡 para discutir; nada de esto está hecho)
**Ya decidido:** la comida se pudre si no está en la nevera, como en la vida real, con las especificaciones que ya traen los objetos. Falta definir la nevera.

Idea: que jugar bien sea **cocinar con anticipación para ganar tiempo en la mañana**.

| Temperatura | Cómo se consigue | Al consumir |
|---|---|---|
| Caliente (dura ~1 h) | recién hecho o recalentado en la estufa (5 min) | comida: −1 Estrés · café: más probable −1 Estrés |
| Normal | pasa solo | sin extra |
| Frío | nevera | café frío: +10 de energía |

| Frescura | Cuánto aguanta (fuera / nevera) | Al consumir |
|---|---|---|
| Buena | comida casera 8 h / 24 h · ingredientes picados 12 h / 48 h · café 6 h | normal |
| Mala | pasado ese tiempo | media energía |
| Podrida | pasado el doble | sin energía y posible Debilitamiento |

Ejemplo de jugada buena: cocinar en la noche, guardar en la nevera y en la mañana recalentar 5 min en vez de cocinar 45.

Las duraciones de 8 h (comida) y 6 h (café) son de tu diseño (§5.4); el resto son números míos para ajustar.
