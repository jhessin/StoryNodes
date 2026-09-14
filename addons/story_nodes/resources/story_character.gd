@tool
class_name StoryCharacter
extends Resource

@export var name: String = ''
@export var image: Texture2D
@export var color: Color = Color.WHITE


func _init(character_name: String = '', _image: Texture2D = null, _color: Color = Color.WHITE) -> void:
	name = character_name
	image = _image
	color = _color
