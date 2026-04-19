extends Control

signal market_closed

const PRICES := {
	"comida_instant": 25,
	"comida_pack": 60,
	"comida_casera": 30,
	"jabon_c": 10,
	"jabon_b": 20,
	"jabon_a": 35,
}

@onready var balance_label: Label = $Container/BalanceLabel
@onready var feedback_label: Label = $Container/FeedbackLabel
@onready var close_button: Button = $Container/CloseButton

func _ready() -> void:
	_update_balance()
	feedback_label.text = ""
	close_button.pressed.connect(_on_close)
	$Container/Items/ComidaInstant/BuyBtn.pressed.connect(_buy_item.bind("comida_instant"))
	$Container/Items/ComidaPack/BuyBtn.pressed.connect(_buy_item.bind("comida_pack"))
	$Container/Items/ComidaCasera/BuyBtn.pressed.connect(_buy_item.bind("comida_casera"))
	$Container/Items/JabonC/BuyBtn.pressed.connect(_buy_item.bind("jabon_c"))
	$Container/Items/JabonB/BuyBtn.pressed.connect(_buy_item.bind("jabon_b"))
	$Container/Items/JabonA/BuyBtn.pressed.connect(_buy_item.bind("jabon_a"))

func _update_balance() -> void:
	balance_label.text = "Savia: S/%d" % EconomyManager.get_balance()

func _buy_item(item_id: String) -> void:
	var price: int = PRICES[item_id]
	if not EconomyManager.can_afford(price):
		feedback_label.text = "No tienes suficiente (S/%d)" % price
		feedback_label.modulate = Color.RED
		return

	EconomyManager.spend_money(price, "MARKET_" + item_id.to_upper())
	_apply_item_effect(item_id)
	_update_balance()

func _apply_item_effect(item_id: String) -> void:
	feedback_label.modulate = Color.WHITE
	match item_id:
		"comida_instant":
			PlayerManager.remove_effect("HUNGER")
			PlayerManager.increase_stat("ENERGY", 10.0)
			feedback_label.text = "Comida comprada (+10 energía, sin hambre)"
		"comida_pack":
			PlayerManager.remove_effect("HUNGER")
			PlayerManager.increase_stat("ENERGY", 30.0)
			feedback_label.text = "Pack comprado (+30 energía, sin hambre)"
		"comida_casera":
			PlayerManager.remove_effect("HUNGER")
			PlayerManager.increase_stat("ENERGY", 20.0)
			PlayerManager.remove_effect("STRESS")
			feedback_label.text = "Comida casera (+20 energía, -estrés)"
		"jabon_c":
			NarrativeFlags.set_flag("soap_c")
			feedback_label.text = "Jabón C comprado (5 usos)"
		"jabon_b":
			NarrativeFlags.set_flag("soap_b")
			feedback_label.text = "Jabón B comprado (8 usos)"
		"jabon_a":
			NarrativeFlags.set_flag("soap_a")
			feedback_label.text = "Jabón A comprado (12 usos)"

func _on_close() -> void:
	market_closed.emit()
