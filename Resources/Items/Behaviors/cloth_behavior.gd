extends ItemBehavior
class_name ClothBehavior

#@export var cloth_data : ClothData
@export var layer : String = "body"

##### TODO crear un sistema de cambio de sprites del personaje, manejar esto aca
##### Mi idea es que el entity tenga una funcion de swap_sprite o algo y se llame desde aca
##### Se le pasa de referencia el item y el entity se encarga de agarrar la ropa que tiene puesta
##### y cambiarla por esta
