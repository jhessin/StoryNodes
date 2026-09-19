@tool
class_name StoryNodeLibraryEditor
extends VBoxContainer

var library: StoryNodeLibrary


func set_library(value: StoryNodeLibrary) -> void:
	library = value
	_refresh()


func _refresh() -> void:
	for child: Node in get_children():
		child.queue_free()

	if library == null:
		return

	var categories: Dictionary[String, VBoxContainer] = { }

	for node: StoryNode in library.node_list:
		var category: String = ''

		if not categories.has(category):
			var category_container := VBoxContainer.new()
			category_container.name = category
			add_child(category_container)

			var category_label := Label.new()
			category_label.text = category
			category_label.add_theme_font_size_override('font_size', 16)
			category_container.add_child(category_label)

			categories[category] = category_container

		var button := _create_definition_button(node)
		categories[category].add_child(button)


func _create_definition_button(node: StoryNode) -> Button:
	var button := Button.new()

	button.text = node.display_name
	button.tooltip_text = node.description
	# button.disabled = not node.instantiable
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# if not node.instantiable:
	# 	button.tooltip_text += '\n\nThis node is created automatically.'
	return button
