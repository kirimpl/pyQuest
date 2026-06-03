extends Control

@onready var music_button: Button = %MusicButton
@onready var sound_button: Button = %SoundButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sound_slider: HSlider = %SoundSlider
@onready var music_volume_label: Label = %MusicVolumeLabel
@onready var sound_volume_label: Label = %SoundVolumeLabel
@onready var reset_button: Button = %ResetButton
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	music_button.pressed.connect(_on_music_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sound_slider.value_changed.connect(_on_sound_volume_changed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_update_view()

func _update_view() -> void:
	music_button.text = "Музыка: %s" % ["включена" if AppState.music_enabled else "выключена"]
	sound_button.text = "Звуки: %s" % ["включены" if AppState.sound_enabled else "выключены"]
	music_slider.set_value_no_signal(AppState.music_volume * 100.0)
	sound_slider.set_value_no_signal(AppState.sound_volume * 100.0)
	music_volume_label.text = "Громкость музыки: %d%%" % int(round(AppState.music_volume * 100.0))
	sound_volume_label.text = "Громкость звуков: %d%%" % int(round(AppState.sound_volume * 100.0))
	status_label.text = "Прогресс кампании: %d секторов, %d/%d узлов, %d очков, %d ошибок, энергия %d/%d, тревога %d%%" % [
		AppState.completed_levels.size(),
		ContentRepository.get_completed_task_count(),
		ContentRepository.get_total_task_count(),
		AppState.score,
		AppState.mistakes,
		AppState.player_energy,
		AppState.max_player_energy,
		AppState.system_alarm
	]

func _on_music_pressed() -> void:
	AppState.set_music_enabled(not AppState.music_enabled)
	SaveManager.save_game()
	_update_view()

func _on_sound_pressed() -> void:
	AppState.set_sound_enabled(not AppState.sound_enabled)
	SaveManager.save_game()
	_update_view()

func _on_music_volume_changed(value: float) -> void:
	AppState.set_music_volume(value / 100.0)
	SaveManager.save_game()
	_update_view()

func _on_sound_volume_changed(value: float) -> void:
	AppState.set_sound_volume(value / 100.0)
	SaveManager.save_game()
	_update_view()

func _on_reset_pressed() -> void:
	SaveManager.delete_save()
	AppState.start_new_game()
	SaveManager.save_game()
	_update_view()

func _on_back_pressed() -> void:
	SceneRouter.go_to_main_menu()
