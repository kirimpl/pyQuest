extends Node

var selected_level: int = 1
var score: int = 0
var mistakes: int = 0
var completed_levels: Array[int] = []
var last_answer_correct: bool = false
var last_explanation: String = ""

func reset_game() -> void:
	selected_level = 1
	score = 0
	mistakes = 0
	completed_levels.clear()
	last_answer_correct = false
	last_explanation = ""

func add_score(value: int) -> void:
	score += value

func add_mistake() -> void:
	mistakes += 1

func complete_level(level: int) -> void:
	if not completed_levels.has(level):
		completed_levels.append(level)
		completed_levels.sort()

func is_level_completed(level: int) -> bool:
	return completed_levels.has(level)
