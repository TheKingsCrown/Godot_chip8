extends Node2D

var action_dictionary = {}
var last_key_pressed: int = -1

func _ready():
	var actions = InputMap.get_actions()
	actions = actions.slice(-16)
	
	var i = 0
	for action in actions:
		action_dictionary[action] = i
		i += 1

func _input(event):
	var event_string: String = event.as_text()
	event_string = event_string.to_lower()
	if action_dictionary.has(event_string):
		last_key_pressed = action_dictionary[event_string]
	else:
		last_key_pressed = -1
	

func _process(delta):
	pass
