extends Resource
class_name Stat

signal value_changed(new_value : float) ## notifica cuando el valor de la estadistica sufre algun cambio

@export var stat_unique_name : String ## Sirve como ID/identificador de la estadistica y debe ser unico, por ejemplo EN
@export var stat_display_name : String : ## Nombre a renderizar en pantalla, por ejemplo ENERGIA
	get() :
		return tr(stat_display_name)
@export var value : float = 0.0 : ## Valor de la estadistica, emite una señal cuando cambia
	set(_value):
		value = clamp(_value, 0, 100.0)
		PlayerManager.stat_value_changed.emit(self, _value)
		value_changed.emit(_value)
