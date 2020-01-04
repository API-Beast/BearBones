extends MarginContainer

const Item = preload("res://Autoload/Dialogs/Config/ActionsItem.tscn")

var config = {}
var items = {}

func _ready():
	self.config = Functions.deep_copy(Actions.config)
	build_entries()

func build_entries():
	for item in items.values():
		item.free()
	items = {}

	for action in Actions.actions.values():
		var node = Item.instance()
		$Items.add_child(node)

		node.set_action(action)

		var targets = ["0", "1", "2"]
		if config.has(action.name):
			for key in config[action.name].keys():
				if key in targets:
					node.set_trigger(int(key), config[action.name][key])
		items[action.name] = node

func assign(new_trigger, action, target=0):
	if not config.has(action):
		config[action] = {}
	config[action][str(target)] = new_trigger
	items[action].set_trigger(target, new_trigger)

func was_modified():
	return Actions.config.hash() != self.config.hash()

func save_data():
	Actions.config = Functions.deep_copy(self.config)
	Actions.save_config()

func reset():
	self.config = {}
	build_entries()