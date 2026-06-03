extends Control

@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var new_game_button: Button = %NewGameButton
@onready var level_map_button: Button = %LevelMapButton
@onready var codex_button: Button = %CodexButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	level_map_button.pressed.connect(_on_level_map_pressed)
	codex_button.pressed.connect(_on_codex_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	_update_status()
	call_deferred("_start_menu_music")

func _start_menu_music() -> void:
	AudioManager.play_music_for_scene("res://scenes/MainMenu.tscn")

func _update_status() -> void:
	continue_button.disabled = not SaveManager.has_save()
	status_label.text = "PyQuest: Code Adventure\n%s\n%s\nОчки: %d   Ошибки: %d   Открыт сектор: %d   Запусков кода: %d" % [
		CodeWorldService.get_campaign_title(),
		CodeWorldService.get_campaign_progress_text(),
		AppState.score,
		AppState.mistakes,
		AppState.max_unlocked_level,
		AppState.get_total_code_attempts()
	]

func _on_new_game_pressed() -> void:
	AppState.start_new_game()
	SaveManager.save_game()
	SceneRouter.go_to_level_map()

func _on_continue_pressed() -> void:
	SaveManager.load_game()
	SceneRouter.go_to_code_game()

func _on_level_map_pressed() -> void:
	SceneRouter.go_to_level_map()

func _on_codex_pressed() -> void:
	SceneRouter.go_to_codex()

func _on_settings_pressed() -> void:
	SceneRouter.go_to_settings()

func _on_exit_pressed() -> void:
	get_tree().quit()
