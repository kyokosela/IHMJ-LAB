extends Resource
class_name MailEvent

## Base class for email minigame events
## Subclasses should call check_stress_failure() before registering success

@warning_ignore("unused_parameter")
func execute(container: Control, data: MailEntry) -> void: pass

## Check if STRESS causes a work task action to fail
## Returns true if STRESS causes failure, false if action proceeds normally
## Call this BEFORE confirming a correct answer
func check_stress_failure() -> bool:
	return not PlayerManager.roll_work_task_success()

## Get the current stress failure chance (for UI feedback)
func get_stress_failure_chance() -> float:
	return PlayerManager.get_work_failure_chance()
