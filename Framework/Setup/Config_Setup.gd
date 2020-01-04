extends Node

func _init():
	var general = {}
	general.autosaves_enabled = true
	general.autosave_timer = 5
	general.num_autosaves = 15
	general.always_redraw = false

	Config.defaults["user://config.json"] = general