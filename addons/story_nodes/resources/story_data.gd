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
var _nodes: Dictionary[StringName, StoryNode] = { }

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
