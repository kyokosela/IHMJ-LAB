extends SceneTree
## Simulación de coherencia del SISTEMA DE EFECTOS (Docs/Design/SISTEMA_EFECTOS.md, §7).
## Juega miles de semanas con distintos perfiles de jugador y mide qué efectos aparecen,
## cómo evoluciona la cordura y si hay "trampas" sin salida.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/simulacion_efectos.gd
##
## Es un modelo SIMPLIFICADO a nivel de día. Los números de R son los del documento: cámbialos,
## vuelve a correr y mira qué pasa. No sustituye las pruebas del juego real.

const N := 3000       # semanas simuladas por perfil
const SEMILLA := 20261121

const R := {
	"cordura_ini": 50.0, "energia_ini": 45.0,
	# --- Cordura: bucle cerrado (§2) ---
	"gan_rutina": 3.0, "gan_finde": 3.0, "domingo_acerca": 0.25,
	"dano_factor": 0.75,   # FJ2: "es más difícil afectarla que beneficiarla" -> las pérdidas se amortiguan
	"perd_max_dia": 10.0,
	"piso_cordura": 10.0,  # estabilizador: en el prólogo, descuidarse NO lleva a cordura 0 (solo un evento narrativo)
	"rebote": [[30.0, 2.0], [40.0, 1.5]],   # estabilizador: desde el fondo, las ganancias valen más (x2 bajo 30, x1.5 bajo 40)
	"calma_prot": [0.05, 0.08, 0.12],
	"sueno_cordura": [3.0, 5.0, 8.0],
	"debil_cordura": 5.0, "calle_cordura": 5.0, "desahogo_cordura": 2.0,
	# --- Causas activas ---
	"instant_estres": 0.5, "agua_fria_estres": 0.5, "calle_prob": 0.10,
	"mitig_max_dia": 2,
	# --- Sueño / insomnio ---
	"deuda_vigilia": 12.0, "deuda_pago_noche": 6.0, "deficit_umbral": 6.0, "deuda_max": 36.0,
	"insomnio_rango": [[4, 7], [2, 6], [0, 3]],
	# --- Energía ---
	# 3 % por hora en reposo (72/día, "Sistema de efectos") + acciones del día
	"gasto_trabajo": 94.0, "gasto_libre": 82.0, "gasto_dia1": 80.0, "casera_energia": 30.0, "instant_energia": 10.0,
	"desmayo_estres3": 0.5, "debil_agotada": 0.3, "debil_dias": 3,
	"hambre_salud_dia": 30.0,
}

var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	rng.seed = SEMILLA
	var perfiles := {
		"modelo": {"desp": [15.0, 16.0], "alarma": 0.0, "comidas": 3, "casera": 0.7, "salta": 0.0, "bano": 1.0,
			"cepillo": 0.95, "cafe": [0, 1], "cafe_inteligente": true, "pesado": 0.0, "apostar": 0.3, "gana": 0.45, "pastillas": true, "medicina": true},
		"neutro": {"desp": [15.0, 17.0], "alarma": 0.15, "comidas": 3, "casera": 0.65, "salta": 0.05, "bano": 0.8,
			"cepillo": 0.7, "cafe": [0, 1], "pesado": 0.1, "apostar": 0.5, "gana": 0.45, "pastillas": false, "medicina": false},
		"caotico": {"desp": [18.0, 20.0], "alarma": 0.7, "comidas": 2, "casera": 0.1, "salta": 0.4, "bano": 0.35,
			"cepillo": 0.2, "cafe": [2, 4], "pesado": 0.4, "apostar": 0.9, "gana": 0.4, "pastillas": false, "medicina": false},
	}
	print("\n=== SIMULACION DE EFECTOS · %d semanas por perfil · semilla %d ===" % [N, SEMILLA])
	var resumen := {}
	for nombre in perfiles:
		resumen[nombre] = _correr(perfiles[nombre])
	_imprimir(resumen)
	_rescate(perfiles)
	_alcance_largo(perfiles)
	if OS.get_cmdline_user_args().has("--traza"):
		_traza("modelo", perfiles.modelo, false, 7)
		_traza("rescate", perfiles.modelo, true, 14)
	if OS.get_cmdline_user_args().has("--traza-caos"):
		_traza("caotico", perfiles.caotico, false, 21)
	quit()

# ---------------------------------------------------------------- ¿se alcanzan TODOS los efectos? (21 días)
func _alcance_largo(perfiles: Dictionary) -> void:
	print("\n--- Alcance a largo plazo (21 días, fuera de la demo): % de partidas que llegan a ... ---")
	var claves := [["Estrés III", "e3"], ["Calma II", "c2"], ["Calma III", "c3"], ["Hipersomnia", "hip"], ["Insomnio III", "i3"], ["Sueño III", "s3"]]
	for nombre in ["modelo", "neutro", "caotico"]:
		var tot := {}
		for run in range(N):
			var s := _estado()
			s["stat_desmayos"] = 0; s["stat_debil"] = 0
			s["reg"] = {"dias_estres": 0, "dias_calma": 0, "dias_ins": 0, "dias_hambre": 0, "dias_sucio": 0, "min_cordura": 100.0}
			for d in range(1, 22):
				if d > 1: _chequeo_diario(s)
				_dia(s, perfiles[nombre], d)
				if s.muerto: break
			for k in s.reg:
				if s.reg[k] is bool and s.reg[k]: tot[k] = tot.get(k, 0.0) + 1.0
		var fila := String(nombre).rpad(9)
		for c in claves: fila += ("%s %s  " % [c[0], _pct(tot, c[1])])
		print(fila)

# ---------------------------------------------------------------- traza de UNA partida (depuración)
func _traza(nombre: String, perfil: Dictionary, crisis: bool, dias: int) -> void:
	print("\n--- Traza '%s' (una partida) ---" % nombre)
	var s := _estado()
	s["stat_desmayos"] = 0; s["stat_debil"] = 0
	s["reg"] = {"dias_estres": 0, "dias_calma": 0, "dias_ins": 0, "dias_hambre": 0, "dias_sucio": 0, "min_cordura": 100.0}
	if crisis:
		s.cordura = 12.0; s.estres = 3; s.estres_fue3 = true; s.ins = 3; s.ins_dias = 5; s.ins_mal = 4
		s.deuda = 30.0; s.inap = 2; s.hambre_dias = 1; s.sin_bano = 3; s.boca = true; s.salud = 80.0; s.energia = 40.0
	for d in range(2 if crisis else 1, dias + 1):
		if d > 1 or crisis: _chequeo_diario(s)
		var antes: String = "est=%d(d%d) cal=%d ins=%d" % [s.estres, s.estres_dias, s.calma, s.ins]
		_dia(s, perfil, d)
		print("D%-2d cord=%5.1f energ=%5.1f | %s -> est=%d(d%d agg%d) cal=%d ins=%d | deuda=%4.1f perdido=%s" % [
			d, s.cordura, s.energia, antes, s.estres, s.estres_dias, s.agg, s.calma, s.ins, s.deuda, str(s.perdido)])

# ---------------------------------------------------------------- utilidades
func _roll(p: float) -> bool:
	return rng.randf() < p

func _estado() -> Dictionary:
	return {
		"cordura": R.cordura_ini, "salud": 100.0, "energia": R.energia_ini,
		"estres": 0, "estres_dias": 0, "estres_fue3": false, "agg": 0,
		"calma": 0, "calma_dias": 0, "rutina_ayer": false,
		"ins": 0, "ins_dias": 0, "ins_mal": 0, "ins_racha": 0,
		"deuda": 0.0, "deficit": 0.0, "dormir_ok": true, "noches_ok": 0,
		"inap": 0, "inap_dias": 0, "ate": 0, "hip": 0, "hip_dias": 0,
		"hambre_dias": 0, "debil": 0, "sin_bano": 0, "boca": false, "hiperact": false,
		"mit_hoy": 0, "perd_hoy": 0.0, "perdido": false, "muerto": false,
		"stat_desmayos": 0, "stat_debil": 0, "stat_pastillas": 0,
		"reg": {"dias_estres": 0, "dias_calma": 0, "dias_ins": 0, "dias_hambre": 0, "dias_sucio": 0, "min_cordura": 100.0},
	}

func _rebote(c: float) -> float:
	for t in R.rebote:
		if c < t[0]: return t[1]
	return 1.0

func _nivel_sueno(deuda: float) -> int:
	if deuda <= 0.0: return 0
	if deuda <= 12.0: return 1
	if deuda <= 24.0: return 2
	return 3

func _min_horas(energia: float) -> int:
	if energia <= 15.0: return 10
	if energia <= 30.0: return 9
	if energia <= 50.0: return 8
	if energia <= 70.0: return 7
	return 6

func _energia_sueno(h: float) -> float:
	var t := [0.0, 5.0, 8.0, 10.0, 12.0, 15.0, 20.0, 30.0, 35.0, 38.0, 40.0]
	var i := clampi(int(floor(h)), 0, 10)
	var j := mini(i + 1, 10)
	return lerpf(t[i], t[j], h - floor(h)) if h < 10.0 else 40.0

# ---------------------------------------------------------------- estrés / calma
func _set_estres(s: Dictionary, v: int) -> void:
	v = clampi(v, 0, 3)
	if v == 3: s.estres_fue3 = true
	if v == 0 and s.estres > 0:
		s.estres_dias = 0
		if s.estres_fue3 and s.ins == 0:   # mitigarlo por completo desde III -> Insomnio
			s.ins = 1
		s.estres_fue3 = false
	if v != s.estres: s.estres_dias = 0
	s.estres = v

func _mitigar(s: Dictionary, n: int) -> void:
	n = mini(n, R.mitig_max_dia - s.mit_hoy)
	if n <= 0 or s.estres == 0: return
	s.mit_hoy += n
	_set_estres(s, s.estres - n)

func _causa_estres(s: Dictionary) -> void:
	if s.calma > 0:
		s.calma -= 1
	elif s.estres == 0:
		_set_estres(s, 1)
	else:
		s.estres_dias += 1   # una causa activa acelera la escalada

# ---------------------------------------------------------------- chequeo diario (al despertar)
func _chequeo_diario(s: Dictionary) -> void:
	s.mit_hoy = 0
	s.perd_hoy = 0.0
	s.hiperact = s.energia >= 90.0
	s.perdido = false
	var c: float = s.cordura
	# 1) escalada de lo que ya existe (antes de crear nada nuevo)
	if s.estres > 0:
		s.estres_dias += 1
		if s.estres == 1 and s.estres_dias >= 1 and c < 30.0 and _roll(0.5): _set_estres(s, 2)
		elif s.estres == 2 and s.estres_dias >= 2 and c < 20.0 and _roll(0.5): _set_estres(s, 3)
	if s.calma > 0:
		if s.rutina_ayer: s.calma_dias += 1
		if s.calma == 1 and s.calma_dias >= 1 and c > 70.0 and _roll(0.5): s.calma = 2; s.calma_dias = 0
		elif s.calma == 2 and s.calma_dias >= 1 and c > 80.0 and _roll(0.5): s.calma = 3; s.calma_dias = 0
	# 2) aparición por cordura (Estrés <-> Calma se reducen entre sí)
	var p_e := 0.5 if c < 30.0 else (0.25 if c < 40.0 else 0.0)
	var p_c := 0.5 if c > 70.0 else (0.25 if c > 60.0 else 0.0)
	if s.calma > 0 and _roll(p_e):
		s.calma -= 1
	elif s.estres > 0 and _roll(p_c):
		_set_estres(s, s.estres - 1)
	elif s.estres == 0 and s.calma == 0:
		if _roll(p_e): _set_estres(s, 1)
		elif _roll(p_c): s.calma = 1; s.calma_dias = 0
	# 3) insomnio y atenta
	if s.ins == 0 and c < 30.0: s.ins = 1
	if s.ins > 0:
		s.ins_dias += 1
		# nivel según la tabla: II = Cordura<30 + 2 noches malas seguidas; III = Cordura<15 + 2 noches malas
		if c < 15.0 and s.ins_mal >= 2: s.ins = 3
		elif c < 30.0 and s.ins_mal >= 2: s.ins = 2
		else: s.ins = 1
	else:
		s.ins_dias = 0
	var ate_nuevo: int = s.ins if (s.ins > 0 and s.ins_dias >= 2) else 0
	if ate_nuevo > 0 and s.hip > 0:   # Atenta y Hipersomnia son opuestos
		s.hip -= 1
		ate_nuevo = 0
	s.ate = ate_nuevo
	# 4) inapetencia e hipersomnia (derivados)
	if c < 30.0 or s.estres == 3:
		if s.inap == 0:
			if _roll(0.5): s.inap = 1; s.inap_dias = 0
		else:
			s.inap_dias += 1
			if s.inap == 1 and s.inap_dias >= 1: s.inap = 2; s.inap_dias = 0
			elif s.inap == 2 and s.inap_dias >= 2: s.inap = 3; s.inap_dias = 0
	else:
		s.inap = 0
	if s.calma == 3:
		if s.hip == 0:
			if _roll(0.5): s.hip = 1; s.hip_dias = 0
		else:
			s.hip_dias += 1
			if s.hip == 1 and s.hip_dias >= 1: s.hip = 2; s.hip_dias = 0
			elif s.hip == 2 and s.hip_dias >= 2: s.hip = 3; s.hip_dias = 0
	else:
		s.hip = 0
	# 5) tiradas que dependen de niveles
	if s.inap > 0 and _roll([0.15, 0.35, 0.70][s.inap - 1]): s.hambre_dias = maxi(s.hambre_dias, 1)
	if s.hip > 0 and _roll([0.15, 0.30, 0.60][s.hip - 1]) and s.deuda <= 0.0: s.deuda = R.deuda_vigilia
	if s.ate > 0 and _roll([0.10, 0.25, 0.50][s.ate - 1]): s.hiperact = true
	if s.estres > 0 and _roll([0.15, 0.30, 0.60][s.estres - 1]): s.hiperact = true
	# 6) debilitamiento por agotamiento y desmayo por estrés III
	if s.energia <= 15.0 and s.energia > 0.0 and s.debil == 0 and _roll(R.debil_agotada):
		_debilitar(s)
	if s.estres == 3 and _roll(R.desmayo_estres3):
		s.perdido = true
		s.stat_desmayos += 1
	# estado de la MAÑANA (un nivel III puede durar solo ese día: el desahogo lo baja antes de la noche)
	var r: Dictionary = s.reg
	if s.estres > 0: r["e%d" % s.estres] = true
	if s.calma > 0: r["c%d" % s.calma] = true
	if s.ins > 0: r["i%d" % s.ins] = true
	if s.hip > 0: r.hip = true

func _debilitar(s: Dictionary) -> void:
	s.debil = R.debil_dias
	s.perd_hoy += R.debil_cordura
	s.stat_debil += 1

# ---------------------------------------------------------------- plan del día según el perfil
func _plan(s: Dictionary, p: Dictionary, trabajo: bool, d: int) -> Dictionary:
	var pl := {"casera": 0, "instant": 0, "bano": false, "cepillo": false, "cafe": 0, "extra": 0,
		"apostar": false, "desp": 0.0, "alarma": false, "pastillas": false, "medicina": false}
	for i in range(p.comidas):
		if _roll(p.salta): continue
		if _roll(p.casera): pl.casera += 1
		else: pl.instant += 1
	pl.bano = _roll(p.bano)
	pl.cepillo = _roll(p.cepillo)
	pl.cafe = rng.randi_range(p.cafe[0], p.cafe[1])
	if trabajo:
		pl.extra = rng.randi_range(3, 5) if _roll(p.pesado) else rng.randi_range(0, 1)
	pl.apostar = (not trabajo) and _roll(p.apostar)
	pl.desp = rng.randf_range(p.desp[0], p.desp[1])
	pl.alarma = _roll(p.alarma)
	pl.pastillas = p.pastillas and s.ins >= 1
	pl.medicina = p.medicina and s.debil > 0
	if p.get("cafe_inteligente", false) and s.energia >= 80.0: pl.cafe = 0   # no tomar café con la energía alta
	if d == 1:   # el tutorial fuerza: desayuno instantáneo, ducha (fría) y cepillarse; el resto del día es libre
		if pl.instant == 0:
			pl.instant = 1
			if pl.casera > 0: pl.casera -= 1
		pl.bano = true; pl.cepillo = true; pl.cafe = 0; pl.extra = 0
	if s.perdido:   # día perdido por un desmayo
		pl.casera = 0; pl.instant = 1; pl.bano = false; pl.cepillo = false; pl.cafe = 0; pl.extra = 0; pl.apostar = false
	return pl

# ---------------------------------------------------------------- un día completo
func _dia(s: Dictionary, p: Dictionary, d: int) -> void:
	var dow := (d - 1) % 7
	var trabajo := dow < 5
	var finde := not trabajo
	var pl := _plan(s, p, trabajo, d)
	# --- comidas ---
	var exito := 1.0
	if s.inap > 0: exito = 1.0 - [0.20, 0.35, 0.50][s.inap - 1]
	var ok := 0
	var casera_ok := 0
	var energia_comida := 0.0
	for i in range(pl.casera):
		if _roll(exito): ok += 1; casera_ok += 1; energia_comida += R.casera_energia
	for i in range(pl.instant):
		if _roll(exito):
			ok += 1; energia_comida += R.instant_energia
			s.boca = true
			if _roll(R.instant_estres): _causa_estres(s)
	if casera_ok > 0: _mitigar(s, 1)   # comida casera caliente: -1 nivel de Estrés
	if ok == 0: s.hambre_dias += 1
	elif ok >= 2: s.hambre_dias = 0
	if s.hambre_dias >= 2: s.salud -= R.hambre_salud_dia
	# --- higiene ---
	if pl.bano:
		s.sin_bano = 0
		if d == 1:
			if _roll(R.agua_fria_estres): _causa_estres(s)
		else:
			_mitigar(s, 1)   # agua caliente: -1 nivel de Estrés
	else:
		s.sin_bano += 1
	if pl.cepillo: s.boca = false
	var sucio: bool = s.sin_bano >= 1 or s.boca
	# --- trabajo, café, apuestas, calle ---
	var umbral: int = 3 + s.ate   # Atenta sube el umbral de "exceso de trabajo"
	if trabajo and pl.extra >= umbral: _causa_estres(s)
	var hiper_previa: bool = s.hiperact
	for i in range(pl.cafe):
		if (hiper_previa or s.hiperact) and s.ins == 0: s.ins = 1   # reactivar Hiperactividad -> Insomnio
		s.hiperact = true
		if i == 0 and s.hip > 0: s.hip -= 1   # el café quita 1 nivel de Hipersomnia
	if pl.apostar:
		if _roll(p.gana):
			if s.estres > 0: _set_estres(s, 0)   # ganar apostando anula el Estrés
		else:
			s.calma = 0                          # perder apostando anula la Calma...
			_causa_estres(s)                     # ...y causa Estrés
	if trabajo:
		var pc: float = R.calle_prob
		if s.ate > 0: pc *= [0.8, 0.65, 0.5][s.ate - 1]
		if s.hip > 0: pc *= [1.4, 1.7, 2.0][s.hip - 1]
		if _roll(pc):
			s.perd_hoy += R.calle_cordura
			s.calma = 0
			_causa_estres(s)
	# --- desahogo (Estrés II y III): alivia el estrés pero cuesta cordura ---
	if s.estres >= 2:
		var ciclos := 1 if s.estres == 2 else 3
		s.agg += ciclos
		s.perd_hoy += R.desahogo_cordura * ciclos
		while s.agg >= 3 and s.estres > 0:
			s.agg -= 3
			_set_estres(s, s.estres - 1)
	else:
		s.agg = 0
	# --- energía ---
	var gasto: float = R.gasto_trabajo if trabajo else R.gasto_libre
	if d == 1: gasto = R.gasto_dia1
	if ok < 2: gasto *= 1.15
	if s.hiperact: gasto *= 0.9
	if s.debil > 0: gasto += 5.0
	if s.energia <= 15.0: gasto *= 0.25
	s.energia = clampf(s.energia + energia_comida - gasto, 0.0, 100.0)
	if s.energia <= 0.0:
		s.energia = 20.0   # desmayo: duerme donde esté con la fórmula de sueño
		s.stat_desmayos += 1
		_debilitar(s)
	if pl.medicina: s.debil = 0
	# --- rutina saludable (4 obligatorias; jugar es comodín) ---
	var items := (1 if casera_ok > 0 else 0) + (1 if pl.bano else 0) + (1 if s.dormir_ok else 0) + 1
	var completa: bool = items == 4 or (items == 3 and pl.apostar)
	s.rutina_ayer = completa
	if completa:
		if s.estres > 0: _mitigar(s, 1)
		elif s.calma == 0: s.calma = 1; s.calma_dias = 0
		else: s.calma_dias += 1
	if items <= 1: _causa_estres(s)   # rutinas desordenadas
	# --- balance de cordura (bucle cerrado) ---
	var ganancia := 0.0
	if completa: ganancia += R.gan_rutina
	if finde and items >= 2: ganancia += R.gan_finde
	if dow == 6 and s.cordura < 50.0: ganancia += R.domingo_acerca * (50.0 - s.cordura)
	ganancia *= _rebote(s.cordura)
	var nsu := _nivel_sueno(s.deuda)
	var perdida: float = (s.perd_hoy + (R.sueno_cordura[nsu - 1] if nsu > 0 else 0.0)) * R.dano_factor
	if s.calma > 0: perdida *= 1.0 - R.calma_prot[s.calma - 1]
	perdida = minf(perdida, R.perd_max_dia)
	s.cordura = clampf(s.cordura + ganancia - perdida, R.piso_cordura, 100.0)
	# --- vigilia y marcas del día ---
	if pl.desp > 16.0: s.deuda = maxf(s.deuda, R.deuda_vigilia)
	_marcar(s, ok, sucio)
	# --- noche: dormir ---
	_dormir(s, p, pl, trabajo)
	if s.debil > 0: s.debil -= 1
	if s.salud <= 0.0: s.muerto = true

func _dormir(s: Dictionary, p: Dictionary, pl: Dictionary, trabajo: bool) -> void:
	var min_h: int = _min_horas(s.energia)
	var objetivo: float = float(min_h)
	if pl.alarma: objetivo = maxf(3.0, min_h - rng.randi_range(1, 4))
	var horas := objetivo
	if s.ins > 0:
		if pl.pastillas:
			horas = float(min_h)   # las pastillas garantizan las horas mínimas esa noche y quitan 1 nivel
			s.stat_pastillas += 1
			if s.ins <= 1: s.ins = 0; s.ins_dias = 0; s.ate = 0
			else: s.ins -= 1
		else:
			var rg: Array = R.insomnio_rango[s.ins - 1]
			horas = minf(objetivo, float(rng.randi_range(rg[0], rg[1])))
	var propio: bool = horas >= float(min_h)
	s.dormir_ok = propio
	if propio:
		s.noches_ok += 1
		s.ins_mal = 0   # una noche apropiada corta la racha de noches malas
		if s.ins > 0:
			s.ins_racha += 1
			if s.ins_racha >= 2: s.ins = 0; s.ins_dias = 0; s.ins_mal = 0; s.ate = 0; s.ins_racha = 0
	else:
		s.noches_ok = 0
		s.ins_racha = 0
		s.ins_mal += 1
		if s.ins == 0: s.ins = 1
		var falta := float(min_h) - horas
		if s.deuda > 0.0: s.deuda += falta
		else:
			s.deficit += falta
			if s.deficit >= R.deficit_umbral: s.deuda = s.deficit; s.deficit = 0.0
	if horas >= 6.0 and s.deuda > 0.0:
		s.deuda = maxf(0.0, s.deuda - minf(horas, R.deuda_pago_noche))
	s.deuda = minf(s.deuda, R.deuda_max)   # tope: 6 noches de pago como máximo
	s.energia = clampf(s.energia + _energia_sueno(horas), 0.0, 100.0)
	# dormir apropiadamente baja el Estrés; si hubo jornada laboral el piso es el nivel I
	if propio and s.estres > 0:
		var piso := 1 if trabajo else 0
		var nuevo := maxi(piso, s.estres - 1)
		if s.noches_ok >= 2 and not trabajo: nuevo = 0
		var quita: int = s.estres - nuevo
		if quita > 0: _mitigar(s, quita)

# ---------------------------------------------------------------- registro
func _marcar(s: Dictionary, comidas_ok: int, sucio: bool) -> void:
	var r: Dictionary = s.reg
	if s.estres > 0: r["e%d" % s.estres] = true; r.dias_estres += 1
	if s.calma > 0: r["c%d" % s.calma] = true; r.dias_calma += 1
	if s.ins > 0: r["i%d" % s.ins] = true; r.dias_ins += 1
	var ns := _nivel_sueno(s.deuda)
	if ns > 0: r["s%d" % ns] = true
	if s.inap > 0: r.inap = true
	if s.ate > 0: r.ate = true
	if s.hip > 0: r.hip = true
	if s.debil > 0: r.debil = true
	if comidas_ok < 2: r.dias_hambre += 1
	if sucio: r.dias_sucio += 1
	r.min_cordura = minf(r.min_cordura, s.cordura)

func _correr(p: Dictionary) -> Dictionary:
	var acum := {"cordura": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], "final": [], "n": 0}
	var tot := {}
	for run in range(N):
		var s := _estado()
		s["stat_desmayos"] = 0
		s["stat_debil"] = 0
		s["reg"] = {"dias_estres": 0, "dias_calma": 0, "dias_ins": 0, "dias_hambre": 0, "dias_sucio": 0, "min_cordura": 100.0}
		for d in range(1, 8):
			if d > 1: _chequeo_diario(s)
			_dia(s, p, d)
			acum.cordura[d - 1] += s.cordura
			if s.muerto: break
		acum.final.append(s.cordura)
		for k in s.reg:
			var v = s.reg[k]
			tot[k] = tot.get(k, 0.0) + (1.0 if v is bool and v else (v if not v is bool else 0.0))
		tot["desmayos"] = tot.get("desmayos", 0.0) + (1.0 if s.stat_desmayos > 0 else 0.0)
		tot["debilitado"] = tot.get("debilitado", 0.0) + (1.0 if s.stat_debil > 0 else 0.0)
		tot["muerte"] = tot.get("muerte", 0.0) + (1.0 if s.muerto else 0.0)
		tot["pastillas"] = tot.get("pastillas", 0.0) + float(s.stat_pastillas)
		tot["cordura_menor_20"] = tot.get("cordura_menor_20", 0.0) + (1.0 if s.reg.min_cordura < 20.0 else 0.0)
		tot["cordura_menor_5"] = tot.get("cordura_menor_5", 0.0) + (1.0 if s.reg.min_cordura < 5.0 else 0.0)
	acum["tot"] = tot
	return acum

func _pct(tot: Dictionary, k: String) -> String:
	return "%d%%" % int(round(100.0 * tot.get(k, 0.0) / N))

func _imprimir(resumen: Dictionary) -> void:
	print("\n--- Cordura media al cierre de cada día (D1..D7) ---")
	for nombre in resumen:
		var fila := ""
		for d in range(7):
			fila += "%5.1f" % (resumen[nombre].cordura[d] / N)
		var fin: Array = resumen[nombre].final
		fin.sort()
		print("%s %s   | final: P10=%d  mediana=%d  P90=%d" % [nombre.rpad(8), fila, int(fin[int(N * 0.1)]), int(fin[int(N * 0.5)]), int(fin[int(N * 0.9)])])
	print("\n--- % de semanas en que aparece cada efecto ---")
	var claves := [["Estrés I", "e1"], ["Estrés II", "e2"], ["Estrés III", "e3"], ["Calma I", "c1"], ["Calma II", "c2"], ["Calma III", "c3"],
		["Insomnio I", "i1"], ["Insomnio II", "i2"], ["Insomnio III", "i3"], ["Sueño I", "s1"], ["Sueño II", "s2"], ["Sueño III", "s3"],
		["Inapetencia", "inap"], ["Atenta", "ate"], ["Hipersomnia", "hip"], ["Debilitamiento", "debilitado"], ["Desmayo", "desmayos"],
		["Cordura < 20 alguna vez", "cordura_menor_20"], ["Cordura < 5 alguna vez", "cordura_menor_5"], ["MUERTE", "muerte"]]
	var enc := String("Efecto").rpad(26)
	for nombre in resumen: enc += ("%s" % nombre).lpad(9)
	print(enc)
	for c in claves:
		var fila := String(c[0]).rpad(26)
		for nombre in resumen: fila += _pct(resumen[nombre].tot, c[1]).lpad(9)
		print(fila)
	print("\n--- Días promedio con ... (de 7) ---")
	for etq in [["Estrés", "dias_estres"], ["Calma", "dias_calma"], ["Insomnio", "dias_ins"], ["Hambre", "dias_hambre"], ["Suciedad", "dias_sucio"], ["Pastillas tomadas", "pastillas"]]:
		var fila := String(etq[0]).rpad(26)
		for nombre in resumen: fila += ("%.2f" % (resumen[nombre].tot.get(etq[1], 0.0) / N)).lpad(9)
		print(fila)

# ---------------------------------------------------------------- prueba de "trampas": ¿se puede salir del peor estado?
func _rescate(perfiles: Dictionary) -> void:
	print("\n--- Rescate: peor estado posible (cordura 12, Estrés III, Insomnio III, Sueño III, inapetencia, sucio) ---")
	print("Salida de la crisis = cordura >= 30, Estrés <= I, Insomnio <= I y Sueño <= I.  Se mide a los 14 días.")
	for nombre in ["modelo", "caotico"]:
		var dias: Array = []
		var recuperadas := 0
		var fin_cordura := 0.0
		var cuenta := {"cordura": 0, "estres": 0, "ins": 0, "sueno": 0}
		var pastillas := 0.0
		for run in range(N):
			var s := _estado()
			s.cordura = 12.0; s.estres = 3; s.estres_fue3 = true; s.ins = 3; s.ins_dias = 5; s.ins_mal = 4
			s.deuda = 30.0; s.inap = 2; s.hambre_dias = 1; s.sin_bano = 3; s.boca = true; s.salud = 80.0; s.energia = 40.0
			s["stat_desmayos"] = 0; s["stat_debil"] = 0
			s["reg"] = {"dias_estres": 0, "dias_calma": 0, "dias_ins": 0, "dias_hambre": 0, "dias_sucio": 0, "min_cordura": 100.0}
			var dia_ok := -1
			for d in range(2, 16):   # empezamos en lunes (d=2 evita el tutorial)
				_chequeo_diario(s)
				_dia(s, perfiles[nombre], d)
				if s.muerto: break
				if dia_ok < 0 and s.cordura >= 30.0 and s.estres <= 1 and s.ins <= 1 and _nivel_sueno(s.deuda) <= 1:
					dia_ok = d - 1
			if dia_ok > 0:
				recuperadas += 1
				dias.append(dia_ok)
			fin_cordura += s.cordura
			pastillas += float(s.stat_pastillas)
			if s.cordura >= 30.0: cuenta.cordura += 1
			if s.estres <= 1: cuenta.estres += 1
			if s.ins <= 1: cuenta.ins += 1
			if _nivel_sueno(s.deuda) <= 1: cuenta.sueno += 1
		dias.sort()
		var mediana: int = dias[int(dias.size() * 0.5)] if dias.size() > 0 else -1
		print("perfil %s sale de la crisis: %3d%%  (mediana %d dias) | a los 14 dias: cordura media %.1f · cordura>=30: %d%% · Estres<=I: %d%% · Insomnio<=I: %d%% · Sueno<=I: %d%% | pastillas usadas (media): %.1f" % [
			nombre.rpad(8), int(round(100.0 * recuperadas / N)), mediana, fin_cordura / N,
			int(100.0 * cuenta.cordura / N), int(100.0 * cuenta.estres / N), int(100.0 * cuenta.ins / N), int(100.0 * cuenta.sueno / N), pastillas / N])
