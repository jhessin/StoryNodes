@tool
class_name StoryData
extends Resource

const START_NODE_ID: StringName = &'__start__'

@export var title: String = ''
@export var description: String = ''
@export var character_library: StoryCharacterLibrary
@export var variable_library: StoryVariableLibrary

var node_list: Array[StoryNode]:
	get:
		return _nodes.values()
var node_ids: Array[StringName]:
	get:
		return _nodes.keys()
var node_count: int:
	get:
		return _nodes.size()
var link_list: Array[StoryLink]:
	get:
		return _links.keys()
var link_count: int:
	get:
		return _links.size()
var character_list: Array[StoryCharacter]:
	get:
		if character_library == null:
			return []
		return character_library.character_list
var character_count: int:
	get:
		if character_library == null:
			return 0
		return character_library.character_count
var cast: Array[StoryCharacter]:
	get:
		var result: Array[StoryCharacter] = []
		for id: StringName in _cast.keys():
			var character: StoryCharacter = character_library.get_character(id)
			if character != null:
				result.append(character)
		return result
var cast_ids: Array[StringName]:
	get:
		return _cast.keys()

var cast_count: int:
	get:
		return _cast.size()

var is_dirty: bool = false

@export_storage
var _cast: Dictionary[StringName, bool] = { }

@export_storage
var _nodes: Dictionary[StringName, StoryNode] = { }

@export_storage
var _links: Dictionary[StoryLink, Object] = { }


## ===
## Lifecycle methods
## ===
func _init() -> void:
	_ensure_start()


func mark_changed() -> void:
	is_dirty = true
	emit_changed()


## ===
## Character methods
## ===
func add_character(character: StoryCharacter) -> void:
	if character == null or character_library == null:
		return

	character_library.add_character(character)


func remove_character(character: StoryCharacter) -> void:
	if character == null or character_library == null:
		return

	character_library.remove_character(character.id)


## ===
## Node methods
## ===
func add_node(node: StoryNode) -> void:
	if (
		node == null or node.instance_id.is_empty()
		or has_node(node.instance_id) or node.instance_id == START_NODE_ID
	):
		return

	_nodes[node.instance_id] = node

	mark_changed()


func get_node(id: StringName) -> StoryNode:
	return _nodes.get(id, null)


func has_node(id: StringName) -> bool:
	return get_node(id) != null


func has_nodes() -> bool:
	return not _nodes.is_empty()


func get_next_nodes(id: StringName) -> Array[StoryNode]:
	var results: Array[StoryNode] = []

	for link: StoryLink in get_links_from(id):
		var node := get_node(link.to)

		if node != null:
			results.append(node)

	return results


func get_start_node() -> StoryNode:
	_ensure_start()
	return get_node(START_NODE_ID)


func is_end_node(id: StringName) -> bool:
	return has_node(id) and not has_next_nodes(id)


func get_end_nodes() -> Array[StoryNode]:
	var results: Array[StoryNode] = []

	for node: StoryNode in node_list:
		if not has_next_nodes(node.instance_id):
			results.append(node)

	return results


func get_end_node() -> StoryNode:
	var end_nodes := get_end_nodes()

	if end_nodes.is_empty():
		return null

	return end_nodes[0]


func has_next_nodes(id: StringName) -> bool:
	return not get_links_from(id).is_empty()


func has_previous_nodes(id: StringName) -> bool:
	return not get_links_to(id).is_empty()


func get_previous_nodes(id: StringName) -> Array[StoryNode]:
	var results: Array[StoryNode] = []

	for link: StoryLink in get_links_to(id):
		var node := get_node(link.from)

		if node != null:
			results.append(node)

	return results


func remove_node(id: StringName) -> void:
	if not has_node(id) or id == START_NODE_ID:
		return

	for link: StoryLink in _links.keys():
		if link.from == id or link.to == id:
			remove_link(link)

	_nodes.erase(id)
	mark_changed()


func clear_nodes() -> void:
	_links.clear()
	_nodes.clear()
	_ensure_start()
	mark_changed()


## ===
## Link methods
## ===
func add_link(from: StringName, to: StringName, from_port: int = 0, to_port: int = 0) -> StoryLink:
	if not has_node(from) or not has_node(to):
		return null

	var existing := get_link(from, to, from_port, to_port)
	if existing != null:
		return existing

	var link := StoryLink.new()
	link.from = from
	link.to = to
	link.from_port = from_port
	link.to_port = to_port

	_links[link] = null
	mark_changed()

	return link


func get_link(from: StringName, to: StringName, from_port: int, to_port: int) -> StoryLink:
	for link: StoryLink in _links:
		if (
			link.from == from and link.to == to
			and link.from_port == from_port and link.to_port == to_port
		):
			return link

	return null


func get_links() -> Array[StoryLink]:
	return link_list


func has_link(from: StringName, to: StringName, from_port: int, to_port: int) -> bool:
	return get_link(from, to, from_port, to_port) != null


func has_links() -> bool:
	return not _links.is_empty()


func remove_link(link: StoryLink) -> void:
	_links.erase(link)
	mark_changed()


func remove_links_from(id: StringName) -> void:
	var has_changed := false
	for link: StoryLink in get_links_from(id):
		remove_link(link)
		has_changed = true

	if has_changed:
		mark_changed()


func remove_links_to(id: StringName) -> void:
	var has_changed := false
	for link: StoryLink in get_links_to(id):
		remove_link(link)
		has_changed = true

	if has_changed:
		mark_changed()


func remove_links(id: StringName) -> void:
	remove_links_from(id)
	remove_links_to(id)


func get_links_from(from: StringName) -> Array[StoryLink]:
	var results: Array[StoryLink] = []

	for link: StoryLink in _links:
		if link.from == from:
			results.append(link)

	return results


func get_links_to(to: StringName) -> Array[StoryLink]:
	var results: Array[StoryLink] = []

	for link: StoryLink in _links:
		if link.to == to:
			results.append(link)

	return results


func clear_links() -> void:
	_links.clear()
	mark_changed()


func clear() -> void:
	_links.clear()
	_nodes.clear()
	mark_changed()


func is_valid() -> bool:
	if character_library == null:
		return false

	for id: StringName in cast_ids:
		if not character_library.has_character(id):
			return false

	for node: StoryNode in node_list:
		if node == null:
			return false

		if node.instance_id.is_empty():
			return false

		if get_node(node.instance_id) != node:
			return false

	for link: StoryLink in link_list:
		if link == null:
			return false

		if not has_node(link.from):
			return false

		if not has_node(link.to):
			return false

	return true


func ensure_start_node() -> void:
	_ensure_start()


## ===
## Cast methods
## ===
func add_to_cast(character: StoryCharacter) -> void:
	if character == null:
		push_error('Cannot add a null character to the cast.')
		return

	if character_library == null:
		push_error('Cannot add character to cast: character library is null.')
		return

	if not character_library.has_character(character.id):
		push_error(
			'Cannot add character "%s" to cast: character is not in the library.' % character.id
		)
		return

	if _cast.has(character.id):
		push_error('Character "%s" is already in the cast.' % character.id)
		return

	_cast[character.id] = true
	mark_changed()


func remove_from_cast(character: StoryCharacter) -> void:
	if character == null:
		push_error('Cannot remove a null character from the cast.')
		return

	if not _cast.has(character.id):
		push_error('Character "%s" is not in the cast.' % character.id)
		return

	_cast.erase(character.id)
	mark_changed()


func is_in_cast(character: StoryCharacter) -> bool:
	if character == null:
		return false
	if character_library == null:
		return false
	if not character_library.has_character(character.id):
		return false
	return _cast.has(character.id)


func clear_cast() -> void:
	if _cast.is_empty():
		return

	_cast.clear()
	mark_changed()


## ===
## Private methods
## ===
func _ensure_start() -> void:
	if _nodes.has(START_NODE_ID):
		return

	var start_node_resource: StoryNode = load(
		"res://addons/story_nodes/resources/nodes/start_node.tres"
	).duplicate(true) as StoryNode

	if start_node_resource == null:
		push_error('Unable to load the start node.')
		return

	start_node_resource.instance_id = START_NODE_ID

	_nodes[START_NODE_ID] = start_node_resource
