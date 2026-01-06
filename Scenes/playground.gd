extends World


"""
Actividades: Dormir, Comer, Cocinar, Asearse (Baño, cepillarse), Lavar ropa, Trabajar y minijuegos ligados a trabajar, comprar (gestion de recursos), parada de autobus simple (navergación de mapa), tendedero, almacenamiento de items

NPCS: MAYUI, VEDA, posible personaje Cebollina

Eventos: Cobro de alquiler y servicios públicos, discursos de la empresa, remuneración diaria por asistencia al trabajo. Tiempos del día como: Mañana, Medio Día, Noche. 

Zonas: 2 confirmadas, Posible zona por estructurar
La casa

subzona es el tendedero (escenaT independiente? escena dentro de la casa?)

La empresa (contiene narrativa de la demo)

la empresa es grande, está conformada por pisos y tiene subzonas, planear eso

La zona comercial

qué puedes hacer dentro, qué puedes comprar, lavandería, etc
"""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TimeManager.minutes = 360
	GameManager.new_game()
	
	TimeManager.connect_to_weekday([TimeUtils.WEEKDAY.MIERCOLES], print.bind("hola"), "03:00", [])
	
	PlayerManager.stat_value_changed.connect(mensaje_de_mierda_gay_el_que_me_lea_excepto_yo)

func mensaje_de_mierda_gay_el_que_me_lea_excepto_yo(stat : Stat, value : float) -> void :
	print(stat.stat_display_name, " | ",value)
