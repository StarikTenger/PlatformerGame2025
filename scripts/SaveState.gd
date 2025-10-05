extends Node

var chosen : Array[String] = ["Fire", "Fire", "Wind", "Earth"]
var state : bool = false

func save_chosen(_chosen : Array[String]):
	chosen = _chosen

func get_chosen():
	return chosen

func set_restarted(_state: bool):
	state = _state

func get_restarted():
	return state
