extends Effect
class_name EffectHourControl ## desaparece cuando llega 0, puede aumentar o disminuir

@export var time : String = "00:00" ## procurar usar el formato HH:MM

func substract_time(subs2time : String) -> void :
	if !TimeUtils.is_valid_format(subs2time) : printerr(" Formato de tiempo incorrecta, usar HH:MM");return
	
	time = TimeUtils.decrease_time(time, subs2time)
	check_time()

func add_time(subs2time : String) -> void :
	if !TimeUtils.is_valid_format(subs2time) : printerr(" Formato de tiempo incorrecta, usar HH:MM");return
	
	time = TimeUtils.increase_time(time, subs2time)

func check_time() -> void :
	if TimeUtils.is_lower_or_equal("00:00", time) :
		PlayerManager.remove_effect(effect_unique_name)
