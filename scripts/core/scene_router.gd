extends Node

const MAIN_MENU: String = "res://scenes/MainMenu.tscn"
const LEVEL_MAP: String = "res://scenes/LevelMap.tscn"
const LESSON: String = "res://scenes/LessonScene.tscn"
const TASK: String = "res://scenes/TaskScene.tscn"
const RESULT: String = "res://scenes/ResultScene.tscn"
const SETTINGS: String = "res://scenes/SettingsScene.tscn"
const FINAL: String = "res://scenes/FinalScene.tscn"
const CODEX: String = "res://scenes/CodexScene.tscn"
const COMMAND_GAME: String = "res://scenes/CommandGameScene.tscn"

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)

func go_to_level_map() -> void:
	get_tree().change_scene_to_file(LEVEL_MAP)

func go_to_lesson() -> void:
	get_tree().change_scene_to_file(LESSON)

func go_to_task() -> void:
	get_tree().change_scene_to_file(TASK)

func go_to_result() -> void:
	get_tree().change_scene_to_file(RESULT)

func go_to_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS)

func go_to_final() -> void:
	get_tree().change_scene_to_file(FINAL)

func go_to_codex() -> void:
	get_tree().change_scene_to_file(CODEX)

func go_to_code_game() -> void:
	get_tree().change_scene_to_file(COMMAND_GAME)
