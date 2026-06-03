extends Node

const MUSIC_TRACKS: Array[String] = [
	"res://assets/audio/music/lofi_01_prettyjohn1.mp3",
	"res://assets/audio/music/lofi_02_mirostar_beats.mp3",
	"res://assets/audio/music/lofi_03_mirostar_music.mp3",
	"res://assets/audio/music/lofi_04_pulsebox_smooth.mp3",
	"res://assets/audio/music/lofi_05_pulsebox_production.mp3"
]

const CLICK_SFX_PATH: String = "res://assets/audio/sfx/ui_click.wav"
const HOVER_SFX_PATH: String = "res://assets/audio/sfx/ui_hover.wav"
const SUCCESS_SFX_PATH: String = "res://assets/audio/sfx/success.wav"
const ERROR_SFX_PATH: String = "res://assets/audio/sfx/error.wav"
const BACK_SFX_PATH: String = "res://assets/audio/sfx/back.wav"
const RUN_SFX_PATH: String = "res://assets/audio/sfx/run.wav"
const STEP_SFX_PATH: String = "res://assets/audio/sfx/step.wav"
const COLLECT_SFX_PATH: String = "res://assets/audio/sfx/collect.wav"
const GATE_SFX_PATH: String = "res://assets/audio/sfx/gate.wav"
const TERMINAL_SFX_PATH: String = "res://assets/audio/sfx/terminal.wav"
const ATTACK_SFX_PATH: String = "res://assets/audio/sfx/attack.wav"
const VICTORY_SFX_PATH: String = "res://assets/audio/sfx/victory.wav"
const FAIL_SFX_PATH: String = "res://assets/audio/sfx/fail.wav"

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var hover_player: AudioStreamPlayer

var _last_scene_path: String = ""
var _current_music_path: String = ""
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)

	hover_player = AudioStreamPlayer.new()
	hover_player.name = "HoverPlayer"
	hover_player.bus = "Master"
	add_child(hover_player)

	get_tree().node_added.connect(_on_node_added)
	AppState.settings_changed.connect(_apply_settings)
	_apply_settings()
	call_deferred("_sync_scene_audio")
	call_deferred("_ensure_music_playing")

func _process(_delta: float) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		var scene_path: String = str(current_scene.scene_file_path)
		if scene_path != _last_scene_path:
			_last_scene_path = scene_path
			_register_buttons_recursive(current_scene)

	if AppState.music_enabled and music_player != null and not music_player.playing:
		_play_random_music_track()

func _sync_scene_audio() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		_last_scene_path = str(current_scene.scene_file_path)
		_register_buttons_recursive(current_scene)
	_ensure_music_playing()

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_register_button(node as BaseButton)
	for child in node.get_children():
		if child is BaseButton:
			_register_button(child as BaseButton)

func _register_buttons_recursive(node: Node) -> void:
	if node is BaseButton:
		_register_button(node as BaseButton)
	for child in node.get_children():
		_register_buttons_recursive(child)

func _register_button(button: BaseButton) -> void:
	if button == null:
		return
	if not button.pressed.is_connected(_on_any_button_pressed):
		button.pressed.connect(_on_any_button_pressed)
	if not button.mouse_entered.is_connected(_on_any_button_hovered):
		button.mouse_entered.connect(_on_any_button_hovered)

func _on_any_button_pressed() -> void:
	play_click()

func _on_any_button_hovered() -> void:
	play_hover()

func _apply_settings() -> void:
	_update_player_volumes()
	if AppState.music_enabled:
		_ensure_music_playing()
	else:
		music_player.stop()

func _update_player_volumes() -> void:
	if music_player != null:
		music_player.volume_db = _linear_to_db(AppState.music_volume, -32.0, -2.0)
	if sfx_player != null:
		sfx_player.volume_db = _linear_to_db(AppState.sound_volume, -34.0, -10.0)
	if hover_player != null:
		hover_player.volume_db = _linear_to_db(AppState.sound_volume, -40.0, -18.0)

func _linear_to_db(value: float, min_db: float, max_db: float) -> float:
	var safe_value: float = clampf(value, 0.0, 1.0)
	if safe_value <= 0.001:
		return -80.0
	return lerpf(min_db, max_db, safe_value)

func _ensure_music_playing() -> void:
	if not AppState.music_enabled:
		return
	if music_player == null:
		return
	if not music_player.playing:
		_play_random_music_track()

func play_music_for_scene(_scene_path: String = "") -> void:
	_ensure_music_playing()

func _play_random_music_track() -> void:
	if not AppState.music_enabled:
		return
	if MUSIC_TRACKS.is_empty():
		push_warning("AudioManager: список музыки пуст.")
		return

	var next_path: String = _pick_random_track_path()
	var stream: AudioStream = load(next_path) as AudioStream
	if stream == null:
		push_warning("AudioManager: не удалось загрузить музыку: " + next_path)
		return

	_current_music_path = next_path
	music_player.stream = stream
	_update_player_volumes()
	music_player.play()

func _pick_random_track_path() -> String:
	if MUSIC_TRACKS.size() == 1:
		return MUSIC_TRACKS[0]
	var next_path: String = _current_music_path
	var attempts: int = 0
	while next_path == _current_music_path and attempts < 12:
		var index: int = _rng.randi_range(0, MUSIC_TRACKS.size() - 1)
		next_path = MUSIC_TRACKS[index]
		attempts += 1
	return next_path

func _on_music_finished() -> void:
	if AppState.music_enabled:
		_play_random_music_track()

func play_click() -> void:
	_play_sfx(CLICK_SFX_PATH, sfx_player)

func play_hover() -> void:
	_play_sfx(HOVER_SFX_PATH, hover_player)

func play_success() -> void:
	_play_sfx(SUCCESS_SFX_PATH, sfx_player)

func play_error() -> void:
	_play_sfx(ERROR_SFX_PATH, sfx_player)

func play_back() -> void:
	_play_sfx(BACK_SFX_PATH, sfx_player)

func play_run() -> void:
	_play_sfx(RUN_SFX_PATH, sfx_player)

func play_step() -> void:
	_play_sfx(STEP_SFX_PATH, sfx_player)

func play_collect() -> void:
	_play_sfx(COLLECT_SFX_PATH, sfx_player)

func play_gate() -> void:
	_play_sfx(GATE_SFX_PATH, sfx_player)

func play_terminal() -> void:
	_play_sfx(TERMINAL_SFX_PATH, sfx_player)

func play_attack() -> void:
	_play_sfx(ATTACK_SFX_PATH, sfx_player)

func play_victory() -> void:
	_play_sfx(VICTORY_SFX_PATH, sfx_player)

func play_fail() -> void:
	_play_sfx(FAIL_SFX_PATH, sfx_player)

func _play_sfx(path: String, player: AudioStreamPlayer) -> void:
	if not AppState.sound_enabled:
		return
	if player == null:
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("AudioManager: не удалось загрузить звук: " + path)
		return
	_update_player_volumes()
	player.stream = stream
	player.play()
