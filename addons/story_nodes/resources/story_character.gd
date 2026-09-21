@tool
class_name StoryCharacter
extends Resource

@export var name: String = ''
@export var image: Texture2D
@export var color: Color = Color.WHITE

var id: StringName:
	get:
		return _id
@export_storage var _id: StringName = &''


func _init(
	character_id: StringName = &'',
	character_name: String = '',
	_image: Texture2D = null,
	_color: Color = Color.WHITE,
) -> void:
	_id = character_id
	name = character_name
	image = _image
	color = _color
