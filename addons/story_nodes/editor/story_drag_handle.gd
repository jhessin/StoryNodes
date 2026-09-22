@tool
class_name StoryDragHandle
extends Control

@export var drag_data: Variant


func _ready() -> void:
	custom_minimum_size = Vector2(24.0, 24.0)
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	queue_redraw()


func _draw() -> void:
	var center_y: float = size.y * 0.5
	var line_length: float = 12.0
	var spacing: float = 4.0
	var line_width: float = 2.0

	for index: int in range(3):
		var y: float = center_y + (index - 1) * spacing

		draw_line(
			Vector2((size.x - line_length) * 0.5, y),
			Vector2((size.x + line_length) * 0.5, y),
			Color.WHITE,
			line_width,
		)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := _create_drag_preview()
	set_drag_preview(preview)

	return drag_data


func _create_drag_preview() -> Control:
	var preview := Label.new()
	preview.text = '☰'
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.custom_minimum_size = size

	return preview
