extends Control

const REPLAY_FRAME_TIME: float = 0.14

@onready var root_margin: MarginContainer = $RootMargin
@onready var root_layout: HBoxContainer = $RootMargin/RootLayout
@onready var left_panel: PanelContainer = $RootMargin/RootLayout/LeftPanel
@onready var right_panel: PanelContainer = $RootMargin/RootLayout/RightPanel
@onready var map_panel: PanelContainer = $RootMargin/RootLayout/LeftPanel/LeftMargin/LeftBox/MapPanel
@onready var briefing_panel: PanelContainer = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/BriefingPanel
@onready var command_panel: PanelContainer = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/CommandPanel
@onready var output_panel: PanelContainer = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/OutputPanel

@onready var title_label: Label = $RootMargin/RootLayout/LeftPanel/LeftMargin/LeftBox/HeaderBox/TitleLabel
@onready var subtitle_label: Label = $RootMargin/RootLayout/LeftPanel/LeftMargin/LeftBox/HeaderBox/SubtitleLabel
@onready var progress_label: Label = $RootMargin/RootLayout/LeftPanel/LeftMargin/LeftBox/HeaderBox/ProgressLabel
@onready var map_grid: GridContainer = $RootMargin/RootLayout/LeftPanel/LeftMargin/LeftBox/MapPanel/MapMargin/MapGrid
@onready var legend_label: Label = $RootMargin/RootLayout/LeftPanel/LeftMargin/LeftBox/LegendLabel
@onready var log_label: Label = $RootMargin/RootLayout/LeftPanel/LeftMargin/LeftBox/LogPanel/LogScroll/LogLabel

@onready var briefing_label: Label = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/BriefingPanel/BriefingMargin/BriefingLabel
@onready var command_reference_label: Label = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/CommandPanel/CommandMargin/CommandReferenceLabel
@onready var code_editor: TextEdit = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/CodeEditor
@onready var run_button: Button = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/ButtonRow/RunButton
@onready var reset_button: Button = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/ButtonRow/ResetButton
@onready var hint_button: Button = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/ButtonRow/SolutionButton
@onready var next_button: Button = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/ButtonRow/NextButton
@onready var menu_button: Button = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/ButtonRow/MenuButton
@onready var button_row: HBoxContainer = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/ButtonRow
@onready var output_label: Label = $RootMargin/RootLayout/RightPanel/RightMargin/RightBox/OutputPanel/OutputScroll/OutputLabel

var current_level: Dictionary = {}
var last_result: Dictionary = {}
var replay_timer: Timer
var replay_frames: Array = []
var replay_index: int = 0
var used_hint_current: bool = false
var level_completed_current_run: bool = false
var hint_stage: int = 0

var help_button: Button = null
var current_tile_size: int = 42
var tile_textures: Dictionary = {}
var tutorial_layer: CanvasLayer = null
var tutorial_step_index: int = 0
var tutorial_title_label: Label = null
var tutorial_body_label: Label = null
var tutorial_back_button: Button = null
var tutorial_next_button: Button = null
var tutorial_skip_button: Button = null

var objective_label: Label = null
var status_label: Label = null
var codex_button: Button = null
var speed_button: Button = null
var utility_button_row: HBoxContainer = null
var codex_layer: CanvasLayer = null
var result_layer: CanvasLayer = null
var pending_result_overlay: Dictionary = {}
var replay_speed_index: int = 1
var cell_nodes: Dictionary = {}
var cell_icon_nodes: Dictionary = {}
var scene_intro_played: bool = false

const REPLAY_SPEEDS: Array = [0.30, 0.14, 0.07]
const REPLAY_SPEED_NAMES: Array = ["0.5x", "1x", "2x"]

const TILE_TEXTURE_PATHS: Dictionary = {
	".": "res://assets/code_adventure/tiles/floor.png",
	"#": "res://assets/code_adventure/tiles/wall.png",
	"P": "res://assets/code_adventure/tiles/hero.png",
	"X": "res://assets/code_adventure/tiles/portal.png",
	"G": "res://assets/code_adventure/tiles/gem.png",
	"K": "res://assets/code_adventure/tiles/key.png",
	"D": "res://assets/code_adventure/tiles/door.png",
	"E": "res://assets/code_adventure/tiles/bug.png",
	"S": "res://assets/code_adventure/tiles/terminal.png",
	"~": "res://assets/code_adventure/tiles/hazard.png",
	"*": "res://assets/code_adventure/tiles/trail.png"
}

const TUTORIAL_STEPS: Array[Dictionary] = [
	{
		"title": "Вход в сектор",
		"body": "Перед тобой повреждённый сектор PyQuest. Слева находится карта узла, справа - терминал управления. Пиши команды в редакторе, чтобы провести героя через препятствия и восстановить систему."
	},
	{
		"title": "Управление героем",
		"body": "Команды выполняются по порядку. hero.move_right() ведёт героя вправо, hero.collect() подбирает кристалл или ключ, hero.open_gate() открывает шлюз, а hero.attack() уничтожает баг рядом."
	},
	{
		"title": "Задача сектора",
		"body": "У каждого сектора своя миссия: добраться до портала, собрать ресурсы, открыть путь, запустить терминал или зачистить узел от багов. Выполни все условия, чтобы сектор был восстановлен."
	},
	{
		"title": "RUN, сканер и звёзды",
		"body": "Нажми RUN или Ctrl+Enter, чтобы запустить программу. Герой выполнит команды шаг за шагом. Сканер поможет с направлением, а за точное и короткое решение ты получишь больше звёзд."
	},
	{
		"title": "Готов к запуску?",
		"body": "Начни с пробного запуска, посмотри маршрут героя и доведи программу до идеального прохождения. Чем чище алгоритм, тем быстрее оживёт сектор."
	}
]

func _ready() -> void:
	_apply_compact_layout()
	var resize_callable: Callable = Callable(self, "_apply_compact_layout")
	if get_viewport() != null and not get_viewport().size_changed.is_connected(resize_callable):
		get_viewport().size_changed.connect(resize_callable)
	_load_tile_textures()
	_setup_help_button()
	_setup_extra_buttons()
	_setup_status_panels()
	_setup_visual_polish()
	_apply_compact_layout()
	run_button.pressed.connect(_on_run_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	set_process_unhandled_input(true)

	replay_timer = Timer.new()
	replay_timer.wait_time = float(REPLAY_SPEEDS[replay_speed_index])
	replay_timer.one_shot = false
	replay_timer.timeout.connect(_on_replay_timeout)
	add_child(replay_timer)

	_load_level()
	call_deferred("_start_music")
	if not AppState.code_tutorial_completed:
		call_deferred("_show_tutorial", 0, false)


func _apply_compact_layout() -> void:
	var viewport_width: float = get_viewport_rect().size.x
	var small: bool = viewport_width < 1150.0
	var very_small: bool = viewport_width < 980.0

	var outer_margin: int = 8 if small else 12
	root_margin.add_theme_constant_override("margin_left", outer_margin)
	root_margin.add_theme_constant_override("margin_top", outer_margin)
	root_margin.add_theme_constant_override("margin_right", outer_margin)
	root_margin.add_theme_constant_override("margin_bottom", outer_margin)
	root_layout.add_theme_constant_override("separation", 10 if small else 14)

	var left_width: int = 520
	var right_width: int = 560
	if small:
		left_width = 460
		right_width = 500
	if very_small:
		left_width = 390
		right_width = 430
	left_panel.custom_minimum_size = Vector2(left_width, 0)
	right_panel.custom_minimum_size = Vector2(right_width, 0)

	# Длинные справочные блоки не должны выталкивать редактор за экран.
	briefing_panel.custom_minimum_size = Vector2(0, 0)
	command_panel.custom_minimum_size = Vector2(0, 0)
	output_panel.custom_minimum_size = Vector2(0, 82 if small else 92)
	code_editor.custom_minimum_size = Vector2(0, 210 if small else 235)

	title_label.add_theme_font_size_override("font_size", 22 if small else 24)
	subtitle_label.add_theme_font_size_override("font_size", 12 if small else 13)
	progress_label.add_theme_font_size_override("font_size", 12 if small else 13)
	briefing_label.add_theme_font_size_override("font_size", 12 if small else 13)
	command_reference_label.add_theme_font_size_override("font_size", 12 if small else 13)
	legend_label.add_theme_font_size_override("font_size", 12 if small else 13)
	log_label.add_theme_font_size_override("font_size", 12 if small else 13)
	output_label.add_theme_font_size_override("font_size", 13 if small else 14)

	for button in [run_button, reset_button, hint_button, next_button, menu_button]:
		if button != null:
			button.custom_minimum_size.y = 36 if small else 40
			button.add_theme_font_size_override("font_size", 12 if small else 13)

	if run_button != null:
		run_button.custom_minimum_size.x = 104 if small else 118
		run_button.add_theme_font_size_override("font_size", 14 if small else 15)

	for button in [help_button, codex_button, speed_button]:
		if button != null:
			button.custom_minimum_size.y = 32 if small else 34
			button.add_theme_font_size_override("font_size", 12)

	if not current_level.is_empty():
		_draw_grid(CodeWorldService.get_initial_display_grid(AppState.selected_level))


func _setup_visual_polish() -> void:
	left_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.030, 0.042, 0.070, 0.96), Color(0.18, 0.35, 0.62, 0.92)))
	right_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.032, 0.055, 0.97), Color(0.22, 0.42, 0.72, 0.90)))
	map_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.018, 0.026, 0.040, 0.98), Color(0.25, 0.48, 0.78, 0.95)))
	briefing_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.050, 0.070, 0.105, 0.96), Color(0.30, 0.52, 0.84, 0.90)))
	command_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.050, 0.078, 0.96), Color(0.22, 0.40, 0.66, 0.88)))
	output_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.020, 0.030, 0.048, 0.98), Color(0.20, 0.34, 0.54, 0.88)))
	output_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	code_editor.highlight_current_line = true
	code_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	code_editor.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0, 1.0))
	code_editor.add_theme_color_override("current_line_color", Color(0.08, 0.13, 0.20, 1.0))
	code_editor.add_theme_color_override("selection_color", Color(0.20, 0.42, 0.78, 0.75))

	_apply_button_style(run_button, Color(0.10, 0.50, 0.32, 1.0), Color(0.22, 0.82, 0.52, 1.0), Color(0.03, 0.22, 0.14, 1.0))
	_apply_button_style(next_button, Color(0.18, 0.34, 0.64, 1.0), Color(0.38, 0.64, 1.0, 1.0), Color(0.07, 0.16, 0.34, 1.0))
	for button in [reset_button, hint_button, menu_button, help_button, codex_button, speed_button]:
		_apply_button_style(button, Color(0.13, 0.18, 0.30, 0.98), Color(0.35, 0.52, 0.82, 0.90), Color(0.06, 0.09, 0.16, 1.0))

func _apply_button_style(button: Button, normal_color: Color, border_color: Color, pressed_color: Color) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _make_button_style(normal_color, border_color))
	button.add_theme_stylebox_override("hover", _make_button_style(normal_color.lightened(0.12), border_color.lightened(0.10)))
	button.add_theme_stylebox_override("pressed", _make_button_style(pressed_color, border_color.lightened(0.18)))
	button.add_theme_stylebox_override("focus", _make_button_style(normal_color.lightened(0.08), Color(0.70, 0.88, 1.0, 1.0), 2))
	button.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))

func _make_button_style(bg: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _load_tile_textures() -> void:
	tile_textures.clear()
	for key in TILE_TEXTURE_PATHS.keys():
		var path: String = str(TILE_TEXTURE_PATHS[key])
		var texture: Resource = load(path)
		if texture != null:
			tile_textures[key] = texture

func _get_utility_row() -> HBoxContainer:
	if utility_button_row != null:
		return utility_button_row
	var right_box: VBoxContainer = button_row.get_parent() as VBoxContainer
	if right_box == null:
		utility_button_row = button_row
		return utility_button_row
	utility_button_row = right_box.get_node_or_null("UtilityButtonRow") as HBoxContainer
	if utility_button_row == null:
		utility_button_row = HBoxContainer.new()
		utility_button_row.name = "UtilityButtonRow"
		utility_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
		utility_button_row.add_theme_constant_override("separation", 8)
		right_box.add_child(utility_button_row)
		right_box.move_child(utility_button_row, mini(right_box.get_child_count() - 1, button_row.get_index() + 1))
	return utility_button_row

func _setup_help_button() -> void:
	var target_row: HBoxContainer = _get_utility_row()
	help_button = target_row.get_node_or_null("HelpButton") as Button
	if help_button == null:
		help_button = Button.new()
		help_button.name = "HelpButton"
		help_button.text = "Помощь"
		help_button.custom_minimum_size = Vector2(92, 36)
		help_button.add_theme_font_size_override("font_size", 12)
		target_row.add_child(help_button)
	help_button.pressed.connect(_on_help_pressed)

func _setup_extra_buttons() -> void:
	var target_row: HBoxContainer = _get_utility_row()
	codex_button = target_row.get_node_or_null("CodexButton") as Button
	if codex_button == null:
		codex_button = Button.new()
		codex_button.name = "CodexButton"
		codex_button.text = "Команды"
		codex_button.custom_minimum_size = Vector2(94, 36)
		codex_button.add_theme_font_size_override("font_size", 12)
		target_row.add_child(codex_button)
	codex_button.pressed.connect(_on_codex_pressed)

	speed_button = target_row.get_node_or_null("SpeedButton") as Button
	if speed_button == null:
		speed_button = Button.new()
		speed_button.name = "SpeedButton"
		speed_button.custom_minimum_size = Vector2(104, 36)
		speed_button.add_theme_font_size_override("font_size", 12)
		target_row.add_child(speed_button)
	speed_button.pressed.connect(_on_speed_pressed)
	_update_speed_button_text()

func _setup_status_panels() -> void:
	var left_box: VBoxContainer = legend_label.get_parent() as VBoxContainer
	if left_box == null:
		return
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "SectorHudPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.055, 0.09, 0.88), Color(0.18, 0.35, 0.58, 1.0)))
	left_box.add_child(panel)
	left_box.move_child(panel, mini(left_box.get_child_count() - 1, legend_label.get_index() + 1))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 13)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(objective_label)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)

func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style

func _start_music() -> void:
	AudioManager.play_music_for_scene("res://scenes/CommandGameScene.tscn")

func _load_level() -> void:
	_stop_replay()
	var level_count: int = max(1, CodeWorldService.get_level_count())
	AppState.selected_level = clampi(AppState.selected_level, 1, level_count)
	current_level = CodeWorldService.get_level(AppState.selected_level)
	if current_level.is_empty():
		output_label.text = "Уровень не найден. Проверь data/code_adventure_levels.json."
		return

	used_hint_current = false
	hint_stage = 0
	level_completed_current_run = AppState.is_level_completed(AppState.selected_level)
	title_label.text = str(current_level.get("title", "Сектор"))
	subtitle_label.text = "%s · %s · сложность: %s" % [CodeWorldService.get_level_chapter(AppState.selected_level), str(current_level.get("mechanic", "команды героя")), CodeWorldService.get_level_difficulty(AppState.selected_level)]
	legend_label.text = _default_legend()
	briefing_label.text = _build_compact_briefing_text()
	command_reference_label.text = _default_command_reference()
	code_editor.text = AppState.get_code_for_level(AppState.selected_level, CodeWorldService.get_default_code(AppState.selected_level))
	output_label.text = _build_idle_output()
	log_label.text = "Терминал готов. Составь программу и запусти героя в сектор."
	_refresh_sector_hud({})
	run_button.disabled = false
	hint_button.disabled = false
	hint_button.text = "Сканер"
	reset_button.disabled = false
	next_button.disabled = not level_completed_current_run
	next_button.text = "Следующий сектор" if AppState.selected_level < level_count else "Финал"
	menu_button.text = "Меню"
	_draw_grid(CodeWorldService.get_initial_display_grid(AppState.selected_level))
	_update_progress_line()
	_animate_scene_entry()
	_play_idle_map_effects()

func _build_compact_briefing_text() -> String:
	var requirements: String = _requirements_to_text(current_level.get("requirements", {}))
	return "Цель: %s\nПобеда: %s\n3 звезды: около %d действий без подсказки. Подробности: F2 / Помощь." % [
		str(current_level.get("goal", "дойти до выхода X")),
		requirements,
		CodeWorldService.get_level_min_steps(AppState.selected_level)
	]


func _build_briefing_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(str(current_level.get("briefing", "")))
	lines.append("")
	lines.append("Цель: " + str(current_level.get("goal", "дойти до выхода X")))
	lines.append("Задачи сектора:\n" + CodeWorldService.get_level_objectives_text(AppState.selected_level))
	lines.append("Условия победы: " + _requirements_to_text(current_level.get("requirements", {})))
	lines.append("3 звезды: пройти примерно за %d действий без подсказки." % CodeWorldService.get_level_min_steps(AppState.selected_level))
	lines.append("Награда: " + CodeWorldService.get_level_reward_text(AppState.selected_level))
	lines.append("")
	lines.append("Собери рабочий алгоритм и проведи героя через сектор так, чтобы восстановить узел без лишних действий.")
	return "\n".join(lines)

func _build_idle_output() -> String:
	var best_text: String = AppState.get_code_level_best_text(AppState.selected_level)
	var last_report: String = AppState.get_code_level_last_report(AppState.selected_level)
	var report_text: String = "\n\nПоследний отчёт:\n" + last_report if not last_report.strip_edges().is_empty() else ""
	return "Статус сектора: %s\n%s\nМинимум для 3 звёзд: %d действий\n\n%s%s" % [
		"восстановлен" if AppState.is_level_completed(AppState.selected_level) else "не восстановлен",
		best_text,
		CodeWorldService.get_level_min_steps(AppState.selected_level),
		"RUN запускает программу героя. Сканер помогает с маршрутом, но за самостоятельное решение награда выше.",
		report_text
	]

func _requirements_to_text(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "дойти до выхода X"
	var requirements: Dictionary = value
	var parts: Array[String] = []
	if bool(requirements.get("reach_exit", true)):
		parts.append("дойти до X")
	if bool(requirements.get("collect_all", false)):
		parts.append("собрать все кристаллы и ключи")
	if bool(requirements.get("defeat_all", false)):
		parts.append("устранить всех багов")
	if bool(requirements.get("open_doors", false)):
		parts.append("открыть все шлюзы")
	if bool(requirements.get("activate_terminal", false)):
		parts.append("активировать терминал")
	return ", ".join(parts)

func _default_legend() -> String:
	return "P герой · X портал · G кристалл · K ключ · D шлюз · E баг · S терминал · # стена"

func _default_command_reference() -> String:
	return "Команды: hero.move_right(), move_left(), move_up(), move_down(), collect(), attack(), open_gate(), activate(). F2 - полный справочник."

func _draw_grid(rows: Array) -> void:
	cell_nodes.clear()
	cell_icon_nodes.clear()
	for child in map_grid.get_children():
		child.free()

	if rows.is_empty():
		return

	var width: int = str(rows[0]).length()
	map_grid.columns = width
	var available_width: int = int(left_panel.custom_minimum_size.x) - 64
	if map_panel.size.x > 80.0:
		available_width = int(map_panel.size.x) - 34
	var gap_total: int = max(0, width - 1) * 4
	current_tile_size = clampi(int((available_width - gap_total) / max(1, width)), 26, 56)
	var map_height: int = int(rows.size()) * (current_tile_size + 4) + 28
	map_panel.custom_minimum_size = Vector2(0, clampi(map_height, 150, 340))
	for y in range(rows.size()):
		var row: String = str(rows[y])
		for x in range(width):
			var cell: String = "."
			if x < row.length():
				cell = row.substr(x, 1)
			map_grid.add_child(_create_cell(cell, x, y))

func _create_cell(cell: String, x: int, y: int) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(current_tile_size, current_tile_size)
	panel.tooltip_text = _cell_tooltip(cell)
	panel.clip_contents = false
	panel.set_meta("grid_pos", Vector2i(x, y))

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = _cell_color(cell)
	style.border_color = _cell_border_color(cell)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)

	var tile_margin: MarginContainer = MarginContainer.new()
	tile_margin.add_theme_constant_override("margin_left", 2)
	tile_margin.add_theme_constant_override("margin_top", 2)
	tile_margin.add_theme_constant_override("margin_right", 2)
	tile_margin.add_theme_constant_override("margin_bottom", 2)
	panel.add_child(tile_margin)

	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(current_tile_size - 4, current_tile_size - 4)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = tile_textures.get(cell, tile_textures.get(".", null))
	texture_rect.pivot_offset = Vector2(current_tile_size - 4, current_tile_size - 4) * 0.5
	tile_margin.add_child(texture_rect)
	_apply_tile_effect(panel, texture_rect, cell)

	if texture_rect.texture == null:
		var label: Label = Label.new()
		label.custom_minimum_size = Vector2(current_tile_size - 4, current_tile_size - 4)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.text = _cell_text(cell)
		tile_margin.add_child(label)

	var pos_key: String = _grid_pos_key(Vector2i(x, y))
	cell_nodes[pos_key] = panel
	cell_icon_nodes[pos_key] = texture_rect
	return panel

func _apply_tile_effect(panel: Control, texture_rect: TextureRect, cell: String) -> void:
	match cell:
		"X":
			_add_pulse_effect(panel, texture_rect, Color(0.20, 1.00, 0.62, 0.34), 1.08, 0.75)
		"E":
			_add_pulse_effect(panel, texture_rect, Color(1.00, 0.18, 0.22, 0.28), 1.05, 0.42)
		"G":
			_add_pulse_effect(panel, texture_rect, Color(0.15, 0.85, 1.00, 0.24), 1.06, 0.55)
		"*":
			panel.modulate = Color(0.74, 0.88, 1.0, 0.72)

func _add_pulse_effect(panel: Control, texture_rect: TextureRect, glow_color: Color, target_scale: float, duration: float) -> void:
	var glow: ColorRect = ColorRect.new()
	glow.color = glow_color
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(glow)
	panel.move_child(glow, 0)
	texture_rect.pivot_offset = Vector2(current_tile_size - 4, current_tile_size - 4) * 0.5
	var tween: Tween = panel.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(texture_rect, "scale", Vector2(target_scale, target_scale), duration)
	tween.parallel().tween_property(glow, "color:a", glow_color.a * 0.25, duration)
	tween.tween_property(texture_rect, "scale", Vector2.ONE, duration)
	tween.parallel().tween_property(glow, "color:a", glow_color.a, duration)

func _grid_pos_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]

func _get_cell_control(pos: Vector2i) -> Control:
	var key: String = _grid_pos_key(pos)
	return cell_nodes.get(key, null) as Control

func _get_cell_icon(pos: Vector2i) -> TextureRect:
	var key: String = _grid_pos_key(pos)
	return cell_icon_nodes.get(key, null) as TextureRect

func _find_symbol_positions(rows: Array, symbol: String) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for y in range(rows.size()):
		var row: String = str(rows[y])
		for x in range(row.length()):
			if row.substr(x, 1) == symbol:
				positions.append(Vector2i(x, y))
	return positions

func _find_first_symbol(rows: Array, symbol: String) -> Vector2i:
	var positions: Array[Vector2i] = _find_symbol_positions(rows, symbol)
	return positions[0] if not positions.is_empty() else Vector2i(-999, -999)

func _positions_removed(previous_rows: Array, current_rows: Array, symbols: Array[String]) -> Array[Vector2i]:
	var removed: Array[Vector2i] = []
	for symbol in symbols:
		var previous_positions: Array[Vector2i] = _find_symbol_positions(previous_rows, symbol)
		var current_positions: Array[Vector2i] = _find_symbol_positions(current_rows, symbol)
		for pos in previous_positions:
			if not current_positions.has(pos):
				removed.append(pos)
	return removed

func _spawn_cell_flash(target: Control, color: Color, duration: float = 0.24, scale_target: float = 1.12) -> void:
	if target == null or not is_instance_valid(target):
		return
	var flash: ColorRect = ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.modulate.a = color.a
	target.add_child(flash)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_property(target, "scale", Vector2(scale_target, scale_target), duration * 0.45)
	tween.chain().tween_property(target, "scale", Vector2.ONE, duration * 0.55)
	tween.finished.connect(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)

func _bounce_texture(icon: TextureRect, strength: float = 1.16, duration: float = 0.18) -> void:
	if icon == null or not is_instance_valid(icon):
		return
	icon.scale = Vector2.ONE
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2(strength, strength), duration)
	tween.tween_property(icon, "scale", Vector2.ONE, duration)

func _spawn_floating_text(target: Control, text_value: String, color: Color) -> void:
	if target == null or not is_instance_valid(target):
		return
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.position = Vector2(0, -4)
	label.size = target.size
	target.add_child(label)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", -18.0, 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
	)

func _shake_control(target: Control, amplitude: float = 4.0, duration: float = 0.16) -> void:
	if target == null or not is_instance_valid(target):
		return
	var base_position: Vector2 = target.position
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "position:x", base_position.x - amplitude, duration * 0.25)
	tween.tween_property(target, "position:x", base_position.x + amplitude, duration * 0.25)
	tween.tween_property(target, "position:x", base_position.x, duration * 0.50)

func _flash_output_panel(success: bool) -> void:
	var color: Color = Color(0.18, 0.82, 0.48, 0.28) if success else Color(1.0, 0.24, 0.26, 0.26)
	_spawn_cell_flash(output_panel, color, 0.34, 1.0)
	_spawn_cell_flash(map_panel, color.darkened(0.15), 0.38, 1.0)

func _play_idle_map_effects() -> void:
	var hero_pos: Vector2i = _find_first_symbol(CodeWorldService.get_initial_display_grid(AppState.selected_level), "P")
	if hero_pos.x >= 0:
		var hero_icon: TextureRect = _get_cell_icon(hero_pos)
		_bounce_texture(hero_icon, 1.08, 0.14)

func _animate_scene_entry() -> void:
	if scene_intro_played:
		return
	scene_intro_played = true
	for node in [left_panel, right_panel]:
		if node == null:
			continue
		node.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(left_panel, "modulate:a", 1.0, 0.30)
	tween.tween_property(right_panel, "modulate:a", 1.0, 0.38)
	tween.tween_property(left_panel, "scale", Vector2(1.0, 1.0), 0.20)
	tween.tween_property(right_panel, "scale", Vector2(1.0, 1.0), 0.24)

func _animate_frame_transition(previous: Dictionary, current: Dictionary) -> void:
	var previous_grid: Array = previous.get("grid", [])
	var current_grid: Array = current.get("grid", [])
	var previous_hero: Vector2i = _find_first_symbol(previous_grid, "P")
	var current_hero: Vector2i = _find_first_symbol(current_grid, "P")
	if current_hero.x >= 0:
		var hero_cell: Control = _get_cell_control(current_hero)
		var hero_icon: TextureRect = _get_cell_icon(current_hero)
		if previous_hero != current_hero:
			_spawn_cell_flash(hero_cell, Color(0.35, 0.72, 1.0, 0.24), 0.18, 1.06)
			_bounce_texture(hero_icon, 1.14, 0.10)
			_spawn_floating_text(hero_cell, "→", Color(0.78, 0.90, 1.0, 0.96))
	var collected_delta: int = int(current.get("collected", 0)) - int(previous.get("collected", 0))
	if collected_delta > 0:
		for pos in _positions_removed(previous_grid, current_grid, ["G", "K"]):
			var collectible_cell: Control = _get_cell_control(pos)
			_spawn_cell_flash(collectible_cell, Color(0.18, 0.92, 1.0, 0.32), 0.28, 1.10)
			_spawn_floating_text(collectible_cell, "+1", Color(0.84, 0.98, 1.0, 1.0))
	var defeated_delta: int = int(current.get("defeated", 0)) - int(previous.get("defeated", 0))
	if defeated_delta > 0:
		for pos in _positions_removed(previous_grid, current_grid, ["E"]):
			var enemy_cell: Control = _get_cell_control(pos)
			_spawn_cell_flash(enemy_cell, Color(1.0, 0.18, 0.25, 0.34), 0.24, 1.10)
			_shake_control(enemy_cell, 3.0, 0.12)
			_spawn_floating_text(enemy_cell, "HIT", Color(1.0, 0.84, 0.84, 1.0))
	var doors_delta: int = int(current.get("opened_doors", 0)) - int(previous.get("opened_doors", 0))
	if doors_delta > 0:
		for pos in _positions_removed(previous_grid, current_grid, ["D"]):
			var gate_cell: Control = _get_cell_control(pos)
			_spawn_cell_flash(gate_cell, Color(1.0, 0.82, 0.24, 0.34), 0.30, 1.08)
			_spawn_floating_text(gate_cell, "OPEN", Color(1.0, 0.94, 0.72, 1.0))
	if bool(current.get("terminal_used", false)) and not bool(previous.get("terminal_used", false)):
		for pos in _find_symbol_positions(current_grid, "S"):
			var terminal_cell: Control = _get_cell_control(pos)
			_spawn_cell_flash(terminal_cell, Color(0.22, 0.94, 1.0, 0.32), 0.26, 1.10)
			_spawn_floating_text(terminal_cell, "SYS", Color(0.84, 0.96, 1.0, 1.0))

func _cell_border_color(cell: String) -> Color:
	match cell:
		"P":
			return Color(0.37, 0.65, 1.0, 1.0)
		"X":
			return Color(0.20, 0.95, 0.65, 1.0)
		"G", "K", "S":
			return Color(0.95, 0.72, 0.30, 1.0)
		"E", "D", "~":
			return Color(0.95, 0.25, 0.30, 1.0)
		"*":
			return Color(0.24, 0.50, 0.80, 1.0)
		_:
			return Color(0.18, 0.25, 0.36, 1.0)

func _cell_color(cell: String) -> Color:
	match cell:
		"#":
			return Color(0.035, 0.045, 0.07, 1.0)
		"P":
			return Color(0.12, 0.36, 0.82, 1.0)
		"X":
			return Color(0.08, 0.42, 0.25, 1.0)
		"G":
			return Color(0.05, 0.46, 0.55, 1.0)
		"K":
			return Color(0.68, 0.43, 0.08, 1.0)
		"D":
			return Color(0.38, 0.16, 0.10, 1.0)
		"E":
			return Color(0.50, 0.05, 0.10, 1.0)
		"S":
			return Color(0.32, 0.16, 0.62, 1.0)
		"~":
			return Color(0.04, 0.20, 0.36, 1.0)
		"*":
			return Color(0.06, 0.15, 0.24, 1.0)
		_:
			return Color(0.10, 0.14, 0.21, 1.0)

func _cell_text(cell: String) -> String:
	match cell:
		"#":
			return ""
		"P":
			return "▶"
		"X":
			return "◎"
		"G":
			return "◆"
		"K":
			return "⚿"
		"D":
			return "▣"
		"E":
			return "×"
		"S":
			return "◉"
		"~":
			return "≈"
		"*":
			return "·"
		_:
			return ""

func _cell_tooltip(cell: String) -> String:
	match cell:
		"P":
			return "Герой"
		"X":
			return "Выход / точка завершения"
		"G":
			return "Кристалл данных"
		"K":
			return "Ключ доступа"
		"D":
			return "Закрытый шлюз"
		"E":
			return "Баг, блокирующий маршрут"
		"S":
			return "Терминал"
		"~":
			return "Блокировка / опасная зона"
		"#":
			return "Стена"
		"*":
			return "След пройденного маршрута"
		_:
			return "Пустая клетка"

func _on_help_pressed() -> void:
	_show_tutorial(0, true)

func _show_tutorial(step_index: int = 0, manual_open: bool = true) -> void:
	if TUTORIAL_STEPS.is_empty():
		return
	tutorial_step_index = clampi(step_index, 0, TUTORIAL_STEPS.size() - 1)
	if tutorial_layer == null:
		_build_tutorial_overlay()
	else:
		tutorial_layer.visible = true
	_update_tutorial_content()
	if manual_open:
		output_label.text = "Обучение открыто. После закрытия можно продолжить писать код."

func _build_tutorial_overlay() -> void:
	tutorial_layer = CanvasLayer.new()
	tutorial_layer.name = "TutorialOverlay"
	tutorial_layer.layer = 20
	add_child(tutorial_layer)

	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_layer.add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_layer.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(720, 430)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.075, 0.12, 0.97)
	style.border_color = Color(0.24, 0.52, 0.92, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	tutorial_title_label = Label.new()
	tutorial_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_title_label.add_theme_font_size_override("font_size", 28)
	tutorial_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tutorial_title_label)

	tutorial_body_label = Label.new()
	tutorial_body_label.add_theme_font_size_override("font_size", 18)
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tutorial_body_label)

	var sample_panel: PanelContainer = PanelContainer.new()
	var sample_style: StyleBoxFlat = StyleBoxFlat.new()
	sample_style.bg_color = Color(0.02, 0.03, 0.05, 0.92)
	sample_style.border_color = Color(0.12, 0.22, 0.34, 1.0)
	sample_style.border_width_left = 1
	sample_style.border_width_right = 1
	sample_style.border_width_top = 1
	sample_style.border_width_bottom = 1
	sample_style.corner_radius_top_left = 10
	sample_style.corner_radius_top_right = 10
	sample_style.corner_radius_bottom_left = 10
	sample_style.corner_radius_bottom_right = 10
	sample_panel.add_theme_stylebox_override("panel", sample_style)
	box.add_child(sample_panel)

	var sample_margin: MarginContainer = MarginContainer.new()
	sample_margin.add_theme_constant_override("margin_left", 14)
	sample_margin.add_theme_constant_override("margin_top", 8)
	sample_margin.add_theme_constant_override("margin_right", 14)
	sample_margin.add_theme_constant_override("margin_bottom", 8)
	sample_panel.add_child(sample_margin)

	var sample_label: Label = Label.new()
	sample_label.name = "SampleLabel"
	sample_label.add_theme_font_size_override("font_size", 16)
	sample_label.text = "hero.move_right()\nhero.collect()\nfor i in range(3):\n    hero.move_right()"
	sample_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sample_margin.add_child(sample_label)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	tutorial_back_button = Button.new()
	tutorial_back_button.text = "Назад"
	tutorial_back_button.custom_minimum_size = Vector2(110, 44)
	tutorial_back_button.pressed.connect(_on_tutorial_back_pressed)
	buttons.add_child(tutorial_back_button)

	tutorial_next_button = Button.new()
	tutorial_next_button.custom_minimum_size = Vector2(160, 44)
	tutorial_next_button.pressed.connect(_on_tutorial_next_pressed)
	buttons.add_child(tutorial_next_button)

	tutorial_skip_button = Button.new()
	tutorial_skip_button.text = "Закрыть"
	tutorial_skip_button.custom_minimum_size = Vector2(120, 44)
	tutorial_skip_button.pressed.connect(_close_tutorial)
	buttons.add_child(tutorial_skip_button)

func _update_tutorial_content() -> void:
	if tutorial_layer == null:
		return
	var step: Dictionary = TUTORIAL_STEPS[tutorial_step_index]
	tutorial_title_label.text = "%d/%d · %s" % [tutorial_step_index + 1, TUTORIAL_STEPS.size(), str(step.get("title", "Обучение"))]
	tutorial_body_label.text = str(step.get("body", ""))
	tutorial_back_button.disabled = tutorial_step_index <= 0
	tutorial_next_button.text = "Начать" if tutorial_step_index >= TUTORIAL_STEPS.size() - 1 else "Далее"
	tutorial_skip_button.text = "Пропустить" if not AppState.code_tutorial_completed else "Закрыть"

func _on_tutorial_back_pressed() -> void:
	tutorial_step_index = maxi(0, tutorial_step_index - 1)
	_update_tutorial_content()

func _on_tutorial_next_pressed() -> void:
	if tutorial_step_index >= TUTORIAL_STEPS.size() - 1:
		_close_tutorial()
		return
	tutorial_step_index += 1
	_update_tutorial_content()

func _close_tutorial() -> void:
	if tutorial_layer != null:
		tutorial_layer.visible = false
	if not AppState.code_tutorial_completed:
		AppState.complete_code_tutorial()
		SaveManager.save_game()

func _on_run_pressed() -> void:
	_stop_replay()
	AudioManager.play_run()
	run_button.disabled = true
	reset_button.disabled = true
	AppState.save_code_for_level(AppState.selected_level, code_editor.text)
	last_result = CodeWorldService.simulate_level(AppState.selected_level, code_editor.text)
	replay_frames = last_result.get("frames", [])
	replay_index = 0
	log_label.text = str(last_result.get("log", ""))

	var success: bool = bool(last_result.get("success", false))
	var steps: int = int(last_result.get("steps", 0))
	var run_stars: int = CodeWorldService.get_star_count_for_run(AppState.selected_level, steps, used_hint_current) if success else 0
	AppState.register_code_level_attempt(AppState.selected_level, success, steps, used_hint_current, run_stars, str(last_result.get("report", "")))

	if success:
		var level_count: int = CodeWorldService.get_level_count()
		var base_points: int = 140 + max(0, 120 - steps * 3)
		var points: int = int(base_points * (0.65 if used_hint_current else 1.0))
		if AppState.is_level_completed(AppState.selected_level):
			points = int(points * 0.25)
		AppState.add_score(points)
		AppState.complete_level(AppState.selected_level, level_count)
		level_completed_current_run = true
		SaveManager.save_game()
		output_label.text = "УСПЕХ. %s\nДействий героя: %d / цель на 3 звезды: %d\nРанг прохождения: %s\nОчков начислено: %d%s\n\n%s" % [
			str(current_level.get("success_message", "Сектор восстановлен.")),
			steps,
			CodeWorldService.get_level_min_steps(AppState.selected_level),
			CodeWorldService.get_star_text(run_stars),
			points,
			"\nПодсказка была использована, поэтому награда снижена." if used_hint_current else "",
			str(last_result.get("report", ""))
		]
		pending_result_overlay = {"success": true, "stars": run_stars, "steps": steps, "points": points, "message": str(current_level.get("success_message", "Сектор восстановлен."))}
		next_button.disabled = false
	else:
		AppState.add_mistake()
		SaveManager.save_game()
		output_label.text = "НЕ ЗАВЕРШЕНО. %s\n\n%s\n\n%s" % [
			str(last_result.get("message", "Проверь код.")),
			str(current_level.get("failure_hint", "Проверь маршрут, отступы и порядок команд.")),
			str(last_result.get("report", ""))
		]
		pending_result_overlay = {"success": false, "stars": 0, "steps": steps, "points": 0, "message": str(last_result.get("message", "Проверь код."))}
		next_button.disabled = true

	_refresh_sector_hud(last_result)
	_update_progress_line()
	_start_replay_or_show_final_grid()

func _start_replay_or_show_final_grid() -> void:
	if replay_frames.is_empty():
		_draw_grid(last_result.get("display_grid", []))
		_run_finished_after_replay()
		return
	_show_replay_frame(0)
	if replay_frames.size() > 1:
		replay_timer.start()
	else:
		_run_finished_after_replay()

func _show_replay_frame(index: int) -> void:
	if index < 0 or index >= replay_frames.size():
		return
	var frame: Dictionary = replay_frames[index]
	var previous_frame: Dictionary = replay_frames[index - 1] if index > 0 else {}
	_draw_grid(frame.get("grid", []))
	if not previous_frame.is_empty():
		_animate_frame_transition(previous_frame, frame)
	_play_replay_sfx(index, frame)
	var event_text: String = str(frame.get("event", ""))
	_refresh_sector_hud(frame)
	progress_label.text = "%s · Шаг: %d · %s · Инвентарь: %s" % [
		_progress_prefix(),
		int(frame.get("steps", 0)),
		event_text,
		_array_to_text(frame.get("inventory", []), "пусто")
	]

func _on_replay_timeout() -> void:
	replay_index += 1
	if replay_index >= replay_frames.size():
		_stop_replay()
		_draw_grid(last_result.get("display_grid", []))
		_run_finished_after_replay()
		return
	_show_replay_frame(replay_index)

func _run_finished_after_replay() -> void:
	run_button.disabled = false
	reset_button.disabled = false
	_update_progress_line()
	if not pending_result_overlay.is_empty():
		var run_success: bool = bool(pending_result_overlay.get("success", false))
		if run_success:
			AudioManager.play_victory()
		else:
			AudioManager.play_fail()
		_flash_output_panel(run_success)
		_show_result_overlay(pending_result_overlay)
		pending_result_overlay.clear()

func _play_replay_sfx(index: int, frame: Dictionary) -> void:
	if index <= 0 or index >= replay_frames.size():
		return
	var previous: Dictionary = replay_frames[index - 1]
	if int(frame.get("collected", 0)) > int(previous.get("collected", 0)):
		AudioManager.play_collect()
	elif int(frame.get("defeated", 0)) > int(previous.get("defeated", 0)):
		AudioManager.play_attack()
	elif int(frame.get("opened_doors", 0)) > int(previous.get("opened_doors", 0)):
		AudioManager.play_gate()
	elif bool(frame.get("terminal_used", false)) and not bool(previous.get("terminal_used", false)):
		AudioManager.play_terminal()
	elif int(frame.get("steps", 0)) > int(previous.get("steps", 0)):
		AudioManager.play_step()

func _stop_replay() -> void:
	if replay_timer != null:
		replay_timer.stop()
	replay_frames.clear()
	replay_index = 0

func _update_progress_line() -> void:
	progress_label.text = _progress_prefix()

func _progress_prefix() -> String:
	return "Сектор %d/%d · Открыт: %d · Пройдено: %d · Очки: %d · Ошибки: %d" % [
		AppState.selected_level,
		CodeWorldService.get_level_count(),
		AppState.max_unlocked_level,
		AppState.completed_levels.size(),
		AppState.score,
		AppState.mistakes
	]

func _on_reset_pressed() -> void:
	_stop_replay()
	code_editor.text = CodeWorldService.get_default_code(AppState.selected_level)
	used_hint_current = false
	hint_button.disabled = false
	hint_button.text = "Сканер"
	output_label.text = _build_idle_output()
	log_label.text = "Сектор готов к новому запуску."
	_refresh_sector_hud({})
	next_button.disabled = not AppState.is_level_completed(AppState.selected_level)
	run_button.disabled = false
	reset_button.disabled = false
	_draw_grid(CodeWorldService.get_initial_display_grid(AppState.selected_level))
	_update_progress_line()

func _on_hint_pressed() -> void:
	used_hint_current = true
	hint_stage += 1
	var hint_text: String = CodeWorldService.get_level_hint(AppState.selected_level)
	var hint_steps: Array = _variant_to_array(current_level.get("hint_steps", []))
	if hint_stage <= hint_steps.size():
		hint_text = str(hint_steps[hint_stage - 1])
	if hint_stage >= 3 or hint_stage >= maxi(1, hint_steps.size()):
		hint_button.disabled = true
		hint_button.text = "Подсказки взяты"
	elif hint_stage == 1:
		hint_button.text = "Ещё совет"
	else:
		hint_button.text = "Псевдокод"
	output_label.text = "Подсказка %d:\n%s\n\nНаграда за успешное прохождение будет снижена, но сектор всё равно засчитывается." % [hint_stage, hint_text]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.ctrl_pressed and key_event.keycode == KEY_ENTER:
			if not run_button.disabled:
				_on_run_pressed()
				get_viewport().set_input_as_handled()
		elif key_event.ctrl_pressed and key_event.keycode == KEY_R:
			_on_reset_pressed()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F1:
			if not hint_button.disabled:
				_on_hint_pressed()
				get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F2:
			_on_codex_pressed()
			get_viewport().set_input_as_handled()
func _refresh_sector_hud(source: Dictionary) -> void:
	if objective_label == null or status_label == null:
		return
	objective_label.text = _build_objective_checklist(source)
	status_label.text = _build_sector_status(source)

func _build_objective_checklist(source: Dictionary) -> String:
	var requirements: Dictionary = current_level.get("requirements", {})
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Цели сектора:")
	if bool(requirements.get("reach_exit", true)):
		lines.append(_check_mark(bool(source.get("at_exit", false))) + " Дойти до портала X")
	if bool(requirements.get("collect_all", false)):
		var remaining_items: int = int(source.get("remaining_items", 1)) if not source.is_empty() else 1
		lines.append(_check_mark(not source.is_empty() and remaining_items <= 0) + " Собрать кристаллы и ключи")
	if bool(requirements.get("defeat_all", false)):
		var remaining_enemies: int = int(source.get("remaining_enemies", 1)) if not source.is_empty() else 1
		lines.append(_check_mark(not source.is_empty() and remaining_enemies <= 0) + " Устранить баги")
	if bool(requirements.get("open_doors", false)):
		var remaining_doors: int = int(source.get("remaining_doors", 1)) if not source.is_empty() else 1
		lines.append(_check_mark(not source.is_empty() and remaining_doors <= 0) + " Открыть шлюзы")
	if bool(requirements.get("activate_terminal", false)):
		lines.append(_check_mark(bool(source.get("terminal_used", false))) + " Активировать терминал")
	return "\n".join(lines)

func _build_sector_status(source: Dictionary) -> String:
	if source.is_empty():
		return "Терминал готов · инвентарь: пусто · F1 сканер · F2 команды"
	var inventory_text: String = _array_to_text(source.get("inventory", []), "пусто")
	return "Статус: шагов %d · собрано %d · багов устранено %d · шлюзов открыто %d · инвентарь: %s" % [
		int(source.get("steps", 0)),
		int(source.get("collected", 0)),
		int(source.get("defeated", 0)),
		int(source.get("opened_doors", 0)),
		inventory_text
	]

func _check_mark(done: bool) -> String:
	return "✓" if done else "□"

func _on_speed_pressed() -> void:
	replay_speed_index = (replay_speed_index + 1) % REPLAY_SPEEDS.size()
	replay_timer.wait_time = float(REPLAY_SPEEDS[replay_speed_index])
	_update_speed_button_text()
	output_label.text = "Скорость проигрывания: " + str(REPLAY_SPEED_NAMES[replay_speed_index])

func _update_speed_button_text() -> void:
	if speed_button != null:
		speed_button.text = "Скорость " + str(REPLAY_SPEED_NAMES[replay_speed_index])

func _on_codex_pressed() -> void:
	_show_codex_overlay()

func _show_codex_overlay() -> void:
	if codex_layer != null:
		codex_layer.queue_free()
	codex_layer = _build_overlay_layer("Справочник команд", _build_codex_text(), "Закрыть", Callable(self, "_close_codex_overlay"), "")

func _build_codex_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Основные команды героя:")
	lines.append("hero.move_right(), hero.move_left(), hero.move_up(), hero.move_down()")
	lines.append("hero.move('right') / hero.move('left') / hero.move('up') / hero.move('down')")
	lines.append("hero.collect() - подобрать кристалл или ключ рядом")
	lines.append("hero.attack() - уничтожить баг рядом")
	lines.append("hero.open_gate() - открыть шлюз при наличии ключа или активированного терминала")
	lines.append("hero.activate() - активировать терминал")
	lines.append("hero.scan(), hero.status(), hero.say('текст')")
	lines.append("")
	lines.append("Проверки для условий:")
	lines.append("hero.can_move('right'), hero.near('gem'), hero.near('enemy'), hero.near('door')")
	lines.append("hero.sees_enemy(), hero.has_key(), hero.has_item('key'), hero.at_exit()")
	lines.append("")
	lines.append("Примеры:")
	lines.append("for step in ['right', 'right', 'down']:")
	lines.append("    hero.move(step)")
	lines.append("")
	lines.append("if hero.sees_enemy():")
	lines.append("    hero.attack()")
	lines.append("")
	lines.append("def go_right(count):")
	lines.append("    for i in range(count):")
	lines.append("        hero.move_right()")
	return "\n".join(lines)

func _close_codex_overlay() -> void:
	if codex_layer != null:
		codex_layer.queue_free()
		codex_layer = null

func _show_result_overlay(data: Dictionary) -> void:
	if result_layer != null:
		result_layer.queue_free()
	var success: bool = bool(data.get("success", false))
	var is_final_success: bool = success and AppState.selected_level >= CodeWorldService.get_level_count()
	var title: String = "Ядро PyQuest восстановлено" if is_final_success else ("Сектор восстановлен" if success else "Сектор не восстановлен")
	var body: String = _build_result_overlay_text(data)
	var main_button_text: String = "Финальный экран" if is_final_success else ("Следующий сектор" if success else "Исправить код")
	var main_action: Callable = Callable(self, "_on_result_next_pressed") if success else Callable(self, "_close_result_overlay")
	result_layer = _build_overlay_layer(title, body, main_button_text, main_action, "Повторить")

func _build_result_overlay_text(data: Dictionary) -> String:
	if bool(data.get("success", false)) and AppState.selected_level >= CodeWorldService.get_level_count():
		return "Ядро PyQuest восстановлено.

Финальный сектор завершён как итоговая практическая задача: функция, цикл, условие, ключи, шлюзы, терминалы, баги и кристаллы собраны в одном маршруте.

Звёзды: %s
Действий: %d / цель: %d
Очки: %d

Нажми «Финальный экран», чтобы увидеть статистику кампании, общий ранг и достижения." % [
			CodeWorldService.get_star_text(int(data.get("stars", 0))),
			int(data.get("steps", 0)),
			CodeWorldService.get_level_min_steps(AppState.selected_level),
			int(data.get("points", 0))
		]
	if bool(data.get("success", false)):
		return "%s

Ранг: %s
Действий: %d / цель: %d
Очки: %d

Карта кампании сохранит лучший результат. Можно перейти дальше или закрыть окно и улучшить код." % [
			str(data.get("message", "Сектор восстановлен.")),
			CodeWorldService.get_star_text(int(data.get("stars", 0))),
			int(data.get("steps", 0)),
			CodeWorldService.get_level_min_steps(AppState.selected_level),
			int(data.get("points", 0))
		]
	return "Причина: %s

Посмотри последний кадр, список целей слева и журнал событий. Обычно проблема в том, что герой не дошёл до X, не собрал объект или не выполнил действие рядом с багом, шлюзом или терминалом." % str(data.get("message", "Проверь код."))

func _build_overlay_layer(title_text: String, body_text: String, main_button_text: String, main_action: Callable, secondary_button_text: String) -> CanvasLayer:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 25
	add_child(layer)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	var viewport_size: Vector2 = get_viewport_rect().size
	var overlay_width: float = min(860.0, max(640.0, viewport_size.x - 120.0))
	var overlay_height: float = min(520.0, max(420.0, viewport_size.y - 90.0))
	var content_width: float = overlay_width - 64.0

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(overlay_width, overlay_height)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.045, 0.065, 0.105, 1.0), Color(0.25, 0.52, 0.92, 1.0)))
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(content_width, overlay_height - 42.0)
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title: Label = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(content_width, 42)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(content_width, overlay_height - 180.0)
	scroll.horizontal_scroll_mode = 0
	scroll.vertical_scroll_mode = 1
	box.add_child(scroll)

	var body_holder: MarginContainer = MarginContainer.new()
	body_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_holder.custom_minimum_size = Vector2(content_width, 0)
	body_holder.add_theme_constant_override("margin_left", 2)
	body_holder.add_theme_constant_override("margin_top", 2)
	body_holder.add_theme_constant_override("margin_right", 8)
	body_holder.add_theme_constant_override("margin_bottom", 2)
	scroll.add_child(body_holder)

	var body: Label = Label.new()
	body.add_theme_font_size_override("font_size", 17)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = body_text
	body.custom_minimum_size = Vector2(content_width - 12.0, 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.clip_text = false
	body_holder.add_child(body)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	if not secondary_button_text.is_empty():
		var secondary: Button = Button.new()
		secondary.text = secondary_button_text
		secondary.custom_minimum_size = Vector2(150, 44)
		secondary.pressed.connect(_on_result_retry_pressed)
		buttons.add_child(secondary)

	var main_button: Button = Button.new()
	main_button.text = main_button_text
	main_button.custom_minimum_size = Vector2(200, 44)
	main_button.pressed.connect(main_action)
	buttons.add_child(main_button)

	var close_button: Button = Button.new()
	close_button.text = "Закрыть"
	close_button.custom_minimum_size = Vector2(140, 44)
	close_button.pressed.connect(_close_active_overlay)
	buttons.add_child(close_button)

	return layer

func _on_result_retry_pressed() -> void:
	_close_result_overlay()
	_on_reset_pressed()

func _on_result_next_pressed() -> void:
	_close_result_overlay()
	if not next_button.disabled:
		_on_next_pressed()

func _close_result_overlay() -> void:
	if result_layer != null:
		result_layer.queue_free()
		result_layer = null

func _close_active_overlay() -> void:
	if result_layer != null:
		_close_result_overlay()
		return
	if codex_layer != null:
		_close_codex_overlay()

func _array_to_text(value: Variant, empty_text: String = "пусто") -> String:
	if typeof(value) != TYPE_ARRAY:
		return empty_text
	var items: Array = value
	if items.is_empty():
		return empty_text
	var text_items: PackedStringArray = PackedStringArray()
	for item in items:
		text_items.append(str(item))
	return ", ".join(text_items)

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result

func _on_next_pressed() -> void:
	_close_result_overlay()
	_close_codex_overlay()
	AppState.save_code_for_level(AppState.selected_level, code_editor.text)
	var level_count: int = CodeWorldService.get_level_count()
	if AppState.selected_level >= level_count:
		SceneRouter.go_to_final()
		return
	AppState.selected_level += 1
	if AppState.selected_level > AppState.max_unlocked_level:
		AppState.max_unlocked_level = AppState.selected_level
	SaveManager.save_game()
	_load_level()

func _on_menu_pressed() -> void:
	_close_result_overlay()
	_close_codex_overlay()
	AppState.save_code_for_level(AppState.selected_level, code_editor.text)
	SaveManager.save_game()
	SceneRouter.go_to_main_menu()
