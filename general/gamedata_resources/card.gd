class_name Card
extends Resource

@export var type: int
@export var revealed: bool


@warning_ignore("shadowed_variable")
func _init(type: int = 0, revealed: bool = false):
	self.type = type
	self.revealed = revealed

@warning_ignore("shadowed_variable") # buggy warning. shouldn't be there because it's a static func
static func fromColorAndValue(color: int, value: int, revealed: bool = false) -> Card:
	return Card.new(color * 13 + value - 1, revealed)

## 0 = spades
## 1 = hearts
## 2 = clubs
## 3 = diamonds
func get_color() -> int:
	@warning_ignore("integer_division")
	return type / 13

## beginning from 1 (ace) to 13 (king)
func get_value() -> int:
	return 1 + (type % 13)

## beginning from 2 (ace) to 10 and A, J, Q and K
func get_value_str() -> String:
	#if not revealed:
		#return "?"
	
	var value = get_value()
	if value >= 2 and value <= 10:
		return str(value)
	elif value == 11:
		return "J"
	elif value == 12:
		return "Q"
	elif value == 13:
		return "K"
	else:
		return "A"
