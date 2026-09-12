class_name StoryData
extends Resource

@export var title: String = ''
@export var description: String = ''

var nodes: Array[StoryNode] = []

var links: Dictionary[StoryLink, Object] = { }


func add_link(from: StringName, to: StringName) -> StoryLink:
	var link := StoryLink.new(from, to)

	links[link] = null

	return link


func remove_link(link: StoryLink) -> void:
	links.erase(link)


func get_link(from: StringName, to: StringName) -> StoryLink:
	for link: StoryLink in links:
		if link.from == from and link.to == to:
			return link

	return null


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


func get_node(id: StringName) -> StoryNode:
	for node: StoryNode in nodes:
		if node.id == id:
			return node

	return null


func has_node(id: StringName) -> bool:
	return get_node(id) != null


func remove_node(id: StringName) -> void:
	for link: StoryLink in links.keys():
		if link.from == id or link.to == id:
			remove_link(link)

	for node: StoryNode in nodes:
		if node.id == id:
			nodes.erase(node)
			return
