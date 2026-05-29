class_name AnimatedBackground
extends Control

@onready var far_layer: TextureRect = %FarLayer
@onready var near_layer: TextureRect = %NearLayer

var elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var mouse_offset: Vector2 = Vector2(mouse_position.x / viewport_size.x - 0.5, mouse_position.y / viewport_size.y - 0.5)
	far_layer.position = Vector2(-70.0, -50.0) + Vector2(sin(elapsed * 0.17) * 14.0, cos(elapsed * 0.13) * 10.0) - mouse_offset * 22.0
	near_layer.position = Vector2(-120.0, -90.0) + Vector2(cos(elapsed * 0.21) * 18.0, sin(elapsed * 0.18) * 14.0) - mouse_offset * 42.0
