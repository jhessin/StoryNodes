@tool
class_name StoryData
extends Resource

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

@export_storage
var _nodes: Dictionary[StringName, StoryNode] = { }

@export_storage
var _links: Dictionary[StoryLink, Object] = { }


## ===
## Node methods
## ===
func add_node(node: StoryNode) -> void:
	if node == null or node.id.is_empty() or has_node(node.id):
		return

	_nodes[node.id] = node


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


func is_start_node(id: StringName) -> bool:
	return has_node(id) and not has_previous_nodes(id)


func get_start_nodes() -> Array[StoryNode]:
	var results: Array[StoryNode] = []

	for node: StoryNode in node_list:
		if not has_previous_nodes(node.id):
			results.append(node)

	return results


func get_start_node() -> StoryNode:
	var start_nodes := get_start_nodes()

	if start_nodes.is_empty():
		return null

	return start_nodes[0]


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
	if not has_node(id):
		return

	for link: StoryLink in _links.keys():
		if link.from == id or link.to == id:
			remove_link(link)

	_nodes.erase(id)


func clear_nodes() -> void:
	_links.clear()
	_nodes.clear()


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


func remove_links_from(id: StringName) -> void:
	for link: StoryLink in get_links_from(id):
		remove_link(link)


func remove_links_to(id: StringName) -> void:
	for link: StoryLink in get_links_to(id):
		remove_link(link)


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


func clear() -> void:
	_links.clear()
	_nodes.clear()


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
