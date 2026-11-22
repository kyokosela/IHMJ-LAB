extends Control

signal arcade_closed

@onready var balance_label: Label = $Container/BalanceLabel
@onready var result_label: Label = $Container/ResultLabel
@onready var bet_10: Button = $Container/Bets/Bet10
@onready var bet_25: Button = $Container/Bets/Bet25
@onready var bet_50: Button = $Container/Bets/Bet50
@onready var bet_100: Button = $Container/Bets/Bet100
@onready var close_button: Button = $Container/CloseButton

func _ready() -> void:
	_update_balance()
	result_label.text = "¡Prueba tu suerte!"
	bet_10.pressed.connect(_on_bet.bind(10))
	bet_25.pressed.connect(_on_bet.bind(25))
	bet_50.pressed.connect(_on_bet.bind(50))
	bet_100.pressed.connect(_on_bet.bind(100))
	close_button.pressed.connect(_on_close)
	_update_buttons()

func _update_balance() -> void:
	balance_label.text = "Savia: S/%d" % EconomyManager.get_balance()

func _update_buttons() -> void:
	var balance := EconomyManager.get_balance()
	bet_10.disabled = balance < 10
	bet_25.disabled = balance < 25
	bet_50.disabled = balance < 50
	bet_100.disabled = balance < 100

func _on_bet(amount: int) -> void:
	if not EconomyManager.can_afford(amount):
		result_label.text = "No tienes suficiente"
		result_label.modulate = Color.RED
		return

	var won := randf() >= 0.5
	if won:
		EconomyManager.add_money(amount, "ARCADE_WIN")
		result_label.text = "¡GANASTE! +S/%d" % amount
		result_label.modulate = Color.GREEN
		PlayerManager.register_gamble(true)
	else:
		EconomyManager.spend_money(amount, "ARCADE_LOSS")
		result_label.text = "Perdiste... -S/%d" % amount
		result_label.modulate = Color.RED
		PlayerManager.register_gamble(false)

	_update_balance()
	_update_buttons()

func _on_close() -> void:
	arcade_closed.emit()
