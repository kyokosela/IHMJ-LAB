extends Resource
class_name ItemState

@export var id : String = ""
@export var exclusive_group : String = ""

func on_event(_item : Item, _event : Event): pass
func process(_item : Item, _delta : float) : pass

#ejemplito:

#wet.exclusive_group = "wetness"
#dry.exclusive_group = "wetness"
#dirty.exclusive_group = "cleanliness"
#clean.exclusive_group = "cleanliness"

#De esta manera WET y DRY como tienen de grupo exclusivo wetness, solo uno de ellos
#estara activo al tiempo, lo mismo con DIRTY y CLEAN. Sin embargo como WET y CLEAN
#no estan en el mismo grupo exclusivo, ambos pueden estar al mismo tiempo
#item.gd maneja el añadir estados con este comportamiento ^
