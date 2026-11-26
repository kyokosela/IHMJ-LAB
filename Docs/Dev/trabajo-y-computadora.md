# Trabajo, dinero y computadora (prototipo)

Status: En progreso
Assign: Sela (hecho con IA)

Código de febrero y abril de 2026, **anterior al diseño actual de la oficina**
([`OFICINA_BORRADOR.md`](../Design/OFICINA_BORRADOR.md)). Sirve de referencia; no está pensado como versión final.

# 📘 `EconomyManager` (autoload)

`money` (inicial 350) · `DAILY_SALARY` 200 · `RENT_AMOUNT` 230 · `BUS_COST` 10.

`add_money`, `spend_money`, `record_daily_earnings`, `pay_weekly_salary` (solo una vez por semana:
`salary_paid_this_week`), `pay_rent`, `check_rent_due`.
Señales: `money_changed`, `salary_paid`, `rent_due`, `rent_paid`, `rent_overdue`, `insufficient_funds`.

# 📘 `AttendanceManager` (autoload)

`clock_in` / `clock_out`, tardanzas (−20), salida anticipada (−50), faltas (aviso, aviso, recorte −100, despido).
Jornada 08:00–17:00, almuerzo 13:00–13:45.

## 💵 Paga semanal (D7, corregida el 2026-11-26)

- El evento `DAY5_SALARY` (`day5_salary.tres`, **cada viernes a las 17:00**) llama a `pay_week_salary()`.
- Si Mayui sigue fichada, la paga espera (`salary_pending`) y llega **al marcar la salida**, contando el viernes.
- Si nunca la marca, o el reloj salta las 17:00 (durmiendo), llega al acabar el viernes con los días completos.
- Se paga lo anotado de lunes a viernes menos los descuentos; ya no se paga al cambiar de semana.
- Prueba: `Tools/probar_paga.gd`. La paga futura (base + aciertos, P96) no está programada.

## ⚠️ Errores conocidos

| Error | Detalle |
|---|---|
| Tardanza | Cuenta desde las 08:00; el diseño dice 08:10 (D23) |
| Entrar antes de las 08:00 | El evento de jornada de las 08:00 (días 2–5) borra `arrived_today`: a las 17:00 se anota una falta aunque haya ido (comprobado: martes 07:50, 1 falta; el día se paga igual) |
| Renta | Nada en las escenas reales permite pagarla; el vencimiento salta a las 18:00 y el diseño dice 17:00 |
| Cambio de mes | Al pasar el día 30 la semana vuelve a 1 a mitad de semana y se borran los ingresos acumulados (visto en el código, sin comprobar) |

# 📘 Otros managers

| Script | Estado |
|---|---|
| `RelationshipManager` | Puntos y niveles por personaje; casi sin uso (historia apagada) |
| `EmailPoolManager` | Carga los correos por día desde `Entries/Narrative/` (38 correos de relleno) |
| `bracelet_manager.gd`, `token_manager.gd` | **Huérfanos:** no son autoload ni los usa nadie |

# 💻 Computadora

- `MailEntry`: nuevos `email_id`, `day_available`, `sender_type`, condiciones por banderas.
- Bandeja: lista con scroll (reemplaza la bandeja con física); `MailItemSimple`.
- Tareas de correo (`Events/`): `trivia`, `typing`, `classification`, `differences`, `leave`. Todas se **dibujan por
  código**. `MailEvent.check_stress_failure()` hace fallar con Estrés.
- `portal.gd` (nómina, asistencia, evaluación), `base_window.gd` (tamaño de ventana por app).
- ⚠️ Los correos de relleno **siguen saliendo** en la PC aunque la historia esté apagada.
- ⚠️ La carpeta `Narrative/` tiene `.gdignore`: Godot la ignora, así que en un ejecutable esos correos faltarían (sin
  comprobar exportando).

# 🎰 Otras pantallas

`evaluation_screen.gd` (⚠️ espera 27 correos escritos a mano), `market.gd` (cobra pero no entrega objetos), `arcade.gd`
(apuesta a cara o cruz). `office.gd` abre la PC.

## Qué reutilizar para el piso 1 (triaje por correo)

La bandeja, `MailEntry` y la idea de "un evento por tarea" sirven de base. Las tareas actuales (trivia, tecleo) no son las
del diseño nuevo.
