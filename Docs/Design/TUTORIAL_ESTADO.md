# Tutorial: guion contra juego
Revisado el 2026-11-24. Fuentes: Notion → *Guión por bloques* (Bloque 1-1 y su página **DIALOGOS**), `Flow de juego.txt` y `Textfiles/Interact/Interacts.csv`.

## Respuesta corta
- **La mañana en casa sí tiene guion escrito** (DIALOGOS). En el juego solo está una parte.
- **El trabajo no tiene guion** (Bloque 1-2: solo objetivos). La tarjeta *Flujo (gameplay)* cuenta la llegada a la empresa (revisión en la entrada, Madina, Sativa, Veda, tu escritorio), sin diálogos y marcada "Sin iniciar".

## La mañana: qué está y qué falta
| Momento | Qué pide el guion | En el juego |
|---|---|---|
| El cuarto | forma del plano, cajas de mudanza, balcón enfrente de la puerta | ✅ en L con muebles provisionales sólidos (P74). ❌ tileset y props reales |
| El baño | aparte, a la izquierda de la puerta: ducha y lavamanos | ✅ escena propia (P75) |
| Despertar | "Tengo que ducharme." | ✅ |
| Hora | de 6:00 a 8:00 | ✅ empieza a las 06:00 (la prueba automática sale de casa antes de las 08:00) |
| Al empezar | lista de tareas en una esquina, efectos Suciedad y Hambre visibles, cuarto a oscuras, sonidos, ayudas de teclas | ❌ |
| Cama | no deja volver a dormir (3 frases) | ✅ tus 3 frases y el aviso; después de la mañana del tutorial deja dormir |
| Puerta | frases según lo que falte: ducha, uniforme, comida, dientes | ✅ con la lista de tareas; el uniforme tiene que estar puesto al salir. Si insistes mucho, se queda callada (P69) |
| Puerta al terminar | "Aquí vamos." | ✅ la primera vez; después deja salir directo |
| Ducha | primera vez, repetir, "Qué frío", silueta tras la cortina, estornudo al salir | ✅ las frases (primera vez, estornudo y al insistir). ❌ transición, silueta y sonido: falta arte (P70) |
| Armario | primero ducharse; frases para uniforme, pijama, casual y ropa sucia; ruge el estómago | ✅ antes de la ducha no se abre; la pijama no se pone; uniforme y estómago (como texto). La cesta habla si hay ropa sucia (en el tutorial aún no la hay, P71). ❌ casual (aún no se puede poner, P72) y sonido del estómago |
| Nevera | frases (antes de ducharse, sin compras, comida instantánea) | ✅ antes de ducharse (no abre la cocina, P77). ❌ sin compras y comida instantánea (P25) |
| Comida | comida instantánea y café | ❌ hoy se cocina comida casera (P25) |
| Estufa y escritorio | frases; Mayui come sentada | ✅ escritorio después de comer (P77). ❌ estufa sin comida y comer sentada (dibujo) |
| Lavamanos y espejo | todas | ✅ |
| "Voy tarde" (hacia las 7:30) | si se alarga en el cuarto: 3 frases | ✅ a las 07:30, 07:40 y 07:50, una por vez, sin interrumpir diálogos ni pantallas (P73) |
| Balcón | frases | ✅ tus 3 frases; después de la mañana se sale (P76) |
| Calendario | frases | ✅ (P77) |
| Casero en el lobby | explica el cobro | ✅ pero dice **viernes** y tu diseño dice **miércoles** (D6) |

## Detalles a decidir en los textos
- Puerta sin cepillarse: DIALOGOS no trae esa frase. Usé la de `Flow de juego.txt` ("Me levare la boca antes de salir.") como "Me lavaré la boca antes de salir." (P53).
- Sobre la nevera tus documentos se contradicen: DIALOGOS dice que no hay ingredientes; `Flow de juego.txt` pone 2 bolsas.

## Orden que recomiendo
1. ✅ Empezar a las 6:00.
2. ✅ Puerta con tu guion, usando la lista de tareas que ya existe (retirada la puerta provisional de `tutorial.gd`).
3. ✅ Frases de la ducha, el armario, la cama y el "Voy tarde".
4. Nevera y pudrición de la comida ([COCINA_Y_OBJETOS.md](COCINA_Y_OBJETOS.md)).
5. Comida instantánea y café (necesitan arte y decidir P25). El escritorio, el balcón y el calendario ya hablan.
6. Escribir el guion del trabajo (Bloque 1-2).
