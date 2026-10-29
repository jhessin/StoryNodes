class_name StoryRuntime
extends Control
## Drop-in scene that plays a StoryData: shows each line of dialogue, builds a
## button for every choice and carries on until the story ends.
##
## Quick start:
##   1. Add story_runtime.tscn to your scene and assign `story`.
##   2. Leave `start_on_ready` on, or call start_story().
##   3. Connect to the signals below to react to the story from your game.
##
## All stepping logic lives in StoryExecution, so you can also skip this scene
## and drive a StoryExecution from your own UI.

signal story_started
signal story_ended
signal dialogue_shown(character: StoryCharacter, text: String, node: DialogueNode)
signal choices_shown(choices: Array[String], node: ChoiceNode)
signal variable_changed(variable_name: StringName, value: Variant)

## The story to play.
@export var story: StoryData
## Start playing as soon as the scene is ready.
@export var start_on_ready: bool = true
## Hide the whole scene while no story is running.
@export var hide_when_inactive: bool = true
## Text of the button for lines that have something after them.
@export var continue_text: String = '->'
## Text of the button for the last line of a story.
@export var end_text: String = 'Goodbye'

## The execution currently playing, or null before start_story() is called.
var execution: StoryExecution:
	get:
		return _execution

## True while a story is running (including while it waits for input).
var is_running: bool:
	get:
		return (
			_execution != null and _execution.state != StoryExecution.State.IDLE
			and _execution.state != StoryExecution.State.ENDED
		)

var _execution: StoryExecution

@onready var character_image: TextureRect = %CharacterImage
@onready var title_label: Label = %TitleLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)

	_clear_ui()

	if start_on_ready and story != null:
		start_story()
	elif hide_when_inactive:
		hide()


## Plays `data` from the beginning, or `story` when no data is given.
## Variables start from the variable library defaults on every call.
func start_story(data: StoryData = null) -> void:
	if data != null:
		story = data

	if story == null:
		push_error('StoryRuntime has no story to play.')
		return

	if not is_node_ready():
		await ready

	_clear_ui()
	show()

	_execution = StoryExecution.new(story)
	_execution.story_started.connect(story_started.emit)
	_execution.story_ended.connect(_on_story_ended)
	_execution.dialogue_shown.connect(_on_dialogue_shown)
	_execution.choices_shown.connect(_on_choices_shown)
	_execution.variable_changed.connect(variable_changed.emit)
	_execution.start()


## Stops the story where it is without emitting story_ended.
func stop_story() -> void:
	_execution = null
	_clear_ui()

	if hide_when_inactive:
		hide()


## Reads a story variable; returns null when nothing is running.
func get_variable(variable_name: StringName) -> Variant:
	if _execution == null:
		return null

	return _execution.get_variable(variable_name)


## Changes a story variable while the story runs, for example to pass in
## game state. Unknown variables are ignored.
func set_variable(variable_name: StringName, value: Variant) -> void:
	if _execution != null:
		_execution.set_variable(variable_name, value)


func _on_dialogue_shown(character: StoryCharacter, text: String, node: DialogueNode) -> void:
	_clear_choices()

	_show_speaker(character)
	description_label.text = text

	var has_next: bool = _execution.story.has_next_nodes(node.instance_id)
	continue_button.text = continue_text if has_next else end_text
	continue_button.show()
	continue_button.grab_focus()

	dialogue_shown.emit(character, text, node)


func _on_choices_shown(choices: Array[String], node: ChoiceNode) -> void:
	_clear_choices()

	continue_button.hide()

	for index: int in choices.size():
		var button: Button = Button.new()
		button.text = choices[index]
		button.pressed.connect(_on_choice_pressed.bind(index))
		choices_container.add_child(button)

	if choices_container.get_child_count() > 0:
		(choices_container.get_child(0) as Button).grab_focus()

	choices_shown.emit(choices, node)


func _on_continue_pressed() -> void:
	if _execution != null:
		_execution.advance()


func _on_choice_pressed(index: int) -> void:
	if _execution == null:
		return

	# Clear first: choose() runs on synchronously and may show the next choices.
	_clear_choices()
	_execution.choose(index)


func _on_story_ended() -> void:
	_clear_ui()

	if hide_when_inactive:
		hide()

	story_ended.emit()


func _show_speaker(character: StoryCharacter) -> void:
	if character == null:
		print('No character assigned to dialogue')
		character_image.hide()
		title_label.hide()
		title_label.remove_theme_color_override('font_color')
		return

	print('Character name: %s' % character.name)
	character_image.texture = character.image
	character_image.show()
	title_label.text = character.name
	title_label.add_theme_color_override('font_color', character.color)
	title_label.show()


func _clear_choices() -> void:
	for child: Node in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()


func _clear_ui() -> void:
	_clear_choices()

	title_label.text = ''
	title_label.hide()
	description_label.text = ''
	continue_button.hide()
