# I HATE MY JOB — CONTENT PASS IMPLEMENTATION PLAN
## Codex 5.3-Ready Technical Specification

**Version:** 1.0  
**Target Engine:** Godot 4.6  
**Prerequisite:** All systems from `IMPLEMENTATION_PLAN_v2.md` must be implemented  
**Document Source:** `IMHJ_Documento_Maestro_v2.md`

---

# TABLE OF CONTENTS

1. [Overview & File Index](#1-overview--file-index)
2. [Phase 1: Dialogic Characters](#2-phase-1-dialogic-characters)
3. [Phase 2: Dialogic Timelines](#3-phase-2-dialogic-timelines)
4. [Phase 3: Schedule Events Days 2-7](#4-phase-3-schedule-events-days-2-7)
5. [Phase 4: Email Content Expansion](#5-phase-4-email-content-expansion)
6. [Phase 5: UI Scene Creation](#6-phase-5-ui-scene-creation)
7. [Testing Checklist](#7-testing-checklist)

---

# 1. OVERVIEW & FILE INDEX

## 1.1 Scope

This plan covers the **Content Pass** - filling in actual game content (dialogue, events, email text) into the systems already implemented by the previous plan.

## 1.2 Files to Create

| Category | Count | Directory |
|----------|-------|-----------|
| Dialogic Characters | 4 | `DialoguePlugin/CHARACTERS/` |
| Dialogic Timelines | 15 | `DialoguePlugin/TIMELINE/` |
| Schedule Events | 17 | `Resources/Events/Schedule/` |
| UI Scenes | 2 | `UI/Evaluation/`, `Prefabs/Workspace/Computer/Apps/Portal/` |

## 1.3 Files to Modify

| Category | Count | Directory |
|----------|-------|-----------|
| Email Resources | 38 | `Resources/Computer/Apps/Mail/Entries/Narrative/` |

## 1.4 Critical Rules

1. **DO NOT modify any `.gd` script files** - all systems are already implemented
2. **Use exact file formats** shown in examples below
3. **Dialogic uses `.dch` for characters and `.dtl` for timelines**
4. **All Spanish text** - the game is in Spanish
5. **Match character voice** as defined in design document

## 1.5 Character Voice Reference

| Character | Voice | Rules |
|-----------|-------|-------|
| **Veda** | Fria, precisa | Sin saludos. Una idea/correo. Firma: — V. |
| **Madina** | Calida, nerviosa | Erratas, "!!", "...". La unica humana. |
| **Casero** | Gruñon, directo | Viejo, sin paciencia. Tono neutral->pasivo-agresivo. |
| **Sativa** | Profesional, desinteresada | Cumple su rol. Estrictamente laboral. |
| **RRHH** | Robotico | Legal, impersonal. Pies de pagina auto-conscientes. |
| **Sistema** | Sin personalidad | Automatizado. Humor oscuro en detalles. |
| **Piso 2** | Autoritario | Ordenes sin contexto. "Usted". |
| **Mayui** | Sarcastica, rebelde | Monologos internos. Realista. |

---

# 2. PHASE 1: DIALOGIC CHARACTERS

**Priority:** HIGH  
**Dependencies:** None  
**Output:** 4 `.dch` files

---

## 2.1 Veda Character

**Action:** CREATE FILE

**File:** `DialoguePlugin/CHARACTERS/Veda.dch`

```json
{
"@path": "res://addons/dialogic/Resources/character.gd",
"@subpath": NodePath(""),
"&_translation_id": "veda_char",
"&color": Color(0.5, 0.2, 0.6, 1),
"&custom_info": {
"prefix": "",
"sound_mood_default": "",
"sound_moods": {},
"style": "test_style",
"suffix": ""
},
"&default_portrait": "",
"&description": "Supervisora de toda la empresa. Uva. Fria y precisa.",
"&display_name": "Veda",
"&mirror": false,
"&nicknames": ["V.", "Supervisora"],
"&offset": Vector2(0, 0),
"&portraits": {},
"&scale": 1.0
}
```

---

## 2.2 Madina Character

**Action:** CREATE FILE

**File:** `DialoguePlugin/CHARACTERS/Madina.dch`

```json
{
"@path": "res://addons/dialogic/Resources/character.gd",
"@subpath": NodePath(""),
"&_translation_id": "madina_char",
"&color": Color(0.9, 0.6, 0.3, 1),
"&custom_info": {
"prefix": "",
"sound_mood_default": "",
"sound_moods": {},
"style": "test_style",
"suffix": ""
},
"&default_portrait": "",
"&description": "Compañera de trabajo. Misma posicion que Mayui. Calida y nerviosa.",
"&display_name": "Madina",
"&mirror": false,
"&nicknames": ["Madi"],
"&offset": Vector2(0, 0),
"&portraits": {},
"&scale": 1.0
}
```

---

## 2.3 Casero Character

**Action:** CREATE FILE

**File:** `DialoguePlugin/CHARACTERS/Casero.dch`

```json
{
"@path": "res://addons/dialogic/Resources/character.gd",
"@subpath": NodePath(""),
"&_translation_id": "casero_char",
"&color": Color(0.6, 0.3, 0.3, 1),
"&custom_info": {
"prefix": "",
"sound_mood_default": "",
"sound_moods": {},
"style": "test_style",
"suffix": ""
},
"&default_portrait": "",
"&description": "Dueño del edificio. Rabano viejo y gruñon.",
"&display_name": "Casero",
"&mirror": false,
"&nicknames": [""],
"&offset": Vector2(0, 0),
"&portraits": {},
"&scale": 1.0
}
```

---

## 2.4 Sativa Character

**Action:** CREATE FILE

**File:** `DialoguePlugin/CHARACTERS/Sativa.dch`

```json
{
"@path": "res://addons/dialogic/Resources/character.gd",
"@subpath": NodePath(""),
"&_translation_id": "sativa_char",
"&color": Color(0.4, 0.7, 0.4, 1),
"&custom_info": {
"prefix": "",
"sound_mood_default": "",
"sound_moods": {},
"style": "test_style",
"suffix": ""
},
"&default_portrait": "",
"&description": "Recepcionista. Lechuga. Profesional y desinteresada.",
"&display_name": "Sativa",
"&mirror": false,
"&nicknames": [""],
"&offset": Vector2(0, 0),
"&portraits": {},
"&scale": 1.0
}
```

---

# 3. PHASE 2: DIALOGIC TIMELINES

**Priority:** HIGH  
**Dependencies:** Phase 1 (Characters)  
**Output:** 15 `.dtl` files

## 3.0 Dialogic Timeline Format Reference

Dialogic 2 uses `.dtl` files with this syntax:
- `character_name: "Dialogue text" #id:XX`
- `[signal arg="value"]` for emitting signals
- `- Choice text` for player choices
- `    Nested content under choice` (indented with tabs/spaces)
- `[set var="value"]` for setting Dialogic variables

---

## 3.1 Casero Introduction (Day 1)

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/casero_intro.dtl`

```
Casero: Ah. La nueva inquilina. #id:1
Casero: M-21, ¿verdad? #id:2
Mayui: (Asiente) #id:3
Casero: Bien. Escucha, porque no lo voy a repetir. #id:4
Casero: La renta son S/230. Se paga los viernes. #id:5
Casero: Si no pagas el viernes, tienes hasta el domingo. #id:6
Casero: Despues de eso... bueno. Ya sabes como funciona. #id:7
Mayui: (Este tipo no pierde el tiempo...) #id:8
Casero: El edificio tiene reglas. No ruido despues de las 22:00. No visitas sin aviso. #id:9
Casero: Y no quiero problemas. ¿Entendido? #id:10
- Entendido.
	Mayui: Entendido. #id:11
	Casero: Bien. #id:12
- ¿Y si tengo preguntas?
	Mayui: ¿Y si tengo preguntas sobre algo? #id:13
	Casero: Pregunta rapido. No tengo todo el dia. #id:14
	Casero: Pero la mayoria de cosas las resuelves tu sola. Asi funciona aqui. #id:15
Casero: Bienvenida al edificio. #id:16
Casero: ...Supongo. #id:17
[signal arg="casero_intro_complete"]
```

---

## 3.2 Veda Day 1 Appearance

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/veda_day1.dtl`

```
Mayui: (Una figura se acerca. Brazalete morado. Debe ser...) #id:1
Veda: M-21. #id:2
Mayui: (No saluda. Solo mi numero.) #id:3
Veda: Primer dia. #id:4
Veda: Espero que te adaptes. #id:5
Veda: No todos lo logran. #id:6
Mayui: (Se va sin esperar respuesta.) #id:7
Mayui: (...¿Eso fue una bienvenida o una advertencia?) #id:8
[signal arg="met_veda"]
```

---

## 3.3 Madina Cafe Day 2

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/madina_cafe_day2.dtl`

```
Madina: ¡¡M-21!! ¿Puedo sentarme? #id:1
- Claro, adelante.
	Mayui: Claro, adelante. #id:2
	Madina: ¡¡Gracias!! Es que... no me gusta comer sola jajaj #id:3
- Prefiero estar sola.
	Mayui: Prefiero estar sola, la verdad. #id:4
	Madina: Oh... ok, perdon!! Otro dia entonces... #id:5
	[signal arg="rejected_madina_day2"]
Madina: Oye... ¿como te ha parecido todo? #id:6
Madina: Las cosas han cambiado mucho desde que llegue... #id:7
Mayui: ¿Cambiado como? #id:8
Madina: No se... el ambiente. La gente esta mas... tensa? #id:9
Madina: Pero bueno!! Seguro son imaginaciones mias jajaj #id:10
Madina: Come, come. El almuerzo se pasa volando aqui... #id:11
[signal arg="madina_cafe_complete"]
```

---

## 3.4 Madina Tension Day 3

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/madina_tension.dtl`

```
Madina: Oye... M-21... #id:1
Madina: ¿Has notado algo raro ultimamente? #id:2
Mayui: ¿Raro como? #id:3
Madina: No se... la gente esta mas tensa... #id:4
Madina: Los correos de Piso 2 son mas... frios? #id:5
Madina: Y ayer vi a Veda hablando con alguien de RRHH por como media hora... #id:6
Mayui: (Madina nota cosas. Eso puede ser util... o peligroso.) #id:7
- ¿Crees que pasa algo malo?
	Mayui: ¿Crees que pasa algo malo? #id:8
	Madina: No lo se!! Pero... ten cuidado, ¿si? #id:9
	Madina: No quiero que te pase nada... #id:10
- Probablemente no es nada.
	Mayui: Probablemente no es nada. Las empresas siempre son asi. #id:11
	Madina: Si... tienes razon... probablemente son imaginaciones mias... #id:12
Madina: Bueno!! Volvamos al trabajo antes de que alguien nos vea... #id:13
[signal arg="madina_tension_complete"]
```

---

## 3.5 Madina M-88 Object Day 4

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/madina_m88_object.dtl`

```
Madina: M-21... ¿tienes un momento? #id:1
Madina: Es que... encontre algo... #id:2
Mayui: ¿Que cosa? #id:3
Madina: Del escritorio de M-88... #id:4
Madina: Estaba limpiando y... bueno... #id:5
Madina: Me pone nerviosa tenerlo... #id:6
Mayui: (Madina saca un papel doblado. Parece una nota.) #id:7
- Dejame verlo.
	Mayui: Dejame verlo. #id:8
	Madina: ¡¡Gracias!! Es que... no se que hacer con esto... #id:9
	Madina: Ten. Pero... ten cuidado, ¿si? #id:10
	[signal arg="received_m88_note"]
- No quiero involucrarme.
	Mayui: No quiero involucrarme en lo que sea que es esto. #id:11
	Madina: Oh... ok... lo entiendo... #id:12
	Madina: Supongo que lo tirare entonces... #id:13
	[signal arg="rejected_m88_note"]
Madina: M-88 era... era buena persona, ¿sabes? #id:14
Madina: Llegaba tarde pero... siempre saludaba a todo el mundo... #id:15
Madina: Un dia simplemente... no vino mas. #id:16
Madina: Dijeron que fue "transferido" pero... #id:17
Madina: ...bueno. No importa. #id:18
[signal arg="madina_m88_complete"]
```

---

## 3.6 Casero Rent Reminder Day 4

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/casero_rent_reminder.dtl`

```
Mayui: (El telefono suena. Es el casero.) #id:1
Casero: M-21. #id:2
Casero: Mañana vence la renta. S/230. #id:3
Casero: No quiero tener que recordartelo de nuevo. #id:4
- Lo se. Estare lista.
	Mayui: Lo se. Estare lista. #id:5
	Casero: Bien. Eso espero. #id:6
- ¿Y si necesito mas tiempo?
	Mayui: ¿Y si necesito un poco mas de tiempo? #id:7
	Casero: No hay mas tiempo. El viernes es el viernes. #id:8
	Casero: Despues de eso... el domingo es la ultima oportunidad. #id:9
	Casero: Y no quieres llegar a eso. Creeme. #id:10
Casero: Hasta mañana. #id:11
Mayui: (Cuelga sin despedirse.) #id:12
[signal arg="rent_reminder_complete"]
```

---

## 3.7 Sunday Week Preparation

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/sunday_prep.dtl`

```
Mayui: (Mañana es lunes.) #id:1
Mayui: (Otra semana. Otra ronda de correos, tareas, y la mirada de Veda.) #id:2
Mayui: (¿Estoy lista?) #id:3
- Si. Puedo con esto.
	Mayui: (Si. Puedo con esto. Una semana mas.) #id:4
	Mayui: (Solo tengo que seguir adelante.) #id:5
- No lo se.
	Mayui: (No lo se. Pero no tengo opcion.) #id:6
	Mayui: (Dejar de trabajar no es una alternativa.) #id:7
- Odio esto.
	Mayui: (Odio esto. Pero el odio no paga la renta.) #id:8
	Mayui: (Asi que aqui estamos.) #id:9
Mayui: (Mañana es lunes.) #id:10
Mayui: (...Vamos.) #id:11
[signal arg="week_prep_complete"]
```

---

## 3.8 Casero Rent Warning 1

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/casero_rent_warning1.dtl`

```
Casero: M-21. #id:1
Casero: El viernes paso. La renta no llego. #id:2
Mayui: Lo se. Estoy trabajando en eso. #id:3
Casero: "Trabajando en eso" no paga facturas. #id:4
Casero: Tienes hasta mañana. Domingo. Mediodia. #id:5
Casero: Despues de eso... no quieres saber que pasa. #id:6
- Tendre el dinero.
	Mayui: Tendre el dinero. Lo prometo. #id:7
	Casero: Las promesas no valen nada aqui. Solo la savia. #id:8
- ¿Que pasa si no pago?
	Mayui: ¿Que pasa si no puedo pagar? #id:9
	Casero: Entonces buscas otro lugar donde dormir. #id:10
	Casero: Y en este invernadero... no hay muchos lugares para gente sin savia. #id:11
Casero: Mañana. Mediodia. S/230. #id:12
Casero: No lo olvides. #id:13
[signal arg="rent_warning1_complete"]
```

---

## 3.9 Casero Rent Final

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/casero_rent_final.dtl`

```
Casero: M-21. #id:1
Casero: Es mediodia. Domingo. #id:2
Casero: ¿Tienes mi dinero? #id:3
Mayui: (No tengo suficiente...) #id:4
Casero: Tu silencio me dice todo. #id:5
Casero: Mira. No es personal. Es negocio. #id:6
Casero: Tienes hasta mañana. Primera hora. S/230 o te vas. #id:7
Casero: No hay mas extensiones. No hay mas charlas. #id:8
Casero: Mañana. Primera hora. #id:9
Mayui: (Se va. La puerta se cierra con un golpe seco.) #id:10
Mayui: (...¿Que voy a hacer?) #id:11
[signal arg="eviction_warning"]
```

---

## 3.10 Fired - Absence

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/fired_absence.dtl`

```
Mayui: (Un correo de RRHH. Asunto: "Terminacion de contrato.") #id:1
Mayui: (Lo abro. Ya se lo que dice.) #id:2
Mayui: "M-21: Debido a ausencias repetidas y no justificadas..." #id:3
Mayui: "...su contrato ha sido terminado con efecto inmediato." #id:4
Mayui: "Por favor, devuelva su brazalete en recepcion." #id:5
Mayui: "— RRHH" #id:6
Mayui: (Ni siquiera una firma real. Solo tres letras.) #id:7
Mayui: (...Esto es todo. Se acabo.) #id:8
[signal arg="game_over_fired"]
```

---

## 3.11 Fired - Late

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/fired_late.dtl`

```
Veda: M-21. #id:1
Veda: Tenemos un problema. #id:2
Mayui: (Veda nunca usa la palabra "problema"...) #id:3
Veda: Llegaste tarde. Repetidamente. #id:4
Veda: Te advertimos. Documentamos. Dimos oportunidades. #id:5
Veda: No las aprovechaste. #id:6
Mayui: Yo... #id:7
Veda: No hay excusas que me interesen. #id:8
Veda: Tu contrato termina hoy. Entrega el brazalete en recepcion. #id:9
Veda: — V. #id:10
Mayui: (Se va. Sin mas.) #id:11
Mayui: (...Se acabo.) #id:12
[signal arg="game_over_fired"]
```

---

## 3.12 Fired - Performance

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/fired_performance.dtl`

```
Mayui: (Un correo de Veda. Directo. Sin asunto.) #id:1
Veda: M-21. #id:2
Veda: Tu desempeño esta semana fue inaceptable. #id:3
Veda: Los errores se acumularon. Las tareas no se completaron. #id:4
Veda: No tenemos espacio para empleados que no cumplen el minimo. #id:5
Veda: Tu contrato termina hoy. #id:6
Veda: — V. #id:7
Mayui: (Minimo. Ni siquiera llegue al minimo.) #id:8
Mayui: (...¿Y ahora que?) #id:9
[signal arg="game_over_fired"]
```

---

## 3.13 Veda Stare Day 4 (Optional - Visual Event)

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/veda_stare.dtl`

```
Mayui: (Veda pasa cerca de mi escritorio.) #id:1
Mayui: (Se detiene. Me mira.) #id:2
Mayui: (No dice nada.) #id:3
Mayui: (Sigue caminando.) #id:4
Mayui: (...¿Que fue eso?) #id:5
[signal arg="veda_stare_complete"]
```

---

## 3.14 Friday Evaluation

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/friday_evaluation.dtl`

```
Veda: M-21. Sientate. #id:1
Mayui: (La oficina de Veda. Minimalista. Fria. Como ella.) #id:2
Veda: Tu primera semana. #id:3
Veda: Revisemos. #id:4
Mayui: (Veda abre una carpeta. Mis numeros. Mis errores. Todo documentado.) #id:5
Veda: Correos procesados. Tareas completadas. Errores cometidos. #id:6
Veda: Todo esta aqui. #id:7
Veda: La evaluacion refleja exactamente lo que hiciste. Nada mas. #id:8
Mayui: ¿Y... que significa eso para mi? #id:9
Veda: Significa que tienes potencial para estar en otro piso. #id:10
Veda: Si decides usarlo, estaras. #id:11
Veda: Si no lo decides... tambien es una decision. #id:12
Mayui: (Por primera vez, Veda dice algo que no es solo presion.) #id:13
Veda: Puedes retirarte. #id:14
Mayui: (Me levanto. La evaluacion termino.) #id:15
[signal arg="evaluation_complete"]
```

---

## 3.15 Madina High Relationship Message (Day 7)

**Action:** CREATE FILE

**File:** `DialoguePlugin/TIMELINE/madina_warning.dtl`

```
Mayui: (Un mensaje de Madina. Tarde en la noche.) #id:1
Madina: M-21... ¿estas despierta? #id:2
Madina: Perdona por escribir tan tarde... #id:3
Madina: Es que... tengo un presentimiento raro. #id:4
Madina: Ten cuidado mañana, ¿si? #id:5
Madina: Algo se siente... raro. #id:6
Madina: No se explicarlo... #id:7
Madina: Solo... cuidate. #id:8
Madina: Buenas noches. #id:9
Mayui: (Madina siempre nota cosas antes que nadie...) #id:10
Mayui: (...¿Que sabe que yo no se?) #id:11
[signal arg="madina_warning_complete"]
```

---

# 4. PHASE 3: SCHEDULE EVENTS DAYS 2-7

**Priority:** HIGH  
**Dependencies:** None  
**Output:** 17 `.tres` files

## 4.0 Schedule Event Format Reference

Based on existing `day1_alarm.tres`:

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = [DAY_NUMBER]
time = "[HH:MM]"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "[Display Name]"
event_unique_name = "[UNIQUE_ID]"
```

---

## 4.1 Day 2 Events

### 4.1.1 Work Hours Day 2

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day2_work_hours.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 2
time = "08:00"

[sub_resource type="Resource" id="end_config"]
script = ExtResource("2")
day = 2
time = "17:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
end = SubResource("end_config")
event_name = "Jornada Laboral Dia 2"
event_unique_name = "WORK_HOURS_DAY2"
```

### 4.1.2 Madina Cafe Day 2

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day2_madina_cafe.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 2
time = "13:20"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Madina en Cafeteria"
event_unique_name = "DAY2_MADINA_CAFE"
```

### 4.1.3 Veda Email Day 2

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day2_veda_email.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 2
time = "09:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Correo de Veda"
event_unique_name = "DAY2_VEDA_EMAIL"
```

---

## 4.2 Day 3 Events

### 4.2.1 Work Hours Day 3

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day3_work_hours.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 3
time = "08:00"

[sub_resource type="Resource" id="end_config"]
script = ExtResource("2")
day = 3
time = "17:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
end = SubResource("end_config")
event_name = "Jornada Laboral Dia 3"
event_unique_name = "WORK_HOURS_DAY3"
```

### 4.2.2 Madina Tension Day 3

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day3_madina_tension.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 3
time = "13:30"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Madina Tension"
event_unique_name = "DAY3_MADINA_TENSION"
```

### 4.2.3 Piso 2 Order Day 3

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day3_piso2_order.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 3
time = "15:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Orden de Piso 2"
event_unique_name = "DAY3_PISO2_ORDER"
```

---

## 4.3 Day 4 Events

### 4.3.1 Work Hours Day 4

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day4_work_hours.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 4
time = "08:00"

[sub_resource type="Resource" id="end_config"]
script = ExtResource("2")
day = 4
time = "17:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
end = SubResource("end_config")
event_name = "Jornada Laboral Dia 4"
event_unique_name = "WORK_HOURS_DAY4"
```

### 4.3.2 Veda Evaluation Notice Day 4

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day4_veda_notice.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 4
time = "09:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Aviso Evaluacion Veda"
event_unique_name = "DAY4_VEDA_NOTICE"
```

### 4.3.3 Madina M-88 Object Day 4

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day4_madina_object.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 4
time = "13:15"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Madina Objeto M-88"
event_unique_name = "DAY4_MADINA_OBJECT"
```

### 4.3.4 Veda Stare Day 4

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day4_veda_stare.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 4
time = "15:30"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Veda Mirada"
event_unique_name = "DAY4_VEDA_STARE"
```

### 4.3.5 Rent Reminder Day 4

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day4_rent_reminder.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 4
time = "18:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Recordatorio Renta"
event_unique_name = "DAY4_RENT_REMINDER"
```

---

## 4.4 Day 5 Events

### 4.4.1 Work Hours Day 5

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day5_work_hours.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 5
time = "08:00"

[sub_resource type="Resource" id="end_config"]
script = ExtResource("2")
day = 5
time = "17:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
end = SubResource("end_config")
event_name = "Jornada Laboral Dia 5"
event_unique_name = "WORK_HOURS_DAY5"
```

### 4.4.2 Friday Evaluation Day 5

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day5_evaluation.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 5
time = "15:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Evaluacion de Veda"
event_unique_name = "DAY5_EVALUATION"
```

### 4.4.3 Salary Payment Day 5

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day5_salary.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 5
time = "16:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Pago Semanal"
event_unique_name = "DAY5_SALARY"
```

### 4.4.4 Rent Due Day 5

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day5_rent_due.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 5
time = "18:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Vencimiento Renta"
event_unique_name = "DAY5_RENT_DUE"
```

### 4.4.5 M-88 Email Day 5

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day5_m88_email.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 5
time = "22:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Correo M-88"
event_unique_name = "DAY5_M88_EMAIL"
```

---

## 4.5 Day 6 Events (Saturday)

### 4.5.1 Weekend Market Day 6

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day6_market.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 6
time = "10:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Mercado de Fin de Semana"
event_unique_name = "DAY6_MARKET"
```

### 4.5.2 Arcade Tournament Day 6

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day6_arcade.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 6
time = "14:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Torneo Arcade"
event_unique_name = "DAY6_ARCADE"
```

---

## 4.6 Day 7 Events (Sunday)

### 4.6.1 Madina Laundry Day 7

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day7_madina_laundry.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 7
time = "11:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Madina en Lavanderia"
event_unique_name = "DAY7_MADINA_LAUNDRY"
```

### 4.6.2 Casero Final (If Not Paid) Day 7

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day7_casero_final.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 7
time = "12:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Casero Confrontacion Final"
event_unique_name = "DAY7_CASERO_FINAL"
```

### 4.6.3 Week Preparation Day 7

**Action:** CREATE FILE

**File:** `Resources/Events/Schedule/day7_week_prep.tres`

```
[gd_resource type="Resource" script_class="EventScheduled" load_steps=3 format=3]

[ext_resource type="Script" path="res://Resources/Events/event_scheduled.gd" id="1"]
[ext_resource type="Script" path="res://Resources/Schedules/schedule_config.gd" id="2"]

[sub_resource type="Resource" id="start_config"]
script = ExtResource("2")
day = 7
time = "17:00"

[resource]
script = ExtResource("1")
start = SubResource("start_config")
event_name = "Preparacion Semana"
event_unique_name = "DAY7_WEEK_PREP"
```

---

# 5. PHASE 4: EMAIL CONTENT EXPANSION

**Priority:** HIGH  
**Dependencies:** None  
**Output:** 38 modified `.tres` files

## 5.0 Email Content Rules

1. **DO NOT change** `email_id`, `day_available`, `sender_type`, `is_conditional`, `required_flags`, `excluded_flags`
2. **ONLY modify** `sender`, `subject`, `content` fields
3. **Match character voice** exactly as defined in Section 1.5
4. **Spanish text only**
5. **Use multiline strings** with proper escape sequences

---

## 5.1 MONDAY EMAILS (Tutorial Day)

### Email #01 - Verificacion (RRHH)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_01.tres`

**Changes:**
- `sender` = `"RRHH"`
- `subject` = `"VERIFICACION DE IDENTIDAD"`
- `content` = (see below)

**Content:**
```
M-21:

Necesitamos que confirmes que eres quien dices ser.

Si, sabemos que parece redundante. Es obligatorio igual.

Complete el formulario adjunto para verificar su identidad como empleado activo de esta organizacion.

— RRHH

*Nadie leyo esto antes de enviarlo.*
```

---

### Email #02 - Transcripcion (Administracion)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_02.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"TRANSCRIPCION REQUERIDA"`
- `content` = (see below)

**Content:**
```
M-21:

Audio adjunto. Necesitamos transcripcion.

Instrucciones:
- Transcriba textualmente
- [INAUDIBLE] para fragmentos no claros
- Si encuentra algo "extraño", ignorelo

— Administracion
```

---

### Email #03 - Discrepancias (Administracion)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_03.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"REVISION DE DISCREPANCIAS"`
- `content` = (see below)

**Content:**
```
M-21:

Dos versiones del formulario semana 22.
Señale discrepancias.

No es emocionante. Hagalo de todas formas.

— Administracion

Nota: Version A indica 47 empleados activos. Version B indica 46. Esto puede o no ser relevante.
```

---

### Email #04 - Mantenimiento (Opcional)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_04.tres`

**Changes:**
- `sender` = `"Mantenimiento"`
- `subject` = `"REPORTE DE ESTADO"`
- `content` = (see below)

**Content:**
```
Hola:

¿Algo necesita atencion?

Si todo esta bien, ignore esto.
Si algo esta mal, tambien puede ignorarlo.
Probablemente tardemos semanas.

— Mantenimiento

*"Si no esta roto, espere."*
```

---

## 5.2 TUESDAY EMAILS

### Email #05 - Clasificacion (Nueva Categoria)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_05.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"CLASIFICACION - NUEVAS CATEGORIAS"`
- `content` = (see below)

**Content:**
```
M-21:

Documentos adjuntos requieren clasificacion.

Nueva categoria disponible: CONFIDENCIAL (sello rojo o marcado "P2")

Algunos documentos mencionan "Proyecto Savia" y "reestructuracion". Clasificar segun corresponda.

Nota: Uno de los documentos esta marcado como "DESCONTINUADO". No se preocupe por eso.

— Administracion
```

---

### Email #06 - Veda: Productividad

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_06.tres`

**Changes:**
- `sender` = `"V."`
- `subject` = `"PRODUCTIVIDAD"`
- `content` = (see below)

**Content:**
```
M-21.

Revise ayer. Funcional.

Funcional es el minimo. No el objetivo.

Todo queda documentado. La evaluacion del viernes incluye todo.

— V.
```

---

### Email #07 - Inventario Mecanografia

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_07.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"INVENTARIO - TRANSCRIPCION"`
- `content` = (see below)

**Content:**
```
M-21:

Transcriba el audio de inventario adjunto.

Nota: La grapadora T-4 aparece dos veces con cantidades distintas. Ignorelo. Problema conocido.

— Administracion
```

---

### Email #08 - Protocolos Trivia

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_08.tres`

**Changes:**
- `sender` = `"RRHH"`
- `subject` = `"EVALUACION DE PROTOCOLOS"`
- `content` = (see below)

**Content:**
```
M-21:

Los protocolos han sido actualizados.

Complete la evaluacion adjunta.

Nota: los protocolos evaluados son los ANTERIORES a la actualizacion.
Los nuevos entran en vigor el lunes.

Lo sentimos por la confusion. No la habra.

— RRHH

*Nadie reviso si esto tenia sentido.*
```

---

### Email #09 - Spam: Lonchera

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_09.tres`

**Changes:**
- `sender` = `"M-33"`
- `subject` = `"mi lonchera"`
- `content` = (see below)

**Content:**
```
es la tercera vez esta semana

tiene mi nombre. marcador permanente. grande.

no la toquen por favor

— M-33

pd: si la tienen y la devuelven no pregunto nada
```

---

## 5.3 WEDNESDAY EMAILS

### Email #10 - Reclasificacion

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_10.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"ACTUALIZACION DE CRITERIOS"`
- `content` = (see below)

**Content:**
```
M-21:

Los criterios fueron actualizados esta mañana.

Cambios:
- "PERSONAL" ahora incluye: ACTIVO / INACTIVO / DESCONTINUADO
- "CONFIDENCIAL" incluye numeros de 4 digitos que comienzan con "04"

Aplicar retroactivamente a documentos pendientes.

— Administracion
```

---

### Email #11 - Transcripcion: Evaluacion Interna

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_11.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"TRANSCRIPCION - EVALUACION INTERNA"`
- `content` = (see below)

**Content:**
```
M-21:

Audio de evaluacion interna adjunto. Transcribir textualmente.

El contenido menciona "optimizacion de plantilla" y "maduracion insuficiente".

Los fragmentos [INAUDIBLE] deben marcarse como tal. No intente adivinar.

— Administracion
```

---

### Email #12 - Dos Libros (Diferencias)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_12.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"REVISION DE CONTABILIDAD"`
- `content` = (see below)

**Content:**
```
M-21:

Adjuntos: Libro A (uso interno) y Libro B (reporte a direccion).

Identifique discrepancias entre ambas versiones.

Nota: Si los numeros no cuadran, no es su problema. Solo reportelo.

— Administracion
```

---

### Email #13 - Piso 2: Orden

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_13.tres`

**Changes:**
- `sender` = `"Piso 2"`
- `subject` = `"DOCUMENTACION DE PERSONAL"`
- `content` = (see below)

**Content:**
```
A: Supervision Piso 1
CC: M-21

Requerimos documentacion actualizada de empleados ACTIVOS.

Formato estandar. Sin excepciones.

Entregar antes del cierre de jornada.

— Piso 2
```

---

### Email #14 - Madina: M-88

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_14.tres`

**Changes:**
- `sender` = `"Madina"`
- `subject` = `"oye..."`
- `content` = (see below)

**Content:**
```
M-21!!

¿notaste el escritorio vacio dos puestos al lado?

M-88. llegaba tarde pero era simpatico.

un dia no vino mas. dijeron "transferido" pero...

no te asustes jajaj
¿almorzamos? :)

— Madi
```

---

### Email #15 - Normativas Trivia

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_15.tres`

**Changes:**
- `sender` = `"RRHH"`
- `subject` = `"EVALUACION DE NORMATIVAS"`
- `content` = (see below)

**Content:**
```
M-21:

Complete la evaluacion sobre normativas internas.

Consulte el manual actualizado para respuestas.

Nota: El manual esta en proceso de actualizacion. Use la version anterior mientras tanto.

— RRHH

*El contenido de este correo puede o no ser relevante para la evaluacion.*
```

---

## 5.4 THURSDAY EMAILS (Dia de Maxima Presion)

### Email #16 - Pendiente de Resolucion

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_16.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"CLASIFICACION - PENDIENTE DE RESOLUCION"`
- `content` = (see below)

**Content:**
```
M-21:

Nueva categoria disponible: PENDIENTE DE RESOLUCION

Documentos adjuntos incluyen expedientes sin resolver.

Nota: Uno de los expedientes solo tiene numero, sin nombre. Comienza con 04.

Clasificar segun corresponda.

— Administracion
```

---

### Email #17 - Veda: Viernes

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_17.tres`

**Changes:**
- `sender` = `"V."`
- `subject` = `"EVALUACION"`
- `content` = (see below)

**Content:**
```
M-21.

Evaluacion mañana. 3 PM. Mi oficina.

No llegue tarde.

— V.
```

---

### Email #18 - Transcripcion Directa a Veda

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_18.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"TRANSCRIPCION - CONFIDENCIAL"`
- `content` = (see below)

**Content:**
```
M-21:

Esta transcripcion va directamente a Supervision.

No queda en sistema general.

Transcribir con precision. Sin comentarios adicionales.

— Administracion
```

---

### Email #19 - Lista Fantasma (Diferencias)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_19.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"REVISION DE PERSONAL - URGENTE"`
- `content` = (see below)

**Content:**
```
M-21:

Dos listas de personal adjuntas.

Lista A: 46 empleados.
Lista B: 47 empleados.

Identifique la discrepancia.

Nota: Si un empleado existe en papel pero no en la oficina, reportelo.

— Administracion
```

---

### Email #20 - Madina: Objeto

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_20.tres`

**Changes:**
- `sender` = `"Madina"`
- `subject` = `"tengo algo..."`
- `content` = (see below)

**Content:**
```
¿podrias pasarte en el almuerzo?

encontre algo del escritorio de M-88...
me pone nerviosa tenerlo

si no puedes no pasa nada!! :)

— Madi
```

---

### Email #21 - Seguridad Trivia

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_21.tres`

**Changes:**
- `sender` = `"RRHH"`
- `subject` = `"PROTOCOLO DE SEGURIDAD"`
- `content` = (see below)

**Content:**
```
M-21:

Recordatorio de protocolo de seguridad.

Si encuentra irregularidades:
- Reporte a su supervisor
- NO discuta con compañeros
- NO investigue por su cuenta

Complete la evaluacion adjunta.

— RRHH

*Este recordatorio no esta relacionado con ningun evento especifico.*
```

---

### Email #22 - Piso 2: Recordatorio

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_22.tres`

**Changes:**
- `sender` = `"Piso 2"`
- `subject` = `"RECORDATORIO DE CONFIDENCIALIDAD"`
- `content` = (see below)

**Content:**
```
A todos los empleados:

La informacion interna es confidencial.

Discutir asuntos laborales fuera de canales autorizados constituye una violacion al contrato.

Este recordatorio no esta dirigido a nadie en particular.

— Piso 2
```

---

## 5.5 FRIDAY EMAILS (Cierre Emocional)

### Email #23 - Clasificacion Final

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_23.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"CLASIFICACION FINAL - CIERRE SEMANAL"`
- `content` = (see below)

**Content:**
```
M-21:

Ultimos documentos de la semana.

Categorias aplicables: DESCONTINUADO — ARCHIVADO

Algunos expedientes fueron procesados y guardados. Es papeleo rutinario.

— Administracion
```

---

### Email #24 - Veda: Post-Evaluacion

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_24.tres`

**Changes:**
- `sender` = `"V."`
- `subject` = `"RESULTADO"`
- `content` = (see below)

**Content:**
```
M-21.

La evaluacion refleja exactamente lo que hizo. Nada mas.

Tiene potencial para estar en otro piso.
Si decide usarlo, estara.

Si no lo decide, tambien es una decision.

— V.
```

---

### Email #25 - Destruccion

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_25.tres`

**Changes:**
- `sender` = `"Administracion"`
- `subject` = `"DESTRUCCION DE DOCUMENTOS"`
- `content` = (see below)

**Content:**
```
M-21:

Al finalizar el proceso, los originales seran destruidos.

Solo queda la version que usted valide.

La responsabilidad recae en el empleado que firmo.

— Administracion
```

---

### Email #26 - Madina: Viernes

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_26.tres`

**Changes:**
- `sender` = `"Madina"`
- `subject` = `"VIERNES!!"`
- `content` = (see below)

**Content:**
```
LLEGO EL VIERNES!!!!

me alegra que estes aqui todavia jajaj

descansa

— Madi
```

---

### Email #27 - Cierre Sistema

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_27.tres`

**Changes:**
- `sender` = `"Sistema"`
- `subject` = `"CIERRE SEMANAL"`
- `content` = (see below)

**Content:**
```
════════════════════
CIERRE SEMANAL
════════════════════

Correos procesados: [XX]
Tareas completadas: [XX]
Tasa de eficiencia: [XX]%

Que tenga un buen fin de semana.

*(Este mensaje fue generado automaticamente.
La empresa no le desea realmente un buen fin de semana.
Es una formalidad programada.)*
════════════════════
```

---

## 5.6 CONDITIONAL EMAILS (#28-#38)

### Email #28 - Falta 1

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_28.tres`

**Changes:**
- `sender` = `"RRHH"`
- `subject` = `"ADVERTENCIA - AUSENCIA"`
- `content` = (see below)

**Content:**
```
M-21:

Se ha registrado una ausencia no justificada.

Esta es una advertencia formal.

Las ausencias repetidas tienen consecuencias segun el reglamento interno.

— RRHH
```

---

### Email #29 - Falta 2

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_29.tres`

**Changes:**
- `sender` = `"RRHH"`
- `subject` = `"ADVERTENCIA SERIA - SEGUNDA AUSENCIA"`
- `content` = (see below)

**Content:**
```
M-21:

Se ha registrado una segunda ausencia no justificada.

Esta es una advertencia seria.

Una ausencia mas resultara en consecuencias economicas.

— RRHH
```

---

### Email #30 - Falta 3 (Recorte Salarial)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_30.tres`

**Changes:**
- `sender` = `"RRHH"`
- `subject` = `"ACCION DISCIPLINARIA - RECORTE SALARIAL"`
- `content` = (see below)

**Content:**
```
M-21:

Debido a ausencias repetidas, su salario ha sido recortado.

Esta accion es inmediata y no negociable.

Una ausencia adicional resultara en terminacion de contrato.

— RRHH
```

---

### Email #31 - Falta 4+ (Despido)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_31.tres`

**Changes:**
- `sender` = `"V."`
- `subject` = `"TERMINACION"`
- `content` = (see below)

**Content:**
```
M-21.

Las ausencias se acumularon.

Su contrato termina hoy.

Entregue el brazalete en recepcion.

— V.
```

---

### Email #32 - Spam Impresora

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_32.tres`

**Changes:**
- `sender` = `"M-45"`
- `subject` = `"la impresora otra vez"`
- `content` = (see below)

**Content:**
```
¿alguien mas tiene problemas con la impresora del pasillo?

llevo tres dias intentando imprimir un documento
cada vez me da error diferente

si alguien sabe como arreglarla avisen pls

— M-45
```

---

### Email #33 - Encuesta Satisfaccion

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_33.tres`

**Changes:**
- `sender` = `"RRHH"`
- `subject` = `"ENCUESTA DE SATISFACCION"`
- `content` = (see below)

**Content:**
```
M-21:

Por favor complete la encuesta de satisfaccion adjunta.

Sus respuestas son anonimas.

Nota: Sus respuestas no son anonimas.

— RRHH

*Completar esta encuesta es "voluntario" pero altamente recomendado.*
```

---

### Email #34 - Prestamo M-44

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_34.tres`

**Changes:**
- `sender` = `"M-44"`
- `subject` = `"favor urgente"`
- `content` = (see below)

**Content:**
```
oye M-21

se que apenas nos conocemos pero...

¿podrias prestarme S/30? es urgente

te lo devuelvo el viernes sin falta, lo prometo

— M-44
```

---

### Email #35 - Restriccion Nocturna

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_35.tres`

**Changes:**
- `sender` = `"Seguridad"`
- `subject` = `"RESTRICCION DE ACCESO"`
- `content` = (see below)

**Content:**
```
A todos los empleados:

El acceso despues de las 18:00 esta restringido.

Motivo: [REDACTADO]

Cualquier empleado encontrado en las instalaciones fuera de horario sera reportado.

— Seguridad
```

---

### Email #36 - Recordatorio Renta

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_36.tres`

**Changes:**
- `sender` = `"Sistema Edificio"`
- `subject` = `"RECORDATORIO DE PAGO"`
- `content` = (see below)

**Content:**
```
M-21:

Recordatorio automatico:

Su renta vence pronto.
Monto: S/230
Fecha limite: Viernes

Evite recargos pagando a tiempo.

— Sistema Automatizado del Edificio
```

---

### Email #37 - EL CORREO MISTERIOSO (M-88)

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_37.tres`

**Changes:**
- `sender` = `"??@???"`
- `subject` = `""`
- `content` = (see below)

**Content:**
```
no confies en la evaluacion

no confies en V.

Nivel -1. Tu sabes donde.

— M-88
```

---

### Email #38 - Respuesta Mantenimiento

**Action:** MODIFY FILE

**File:** `Resources/Computer/Apps/Mail/Entries/Narrative/email_38.tres`

**Changes:**
- `sender` = `"Mantenimiento"`
- `subject` = `"RE: REPORTE DE ESTADO"`
- `content` = (see below)

**Content:**
```
M-21:

Recibimos su reporte.

Su solicitud ha sido registrada y sera atendida a la brevedad posible.

Tiempo estimado de resolucion: [INDEFINIDO]

— Mantenimiento

*"A la brevedad posible" es una expresion, no una promesa.*
```

---

# 6. PHASE 5: UI SCENE CREATION

**Priority:** MEDIUM  
**Dependencies:** Scripts already exist  
**Output:** 2 `.tscn` files

## 6.1 Evaluation Screen Scene

**Action:** CREATE FILE

**File:** `UI/Evaluation/evaluation_screen.tscn`

```
[gd_scene load_steps=2 format=3 uid="uid://evaluation_screen"]

[ext_resource type="Script" path="res://UI/Evaluation/evaluation_screen.gd" id="1"]

[node name="EvaluationScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.1, 0.1, 0.15, 0.95)

[node name="Container" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -150.0
offset_right = 200.0
offset_bottom = 150.0

[node name="Title" type="Label" parent="Container"]
layout_mode = 2
text = "EVALUACION SEMANAL"
horizontal_alignment = 1

[node name="Separator1" type="HSeparator" parent="Container"]
layout_mode = 2

[node name="EmailsProcessed" type="Label" parent="Container"]
layout_mode = 2
text = "Correos procesados: 0"

[node name="TasksCompleted" type="Label" parent="Container"]
layout_mode = 2
text = "Tareas completadas: 0"

[node name="ErrorsMade" type="Label" parent="Container"]
layout_mode = 2
text = "Errores cometidos: 0"

[node name="Efficiency" type="Label" parent="Container"]
layout_mode = 2
text = "Eficiencia: 0%"

[node name="Separator2" type="HSeparator" parent="Container"]
layout_mode = 2

[node name="Result" type="Label" parent="Container"]
layout_mode = 2
text = "Resultado: PENDIENTE"
horizontal_alignment = 1

[node name="CloseButton" type="Button" parent="Container"]
layout_mode = 2
text = "Cerrar"
```

---

## 6.2 Portal App Scene

**Action:** CREATE FILE

**File:** `Prefabs/Workspace/Computer/Apps/Portal/portal.tscn`

```
[gd_scene load_steps=2 format=3 uid="uid://portal_app"]

[ext_resource type="Script" path="res://Prefabs/Workspace/Computer/Apps/Portal/portal.gd" id="1"]

[node name="Portal" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="TabContainer" type="TabContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = -10.0

[node name="Salario" type="VBoxContainer" parent="TabContainer"]
layout_mode = 2

[node name="SalaryTitle" type="Label" parent="TabContainer/Salario"]
layout_mode = 2
text = "NOMINA ACTUAL"

[node name="SalaryAmount" type="Label" parent="TabContainer/Salario"]
layout_mode = 2
text = "S/ 0"

[node name="SalaryDetails" type="RichTextLabel" parent="TabContainer/Salario"]
layout_mode = 2
custom_minimum_size = Vector2(0, 200)
text = "Detalles de nomina..."

[node name="Asistencia" type="VBoxContainer" parent="TabContainer"]
layout_mode = 2

[node name="AttendanceTitle" type="Label" parent="TabContainer/Asistencia"]
layout_mode = 2
text = "REGISTRO DE ASISTENCIA"

[node name="AttendanceGrid" type="GridContainer" parent="TabContainer/Asistencia"]
layout_mode = 2
columns = 2

[node name="Evaluaciones" type="VBoxContainer" parent="TabContainer"]
layout_mode = 2

[node name="EvalTitle" type="Label" parent="TabContainer/Evaluaciones"]
layout_mode = 2
text = "EVALUACIONES ANTERIORES"

[node name="EvalList" type="ItemList" parent="TabContainer/Evaluaciones"]
layout_mode = 2
custom_minimum_size = Vector2(0, 200)
```

---

# 7. TESTING CHECKLIST

## 7.1 Pre-Implementation Verification

- [ ] All scripts from IMPLEMENTATION_PLAN_v2.md are present
- [ ] `NarrativeFlags` autoload exists and is registered
- [ ] `EconomyManager` autoload exists and is registered
- [ ] `AttendanceManager` autoload exists and is registered
- [ ] `RelationshipManager` autoload exists and is registered
- [ ] `EventManager` signals exist (`event_activated`, `event_deactivated`)

## 7.2 Phase 1 Testing (Characters)

- [ ] All 4 `.dch` files created in `DialoguePlugin/CHARACTERS/`
- [ ] Files are valid JSON format
- [ ] Godot recognizes characters in Dialogic editor

## 7.3 Phase 2 Testing (Timelines)

- [ ] All 15 `.dtl` files created in `DialoguePlugin/TIMELINE/`
- [ ] Each timeline can be loaded with `Dialogic.start("[name]")`
- [ ] Signals emit correctly from timelines
- [ ] Character names match `.dch` files

## 7.4 Phase 3 Testing (Schedule Events)

- [ ] All 17 `.tres` files created in `Resources/Events/Schedule/`
- [ ] Events load without errors in Godot
- [ ] `EventManager` triggers events at correct times
- [ ] `narrative_event_handler.gd` handles all event unique names

## 7.5 Phase 4 Testing (Emails)

- [ ] All 38 email `.tres` files have full content
- [ ] Emails display correctly in mail UI
- [ ] Conditional emails respect flag requirements
- [ ] Email minigames launch from email content

## 7.6 Phase 5 Testing (UI Scenes)

- [ ] `evaluation_screen.tscn` loads without errors
- [ ] `portal.tscn` loads without errors
- [ ] Scripts connect to UI elements correctly

## 7.7 Full Playthrough Test

- [ ] Day 1: All tutorials work, casero intro plays
- [ ] Day 2: Veda email arrives, Madina cafe event triggers
- [ ] Day 3: Tension events, Piso 2 order CC visible
- [ ] Day 4: M-88 object choice works, rent reminder triggers
- [ ] Day 5: Evaluation scene plays, salary paid, rent due
- [ ] Day 6: Weekend market accessible
- [ ] Day 7: Week preparation monologue plays

## 7.8 Conditional Path Tests

- [ ] Missing work triggers absence emails correctly
- [ ] 4 absences = fired (fired_absence.dtl plays)
- [ ] Not paying rent triggers warnings correctly
- [ ] Accepting M-88 note sets `nota_madina` flag
- [ ] Email #37 appears only with `nota_madina` flag

---

# APPENDIX A: NARRATIVE EVENT HANDLER UPDATES

The `narrative_event_handler.gd` script already contains handlers for most events. Ensure the following event unique names are handled:

**Already Handled:**
- `DAY1_ALARM` -> `_trigger_alarm_tutorial()`
- `DAY1_CASERO_INTRO` -> `_trigger_casero_intro()`
- `DAY1_VEDA_APPEAR` -> `_trigger_veda_day1()`
- `DAY2_MADINA_CAFE` -> `_trigger_madina_cafe_day2()`
- `DAY3_MADINA_TENSION` -> `_trigger_madina_tension()`
- `DAY4_MADINA_OBJECT` -> `_trigger_madina_m88_object()`
- `DAY4_VEDA_STARE` -> `_trigger_veda_stare()`
- `DAY4_RENT_REMINDER` -> `_trigger_rent_reminder()`
- `DAY5_EVALUATION` -> `_trigger_friday_evaluation()`
- `DAY5_RENT_DUE` -> `EconomyManager.check_rent_due()`
- `DAY5_M88_EMAIL` -> `_check_m88_email()`
- `DAY6_MARKET` -> `_trigger_weekend_market()`
- `DAY7_WEEK_PREP` -> `_trigger_week_preparation()`

**Need Handler (Add to narrative_event_handler.gd):**
- `WORK_HOURS_DAY2` through `WORK_HOURS_DAY5` - Same as `WORK_HOURS`
- `DAY2_VEDA_EMAIL` - Can be handled by email system
- `DAY3_PISO2_ORDER` - Can be handled by email system
- `DAY4_VEDA_NOTICE` - Can be handled by email system
- `DAY5_SALARY` - Connect to `EconomyManager.pay_salary()`
- `DAY6_ARCADE` - Set flag for arcade availability
- `DAY7_MADINA_LAUNDRY` - Trigger Madina encounter
- `DAY7_CASERO_FINAL` - Trigger final rent confrontation

---

# APPENDIX B: QUICK REFERENCE - FILE COUNTS

| Phase | Type | Count |
|-------|------|-------|
| Phase 1 | Dialogic Characters | 4 |
| Phase 2 | Dialogic Timelines | 15 |
| Phase 3 | Schedule Events | 17 |
| Phase 4 | Email Content Updates | 38 |
| Phase 5 | UI Scenes | 2 |
| **TOTAL** | **Files to Create/Modify** | **76** |

---

**END OF CONTENT PASS IMPLEMENTATION PLAN**

*Generated: February 2026*
*For use with Codex 5.3 or equivalent AI coding assistant*
