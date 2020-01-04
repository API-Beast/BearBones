extends Node

var actions = {}
var config = {}

var current_action = null
var queued_actions = []

func _ready():
	self.config = Config.load_config_file("user://actions.json", {})

func find_triggered_action(e):
	for name in actions.keys():
		if is_pressed(e, name):
			return name
	return null

func get_action_label(name):
	return actions[name].label

func get_action_trigger(name):
	var action = actions[name]
	var action_config = null

	if config.has(name):
		action_config = config[name]

	if action:
		var triggers = {0: action.default_primary_trigger, 1: action.default_secondary_trigger}
		if action_config:
			for binding in action_config.keys():
				var val = action_config[binding]
				if val != null:
					triggers[binding] = val
		if triggers[0]:
			return triggers[0]
		else:
			return triggers[1]

func is_pressed(e, name):
	var action = actions[name]
	var action_config = null

	if config.has(name):
		action_config = config[name]

	if action:
		var triggers = {0: action.default_primary_trigger, 1: action.default_secondary_trigger}
		if action_config:
			for binding in action_config.keys():
				var val = action_config[binding]
				if val != null:
					triggers[binding] = val
		for trigger in triggers.values():
			if trigger and trigger.is_pressed(e):
				return true

	if not action:
		printerr("No action with name ", name)

	return false

func is_held(name):
	var action = actions[name]
	var action_config = null

	if config.has(name):
		action_config = config[name]

	if action:
		var triggers = {0: action.default_primary_trigger, 1: action.default_secondary_trigger}
		if action_config:
			for binding in action_config.keys():
				var val = action_config[binding]
				if val != null:
					triggers[binding] = val
		for trigger in triggers.values():
			if trigger and trigger.is_held():
				return true

	if not action:
		printerr("No action with name ", name)

	return false

func register_action(action):
	var name = action.Name
	actions[name] = {"name":name, "action":action, "label":action.Label, "default_primary_trigger":Functions.trigger_from_array(action.DefaultPrimaryTrigger), "default_secondary_trigger":Functions.trigger_from_array(action.DefaultSecondaryTrigger)}

func register_placeholder_action(name, label, prim_trigger_default=[], sec_trigger_default=[]):
	actions[name] = {"name":name, "action":null, "label":label, "default_primary_trigger":Functions.trigger_from_array(prim_trigger_default), "default_secondary_trigger":Functions.trigger_from_array(sec_trigger_default)}

func execute_action(name, targets, pos, graph, focus = null):
	if current_action:
		abort_action()
	
	if focus == null:
		focus = targets[0]

	var action_class = actions[name].action
	if action_class:
		current_action = action_class.new()
		current_action.start(pos, targets, graph, focus)
		return true
	else:
		printerr("No action named ", name)
	return false

func queue_action(name):
	queued_actions.push_back(name)

func update_action(pos):
	if current_action:
		if current_action.is_finished():
			current_action = null
		else:
			current_action.update(pos)

func confirm_action(pos):
	if current_action:
		current_action.confirm(pos)
	current_action = null

func abort_action():
	if current_action:
		current_action.abort()
		current_action = null
		return true
	current_action = null
	return false

func save_config():
	Config.save_config_file("user://actions.json", self.config)