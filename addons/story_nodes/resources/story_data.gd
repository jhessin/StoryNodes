class_name StoryData
extends Resource

@export var title: String = ''
@export var description: String = ''

var nodes: Dictionary[StringName, StoryNode] = { }

var links: Dictionary[StoryLink, Object] = { }


## ===
## Node methods
## ===
func add_node(node: StoryNode) -> void:
	if has_node(node.id):
		return

	nodes[node.id] = node


func get_node(id: StringName) -> StoryNode:
	return nodes.get(id, null)


func has_node(id: StringName) -> bool:
	return get_node(id) != null


func remove_node(id: StringName) -> void:
	for link: StoryLink in links.keys():
		if link.from == id or link.to == id:
			remove_link(link)

	nodes.erase(id)


## ===
## Link methods
## ===
func add_link(from: StringName, to: StringName) -> StoryLink:
	var link := StoryLink.new(from, to)

	links[link] = null

	return link


func get_link(from: StringName, to: StringName) -> StoryLink:
	for link: StoryLink in links:
		if link.from == from and link.to == to:
			return link

	return null


func remove_link(link: StoryLink) -> void:
	links.erase(link)


func get_links_from(from: StringName) -> Array[StoryLink]:
	var results: Array[StoryLink] = []

	for link: StoryLink in links:
		if link.from == from:
			results.append(link)

	return results


func get_links_to(to: StringName) -> Array[StoryLink]:
	var results: Array[StoryLink] = []

	for link: StoryLink in links:
		if link.to == to:
			results.append(link)

	return results


func has_link(from: StringName, to: StringName) -> bool:
	return get_link(from, to) != null
