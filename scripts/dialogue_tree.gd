class_name DialogueTree
extends RefCounted

## Branching dialogue system for NPC conversations.
##
## Usage:
##   var tree := DialogueTree.new()
##   tree.add_node("start", "TIBBIT", "What brings you to the harbor?")
##   tree.add_choice("start", "Ask about relic", "relic_q")
##   tree.add_choice("start", "Ask about Pindle", "pindle_q")
##   tree.add_node("relic_q", "TIBBIT", "Ancient thing. Probably dangerous.")
##   tree.add_node("pindle_q", "TIBBIT", "Small man. Big stamp.")
##   await room.run_dialogue_tree(tree)

## A single dialogue node
class DialogueNode:
	var id: String
	var speaker: String
	var text: String
	var choices: Array[DialogueChoice] = []
	var next_id: String = ""  # Auto-advance to this node (if no choices)
	var on_enter_flag: String = ""  # Flag to set when this node is reached
	var on_enter_item: String = ""  # Item to give when this node is reached
	var condition_flag: String = ""  # Only show if this flag is set
	var condition_not_flag: String = ""  # Only show if this flag is NOT set

## A choice the player can select
class DialogueChoice:
	var label: String
	var target_id: String
	var condition_flag: String = ""  # Only show if flag is set
	var condition_not_flag: String = ""  # Only show if flag is NOT set
	var set_flag: String = ""  # Flag to set when chosen

var nodes: Dictionary = {}  # id -> DialogueNode
var start_id: String = "start"

func add_node(id: String, speaker: String, text: String, next_id: String = "") -> DialogueTree:
	var node := DialogueNode.new()
	node.id = id
	node.speaker = speaker
	node.text = text
	node.next_id = next_id
	nodes[id] = node
	if nodes.size() == 1:
		start_id = id
	return self

func add_choice(node_id: String, label: String, target_id: String,
		condition_flag: String = "", condition_not_flag: String = "",
		set_flag: String = "") -> DialogueTree:
	if node_id not in nodes:
		return self
	var choice := DialogueChoice.new()
	choice.label = label
	choice.target_id = target_id
	choice.condition_flag = condition_flag
	choice.condition_not_flag = condition_not_flag
	choice.set_flag = set_flag
	nodes[node_id].choices.append(choice)
	return self

func set_node_flag(node_id: String, flag: String) -> DialogueTree:
	if node_id in nodes:
		nodes[node_id].on_enter_flag = flag
	return self

func set_node_item(node_id: String, item: String) -> DialogueTree:
	if node_id in nodes:
		nodes[node_id].on_enter_item = item
	return self

func set_node_condition(node_id: String, flag: String = "", not_flag: String = "") -> DialogueTree:
	if node_id in nodes:
		nodes[node_id].condition_flag = flag
		nodes[node_id].condition_not_flag = not_flag
	return self

func get_available_choices(node_id: String) -> Array[DialogueChoice]:
	if node_id not in nodes:
		return []
	var result: Array[DialogueChoice] = []
	for choice in nodes[node_id].choices:
		if choice.condition_flag != "" and not GameState.has_flag(choice.condition_flag):
			continue
		if choice.condition_not_flag != "" and GameState.has_flag(choice.condition_not_flag):
			continue
		result.append(choice)
	return result
