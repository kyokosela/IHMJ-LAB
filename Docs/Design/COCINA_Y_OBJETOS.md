# Cocina, objetos y estados
**Lo que el juego hace HOY** (comprobado el 2026-11-24) y, al final, una propuesta para discutir.

## 1. Cómo se usa la cocina
- **Almacenamiento:** 2 alacenas (12 casillas), a temperatura ambiente. Todavía no hay una nevera que enfríe.
- Los objetos se **arrastran**. **Clic derecho** (o doble clic) sobre un objeto en tus manos = usarlo (comer, beber).
- **Estaciones** (estufa, fregadero, tabla): reciben un objeto, su botón hace la receta y **el resultado se queda ahí**.
- **Combinar:** dos casillas arriba y el resultado en la de abajo. No combina otra vez hasta que saques el resultado.
- **El reloj solo avanza cuando haces acciones.** Una receta con tiempo termina cuando el reloj avanza; hoy no se puede esperar en la cocina (P56).

## 2. Con qué empiezas
| Objeto | Cantidad | Para qué |
|---|---|---|
| Bolsa de ingredientes | 2 | se pica en la tabla; así como está no se come |
| Olla | 1 | guarda ingredientes, comida o agua |

El cuadro rosa y negro es "sin imagen": faltan los íconos (P38) y los nombres en español (P39).

## 3. Recetas conectadas
| Dónde | Pones | Sale | Tiempo |
|---|---|---|---|
| Tabla de picar | bolsa de ingredientes | ingredientes picados | al instante |
| Combinar | olla **vacía** + ingredientes picados | olla con ingredientes | al instante |
| Estufa | olla con ingredientes picados | olla con **comida casera caliente** | 45 min |
| Fregadero | olla **vacía** | olla con agua | al instante |
| Estufa | olla con agua que no esté caliente | olla con agua caliente | 25 min |

**Comida casera, paso a paso:** bolsa → tabla de picar → Combinar (olla + ingredientes) → estufa (45 min) → pasa la olla a tus manos → clic derecho para comer.

## 4. ¿Y el agua?
Hoy solo se puede **llenar la olla y calentarla**. No se combina con nada: la comida casera pide la olla vacía, y el **café** de tu dev (agua + bolsa de café → cafetera → taza) existe en archivos pero **no está conectado** a esta cocina (usa un objeto antiguo "olla con agua", y no hay bolsa de café ni taza). Beber el agua no hace nada (P43).

## 5. Qué pasa al comer
| Comes | Energía | Además |
|---|---|---|
| Comida casera | **+42** (tu diseño dice +30, P58) | quita Hambre · cuenta como comida casera · caliente: −1 Estrés · completa la tarea de cocinar |
| Ingredientes picados **sin cocinar** | **+42** | **lo mismo que la comida casera** y también completa la tarea: se puede saltar la estufa (P57) |
| Bolsa sin picar | no se puede | — |

Con Inapetencia, comer puede fallar y da menos energía. El café (Hiperactividad; caliente: 1 de 6 veces −1 Estrés; frío: +10 de energía) está programado pero no se consigue. La comida instantánea todavía no existe (P25).

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
