@tool
class_name StoryFileList
extends Control

signal story_selected(story: StoryData)

var filesystem: EditorFileSystem
var selected_path: String = ''

@onready var item_list: ItemList = %ItemList


func _ready() -> void:
	filesystem = EditorInterface.get_resource_filesystem()
	filesystem.filesystem_changed.connect(_refresh)
	item_list.item_selected.connect(_on_item_selected)

	if not filesystem.is_scanning():
		_refresh()


func _refresh() -> void:
	item_list.clear()

	var root := filesystem.get_filesystem()

	if root == null:
		return

	_scan_directory(root)
	_restore_selection()


func _restore_selection() -> void:
	if selected_path.is_empty():
		return

	for i: int in item_list.item_count:
		var path := item_list.get_item_metadata(i) as String

		if path == selected_path:
			item_list.select(i)
			return


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
			item_list.set_item_metadata(item_list.item_count - 1, path)

	for i: int in directory.get_subdir_count():
		_scan_directory(directory.get_subdir(i))


func _on_item_selected(index: int) -> void:
	var path := item_list.get_item_metadata(index) as String

	if path.is_empty():
		return

	selected_path = path

	var resource := load(path)

	if resource is StoryData:
		story_selected.emit(resource as StoryData)
