@tool
class_name StoryData
extends Resource

## Granular signals let views update only what changed. `changed` still fires
## for every edit (use it for dirty tracking and saving).
signal node_added(node: StoryNode)
signal node_removed(id: StringName)
signal link_added(link: StoryLink)
signal link_removed(link: StoryLink)

## The ports of this node's outgoing links were shifted or moved.
signal links_changed(node_id: StringName)

const START_NODE_ID: StringName = &'__start__'

@export var title: String = '':
	set(value):
		if title == value:
			return
		title = value
		if not resource_path.is_empty():
			emit_changed()
@export var description: String = '':
	set(value):
		if description == value:
			return
		description = value
		if not resource_path.is_empty():
			emit_changed()
@export var character_library: StoryCharacterLibrary
@export var variable_library: StoryVariableLibrary

@export_storage
var _cast: Dictionary[StringName, bool] = { }

@export_storage
var _nodes: Dictionary[StringName, StoryNode] = { }

@export_storage
var _links: Dictionary[StoryLink, Object] = { }

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
		if character_library == null:
			return []
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

var edit_revision: int:
	get:
		return _history.undo_redo.get_version()
var history: StoryHistory:
	get:
		return _history

var has_undo: bool:
	get:
		return _history.undo_redo.has_undo()

var has_redo: bool:
	get:
		return _history.undo_redo.has_redo()
var _history: StoryHistory = StoryHistory.new()


static func reload_story(path: String) -> StoryData:
	var resource: Resource = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_REPLACE)
	if resource is not StoryData:
		push_error('Failed to reload StoryData: %s' % path)
		return null

	return resource as StoryData


## ===
## Lifecycle methods
## ===
func _init() -> void:
	ensure_start_node()


func undo() -> void:
	_history.undo()


func redo() -> void:
	_history.redo()


## Group several API calls into ONE undo step.
func transact(action_name: String, build: Callable) -> void:
	_history.transact(action_name, build)


## Gives every node (including ones loaded from disk) the story's history and
## relays their changes to `changed`. Safe to call more than once.
func setup_history() -> void:
	for node: StoryNode in _nodes.values():
		node.set_history(_history)
		_track_node(node)


func ensure_start_node() -> void:
	_ensure_start()


## ===
## MUTATING Node methods
## ===
func add_node(node: StoryNode) -> bool:
	if (
		node == null or node.instance_id.is_empty()
		or has_node(node.instance_id) or node.instance_id == START_NODE_ID
	):
		return false

	node.set_history(_history)
	_history.record('Add Node', _add_node.bind(node), _remove_node.bind(node.instance_id))
	return true


func remove_node(id: StringName) -> void:
	remove_nodes([id] as Array[StringName])


func remove_nodes(ids: Array[StringName]) -> void:
	var targets: Array[StoryNode] = []
	var target_ids: Array[StringName] = []
	for id: StringName in ids:
		var node: StoryNode = get_node(id)
		if node != null and id != START_NODE_ID and id not in target_ids:
			targets.append(node)
			target_ids.append(id)
	if targets.is_empty():
		return

	var snapshot: Array[StoryLink] = [] # endpoint copies, not live objects
	for link: StoryLink in _links:
		if link.from in target_ids or link.to in target_ids:
			snapshot.append(link.duplicate())

	_history.record(
		'Remove Nodes',
		_remove_nodes.bind(target_ids),
		_restore_nodes.bind(targets, snapshot),
	)


func move_nodes(positions: Dictionary[StringName, Vector2]) -> void:
	_history.begin('Move Nodes')
	for id: StringName in positions:
		var node: StoryNode = get_node(id)
		if node != null:
			node.position = positions[id] # setter records via history
	_history.commit()


## Removes a choice, its links, and closes the gap in the node's ports, as one
## undo step. Use this instead of ChoiceNode.remove_choice() from the editor.
func remove_choice(node_id: StringName, index: int) -> void:
	var node: ChoiceNode = get_node(node_id) as ChoiceNode
	if node == null or index < 0 or index >= node.choices.size():
		push_error('Cannot remove choice %d of node "%s".' % [index, node_id])
		return

	var snapshot: Array[StoryLink] = [] # endpoint copies, not live objects
	for link: StoryLink in get_links_from_port(node_id, index):
		snapshot.append(link.duplicate())

	_history.record(
		'Remove Choice',
		_remove_choice_at.bind(node_id, index),
		_insert_choice_at.bind(node_id, index, node.choices[index], snapshot),
	)


## ===
## Non-MUTATING Node methods
## ===
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


## ===
## MUTATING Link methods
## ===
func add_link(from: StringName, to: StringName, from_port: int = 0, to_port: int = 0) -> void:
	_history.record(
		'Add Story Link',
		_add_link.bind(from, from_port, to, to_port),
		_remove_link.bind(from, from_port, to, to_port),
	)


func remove_links_from(id: StringName) -> void:
	remove_links(get_links_from(id))


func remove_links_to(id: StringName) -> void:
	remove_links(get_links_to(id))


# Remove the links provided
func remove_links(links: Array[StoryLink]) -> void:
	_history.record(
		'Remove Links',
		_remove_links.bind(links.duplicate(true)),
		_add_links.bind(links.duplicate(true)),
	)


func add_links(links: Array[StoryLink]) -> void:
	_history.record(
		'Add Links',
		_add_links.bind(links.duplicate(true)),
		_remove_links.bind(links.duplicate(true)),
	)


func remove_link(link: StoryLink) -> void:
	_history.record(
		'Remove Link',
		_remove_link.bind(link.from, link.from_port, link.to, link.to_port),
		_add_link.bind(link.from, link.from_port, link.to, link.to_port),
	)


func remove_link_from_port(from: StringName, from_port: int) -> void:
	var links_to_remove: Array[StoryLink] = get_links_from_port(from, from_port)
	remove_links(links_to_remove)


func shift_link_ports(from: StringName, removed_port: int) -> void:
	_history.record(
		'Shift Link Ports',
		_shift_link_ports.bind(from, removed_port),
		_unshift_link_ports.bind(from, removed_port),
	)


func unshift_link_ports(from: StringName, replaced_port: int) -> void:
	_history.record(
		'Unshift Link Ports',
		_unshift_link_ports.bind(from, replaced_port),
		_shift_link_ports.bind(from, replaced_port),
	)


func move_link_port(from: StringName, from_port: int, to_port: int) -> void:
	_history.record(
		'Move Link Port',
		_move_link_port.bind(from, from_port, to_port),
		_move_link_port.bind(from, to_port, from_port),
	)


## ===
## Non-MUTATING Link methods
## ===
func get_link(from_id: StringName, from_port: int, to_id: StringName, to_port: int) -> StoryLink:
	for link: StoryLink in _links:
		if (
			link.from == from_id and link.to == to_id
			and link.from_port == from_port and link.to_port == to_port
		):
			return link

	return null


func get_links() -> Array[StoryLink]:
	return link_list


func has_link(from: StringName, to: StringName, from_port: int, to_port: int) -> bool:
	return get_link(from, from_port, to, to_port) != null


func has_links() -> bool:
	return not _links.is_empty()


func get_links_from_port(from: StringName, from_port: int) -> Array[StoryLink]:
	var result: Array[StoryLink] = []

	for link: StoryLink in _links:
		if link.from == from and link.from_port == from_port:
			result.append(link)
	return result


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


## ===
## MUTATING Cast methods
## ===
func add_to_cast(character: StoryCharacter) -> void:
	_history.record(
		'Add To Cast',
		_add_to_cast.bind(character.duplicate()),
		_remove_from_cast.bind(character.duplicate()),
	)


func remove_from_cast(character: StoryCharacter) -> void:
	_history.record(
		'Remove From Cast',
		_remove_from_cast.bind(character.duplicate()),
		_add_to_cast.bind(character.duplicate()),
	)


## ===
## Non-MUTATING Cast methods
## ===
func is_in_cast(character: StoryCharacter) -> bool:
	if character == null:
		return false
	if character_library == null:
		return false
	if not character_library.has_character(character.id):
		return false
	return _cast.has(character.id)


func save() -> void:
	var error := ResourceSaver.save(self)

	if error != OK:
		push_error('Error saving story data: %s' % resource_path)
		push_error(error_string(error))


func _remove_links(links: Array[StoryLink]) -> void:
	for link: StoryLink in links:
		_remove_link(link.from, link.from_port, link.to, link.to_port)


func _add_links(links: Array[StoryLink]) -> void:
	for link: StoryLink in links:
		_add_link(link.from, link.from_port, link.to, link.to_port)


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
	start_node_resource.set_history(_history)
	_track_node(start_node_resource)


func _track_node(node: StoryNode) -> void:
	if not node.changed.is_connected(emit_changed):
		node.changed.connect(emit_changed)


func _untrack_node(node: StoryNode) -> void:
	if node.changed.is_connected(emit_changed):
		node.changed.disconnect(emit_changed)


func _add_node(node: StoryNode) -> void:
	_track_node(node)
	_nodes[node.instance_id] = node
	node_added.emit(node)
	emit_changed()


func _remove_node(id: StringName) -> void:
	var ids: Array[StringName] = [id]
	_remove_nodes(ids)


func _add_link(from_id: StringName, from_port: int, to_id: StringName, to_port: int) -> void:
	if not has_node(from_id):
		push_error('Node: %s - is not in the story.' % from_id)
		return
	if not has_node(to_id):
		push_error('Node: %s - is not in the story.' % to_id)
		return

	var existing := get_link(from_id, from_port, to_id, to_port)
	if existing != null:
		push_error('Link already exists: %s' % existing.id)
		return

	var link := StoryLink.new()
	link.from = from_id
	link.to = to_id
	link.from_port = from_port
	link.to_port = to_port

	_links[link] = null
	link_added.emit(link)
	emit_changed()


func _remove_link(from_id: StringName, from_port: int, to_id: StringName, to_port: int) -> void:
	var link := get_link(from_id, from_port, to_id, to_port)

	if link == null:
		return

	_links.erase(link)
	link_removed.emit(link)
	emit_changed()


func _shift_link_ports(from: StringName, removed_port: int) -> void:
	for link: StoryLink in _links:
		if link.from != from:
			continue

		if link.from_port > removed_port:
			link.from_port -= 1

	links_changed.emit(from)
	emit_changed()


func _unshift_link_ports(from: StringName, replaced_port: int) -> void:
	for link: StoryLink in _links:
		if link.from != from:
			continue

		if link.from_port >= replaced_port:
			link.from_port += 1

	links_changed.emit(from)
	emit_changed()


func _move_link_port(from: StringName, from_port: int, to_port: int) -> void:
	if from_port == to_port:
		return

	for link: StoryLink in get_links_from(from):
		if link.from_port == from_port:
			link.from_port = to_port
		elif from_port < to_port:
			if link.from_port > from_port and link.from_port <= to_port:
				link.from_port -= 1
		else:
			if link.from_port >= to_port and link.from_port < from_port:
				link.from_port += 1

	links_changed.emit(from)
	emit_changed()


func _add_to_cast(character: StoryCharacter) -> void:
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
	emit_changed()


func _remove_from_cast(character: StoryCharacter) -> void:
	if character == null:
		push_error('Cannot remove a null character from the cast.')
		return

	if not _cast.has(character.id):
		push_error('Character "%s" is not in the cast.' % character.id)
		return

	_cast.erase(character.id)
	emit_changed()


func _remove_nodes(ids: Array[StringName]) -> void:
	for link: StoryLink in _links.keys(): # keys() is a copy, safe to erase
		if link.from in ids or link.to in ids:
			_links.erase(link)
			link_removed.emit(link)

	for id: StringName in ids:
		var node: StoryNode = _nodes.get(id)
		if node == null or id == START_NODE_ID:
			continue

		_untrack_node(node)
		_nodes.erase(id)
		node_removed.emit(id)

	emit_changed()


func _restore_nodes(nodes: Array[StoryNode], links: Array[StoryLink]) -> void:
	for node: StoryNode in nodes:
		_track_node(node)
		_nodes[node.instance_id] = node
		node_added.emit(node)

	for link: StoryLink in links:
		_add_link(link.from, link.from_port, link.to, link.to_port)

	emit_changed()


func _remove_choice_at(node_id: StringName, index: int) -> void:
	var node: ChoiceNode = get_node(node_id) as ChoiceNode
	if node == null:
		return

	for link: StoryLink in get_links_from_port(node_id, index):
		_links.erase(link)
		link_removed.emit(link)

	_shift_link_ports(node_id, index)
	node._remove_choice(index)


func _insert_choice_at(
	node_id: StringName,
	index: int,
	text: String,
	links: Array[StoryLink],
) -> void:
	var node: ChoiceNode = get_node(node_id) as ChoiceNode
	if node == null:
		return

	node._add_choice(text, index)
	_unshift_link_ports(node_id, index)

	for link: StoryLink in links:
		_add_link(link.from, link.from_port, link.to, link.to_port)
