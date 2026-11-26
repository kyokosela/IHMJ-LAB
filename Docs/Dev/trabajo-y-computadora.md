# Trabajo, dinero y computadora (prototipo)

Status: En progreso
Assign: Sela (hecho con IA)

Código de febrero y abril de 2026, **anterior al diseño actual de la oficina**
([`OFICINA_BORRADOR.md`](../Design/OFICINA_BORRADOR.md)). Sirve de referencia; no está pensado como versión final.

# 📘 `EconomyManager` (autoload)

`money` (inicial 350) · `DAILY_SALARY` 200 · `RENT_AMOUNT` 230 · `BUS_COST` 10.

`add_money`, `spend_money`, `record_daily_earnings`, `pay_weekly_salary`, `pay_rent`, `check_rent_due`.
Señales: `money_changed`, `salary_paid`, `rent_due`, `rent_paid`, `rent_overdue`, `insufficient_funds`.

# 📘 `AttendanceManager` (autoload)

`clock_in` / `clock_out`, tardanzas (−20), salida anticipada (−50), faltas (aviso, aviso, recorte −100, despido).
Jornada 08:00–17:00, almuerzo 13:00–13:45.

## ⚠️ Errores conocidos

| Error | Detalle |
|---|---|
| **El viernes no se paga** | El pago salta el viernes a las 16:00 (`day5_salary.tres`), antes de fichar la salida. Comprobado: 5 días trabajados pagan **800** en vez de 1.000. El pago del cambio de semana llega con los ingresos ya en cero |
| Tardanza | Cuenta desde las 08:00; el diseño dice 08:10 (D23) |
| Renta | Nada en las escenas reales permite pagarla |

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
