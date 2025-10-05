extends Node2D

@export var char1: String
@export var char2: String
@export var char3: String
@export var char4: String

@export var can_change: bool = true

func get_roster():
	var ans : Array[String]
	ans.push_back(char1)
	ans.push_back(char2)
	ans.push_back(char3)
	ans.push_back(char4)
	return ans

func is_can_change():
	return can_change
