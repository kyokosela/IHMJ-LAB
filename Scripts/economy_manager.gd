extends Node

signal money_changed(new_amount: int, delta: int)
signal transaction_logged(transaction: Dictionary)
signal salary_paid(amount: int, details: Dictionary)
signal rent_due()
signal rent_paid()
signal rent_overdue(warnings: int)
signal insufficient_funds(required: int, available: int)

const STARTING_MONEY: int = 350
const DAILY_SALARY: int = 200
const RENT_AMOUNT: int = 230
const BUS_COST: int = 10

var money: int = STARTING_MONEY:
	set(value):
		var old_value := money
		money = max(0, value)
		if money != old_value:
			money_changed.emit(money, money - old_value)

var transactions: Array[Dictionary] = []
var daily_earnings: Array[int] = [0, 0, 0, 0, 0, 0, 0]
var rent_paid_this_week: bool = false
var rent_warnings: int = 0

func _ready() -> void:
	TimeManager.week_changed.connect(_on_week_changed)

func add_money(amount: int, reason: String) -> void:
	_log_transaction(amount, reason)
	money += amount

func spend_money(amount: int, reason: String) -> bool:
	if money < amount:
		insufficient_funds.emit(amount, money)
		return false
	_log_transaction(-amount, reason)
	money -= amount
	return true

func can_afford(amount: int) -> bool:
	return money >= amount

func get_balance() -> int:
	return money

func record_daily_earnings(day_index: int, amount: int) -> void:
	if day_index >= 0 and day_index < 7:
		daily_earnings[day_index] = amount

func calculate_weekly_gross() -> int:
	var total: int = 0
	for i in range(5):
		total += daily_earnings[i]
	return total

func pay_weekly_salary(deductions: int = 0) -> void:
	var gross: int = calculate_weekly_gross()
	var net: int = max(0, gross - deductions)
	var details := {
		"gross": gross,
		"deductions": deductions,
		"net": net,
		"days_worked": _count_days_worked()
	}

	if net > 0:
		add_money(net, "SALARY_WEEKLY")
	salary_paid.emit(net, details)

func check_rent_due() -> void:
	if not rent_paid_this_week:
		rent_due.emit()

func pay_rent() -> bool:
	if spend_money(RENT_AMOUNT, "RENT"):
		rent_paid_this_week = true
		rent_warnings = 0
		rent_paid.emit()
		return true

	rent_warnings += 1
	rent_overdue.emit(rent_warnings)
	return false

func is_rent_paid() -> bool:
	return rent_paid_this_week

func get_rent_warnings() -> int:
	return rent_warnings

func pay_bus() -> bool:
	return spend_money(BUS_COST, "BUS_TRANSPORT")

func can_afford_bus() -> bool:
	return can_afford(BUS_COST)

func get_save_data() -> Dictionary:
	return {
		"money": money,
		"transactions": transactions.duplicate(true),
		"daily_earnings": daily_earnings.duplicate(),
		"rent_paid_this_week": rent_paid_this_week,
		"rent_warnings": rent_warnings
	}

func load_save_data(data: Dictionary) -> void:
	money = data.get("money", STARTING_MONEY)
	transactions.clear()
	var saved_transactions: Array = data.get("transactions", [])
	for item in saved_transactions:
		if item is Dictionary:
			transactions.append(item)
	daily_earnings = [0, 0, 0, 0, 0, 0, 0]
	var saved_daily_earnings: Array = data.get("daily_earnings", [])
	for i in range(min(saved_daily_earnings.size(), daily_earnings.size())):
		daily_earnings[i] = int(saved_daily_earnings[i])
	rent_paid_this_week = data.get("rent_paid_this_week", false)
	rent_warnings = data.get("rent_warnings", 0)

func _count_days_worked() -> int:
	var count: int = 0
	for i in range(5):
		if daily_earnings[i] > 0:
			count += 1
	return count

func _log_transaction(amount: int, reason: String) -> void:
	var entry := {
		"amount": amount,
		"reason": reason,
		"day": TimeManager.day,
		"week_day": TimeManager.week_day,
		"time": TimeManager.get_current_time(),
		"balance_after": money + amount
	}
	transactions.append(entry)
	transaction_logged.emit(entry)

func _on_week_changed(_week: int) -> void:
	rent_paid_this_week = false
	daily_earnings = [0, 0, 0, 0, 0, 0, 0]
