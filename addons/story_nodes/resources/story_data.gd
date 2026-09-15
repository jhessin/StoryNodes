@tool
class_name StoryData
extends Resource

const START_NODE_ID: StringName = &'start'

@export var title: String = ''
@export var description: String = ''

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
		return _characters
var character_count: int:
	get:
		return _characters.size()

var is_dirty: bool = false
@export_storage
var _characters: Array[StoryCharacter] = []

@export_storage
var _nodes: Dictionary[StringName, StoryNode] = { }

@export_storage
var _links: Dictionary[StoryLink, Object] = { }


func _init() -> void:
	_ensure_start()


func mark_changed() -> void:
	is_dirty = true
	emit_changed()


## ===
## Character methods
## ===
func add_character(character: StoryCharacter) -> void:
	if character == null:
		return

	if _characters.has(character):
		return

	_characters.append(character)
	mark_changed()


func remove_character(character: StoryCharacter) -> void:
	if character == null:
		return

	_characters.erase(character)
	mark_changed()


## ===
## Node methods
## ===
func add_node(node: StoryNode) -> void:
	if node == null or node.id.is_empty() or has_node(node.id):
		return

	_nodes[node.id] = node

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
	return get_node(START_NODE_ID)


func is_end_node(id: StringName) -> bool:
	return has_node(id) and not has_next_nodes(id)


func get_end_nodes() -> Array[StoryNode]:
	var results: Array[StoryNode] = []

	for node: StoryNode in node_list:
		if not has_next_nodes(node.id):
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
func add_link(from: StringName, to: StringName) -> StoryLink:
	if not has_node(from) or not has_node(to):
		return null

	var existing := get_link(from, to)
	if existing != null:
		return existing

	var link := StoryLink.new(from, to)

	_links[link] = null
	mark_changed()

	return link


func get_link(from: StringName, to: StringName) -> StoryLink:
	for link: StoryLink in _links:
		if link.from == from and link.to == to:
			return link

	return null


func get_links() -> Array[StoryLink]:
	return link_list


func has_link(from: StringName, to: StringName) -> bool:
	return get_link(from, to) != null


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
	for node: StoryNode in node_list:
		if node == null:
			return false

		if node.id.is_empty():
			return false

		if get_node(node.id) != node:
			return false

	for link: StoryLink in link_list:
		if link == null:
			return false

		if not has_node(link.from):
			return false

		if not has_node(link.to):
			return false

	return true


func _ensure_start() -> void:
	if _nodes.has(START_NODE_ID):
		return

	_nodes[START_NODE_ID] = StoryNode.new(START_NODE_ID, 'Start')
