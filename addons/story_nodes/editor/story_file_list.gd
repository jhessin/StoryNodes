@tool
class_name StoryFileList
extends Control

signal story_selected(story: StoryData)
signal story_created(story: StoryData)

const ITEM_HEIGHT: float = 32.0

var filesystem: EditorFileSystem
var selected_path: String = ''
var context_index: int = -1

@onready var item_list: ItemList = %ItemList
@onready var create_button: Button = %CreateButton
@onready var save_dialog: FileDialog = %SaveDialog
@onready var save_menu: PopupMenu = %SaveMenu


func _ready() -> void:
	item_list.gui_input.connect(_on_gui_input)
	save_menu.id_pressed.connect(_on_save_menu_selected)
	filesystem = EditorInterface.get_resource_filesystem()
	filesystem.filesystem_changed.connect(_refresh)

	item_list.item_selected.connect(_on_item_selected)
	create_button.pressed.connect(_on_new_story_pressed)
	save_dialog.file_selected.connect(_on_save_dialog_file_selected)

	if not filesystem.is_scanning():
		_refresh()


func mark_dirty(data: StoryData) -> void:
	if data == null:
		return

	for i: int in item_list.item_count:
		var path := item_list.get_item_metadata(i) as String

		if path != data.resource_path:
			continue

		var title := data.title

		if title.is_empty():
			title = path

		if data.is_dirty:
			title += '(*)'

		item_list.set_item_text(i, title)
		item_list.set_item_tooltip(i, data.description)
		return


func select_path(path: String) -> void:
	selected_path = path

	for i: int in item_list.item_count:
		var item_path := item_list.get_item_metadata(i) as String

		if item_path == path:
			item_list.select(i)
			return


func _on_save_menu_selected(id: int) -> void:
	match save_menu.get_item_text(id):
		'Save':
			if context_index >= 0 and context_index < item_list.item_count:
				_save(context_index)
		'Save All':
			for i: int in item_list.item_count:
				_save(i)

	context_index = -1


func _save(index: int) -> void:
	var path := item_list.get_item_metadata(index) as String

	if path.is_empty():
		return

	var story_data: StoryData = load(path) as StoryData

	if story_data == null:
		return

	var error := ResourceSaver.save(story_data)

	if error != OK:
		push_error('Story save error: ', error)
		push_error('Story save error string: ', error_string(error))
		return

	story_data.is_dirty = false
	mark_dirty(story_data)


func _update_item_list_size() -> void:
	item_list.custom_minimum_size.y = item_list.item_count * ITEM_HEIGHT


func _refresh() -> void:
	item_list.clear()

	var root := filesystem.get_filesystem()

	if root == null:
		return

	_scan_directory(root)
	_restore_selection()
	_update_item_list_size()


func _restore_selection() -> void:
	if selected_path.is_empty():
		return

	select_path(selected_path)


func _scan_directory(directory: EditorFileSystemDirectory) -> void:
	for i: int in directory.get_file_count():
		var path := directory.get_file_path(i)

		if not path.ends_with(".tres"):
			continue

		var resource := load(path)

		if resource is StoryData:
			if resource.title.is_empty():
				item_list.add_item(path)
			else:
				item_list.add_item(resource.title)

			var index: int = item_list.item_count - 1
			item_list.set_item_metadata(index, path)
			var description: String = resource.description
			item_list.set_item_tooltip(index, description)
			mark_dirty(resource as StoryData)

	for i: int in directory.get_subdir_count():
		_scan_directory(directory.get_subdir(i))


func _on_item_selected(index: int) -> void:
	var path := item_list.get_item_metadata(index) as String

	if path.is_empty():
		return

	var resource := load(path)

	if resource is StoryData:
		story_selected.emit(resource as StoryData)


func _on_new_story_pressed() -> void:
	save_dialog.popup_centered_ratio()


func _on_save_dialog_file_selected(path: String) -> void:
	if not path.ends_with('.tres'):
		path += '.tres'

	var story := StoryData.new()

	var error := ResourceSaver.save(story, path)

	if error != OK:
		push_error("Failed to save story: %s" % error_string(error))
		return

	selected_path = path

	story.resource_path = path

	filesystem.scan()
	select_path(path)

	story_selected.emit(story)

	EditorInterface.inspect_object(story)


func _on_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	if not event.pressed:
		return

	if event.button_index != MOUSE_BUTTON_RIGHT:
		return

	context_index = item_list.get_item_at_position(event.position, true)

	if context_index < 0:
		return

	_show_menu()


func _show_menu() -> void:
	var screen_position: Vector2 = DisplayServer.mouse_get_position()
	save_menu.popup(Rect2(screen_position, Vector2.ZERO))
