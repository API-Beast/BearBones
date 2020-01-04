extends Node

var global_config := {}
var defaults := {}

signal config_updated(path)

func save_config_file(path, data:Dictionary)->void:
	var file_ptr := File.new()
	file_ptr.open(path, File.WRITE)
	var json := JSON.print(Serializer.serialize(data), " ", false).to_utf8()
	file_ptr.store_buffer(json)
	file_ptr.close()
	print("Saving ", path)

func load_config_file(path, default=null):
	var file_ptr = File.new()
	if file_ptr.file_exists(path):
		file_ptr.open(path, File.READ)
		var data = file_ptr.get_buffer(file_ptr.get_len()).get_string_from_utf8()
		file_ptr.close()
		var json = JSON.parse(data)
		if json.error:
			printerr("Config: Error parsing ", path, ": ", json.error_string)
			print("Config: Using default configuration.")
			return default
		print("Config: ", path, " loaded.")
		return Serializer.deserialize(json.result)
	else:
		print("Config: ", path, " doesn't exist, using default configuration.")
		return default

func get_config(path):
	if not global_config.has(path):
		var cfg = load_config_file(path, {})

		if defaults.has(path):
			var default = defaults[path]
			for key in cfg.keys():
				if not default.has(key):
					printerr("Config FIXME: Config key ", key, " has no default in ",  path, ".")
			for key in default.keys():
				if not cfg.has(key):
					cfg[key] = default[key]
		else:
			printerr("Config FIXME: No defaults found for ", path)

		global_config[path] = cfg
		emit_signal("config_updated", path)
	return global_config[path]

func set_config(path, new_config):
	global_config[path] = new_config
	save_config_file(path, new_config)
	emit_signal("config_updated", path)

func get_defaults(path):
	return defaults[path]

func get_value(path, key):
	var cfg = get_config(path)
	return cfg[key]