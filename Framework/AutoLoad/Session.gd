extends Node

var data = {}
var temp_data = {}
var autosave_timer = null
var time_since_last_autosave = 0.0

var session_dir =  "user://session/Alpha"
var import_dirs =  []

signal before_session_save()

static func sort_time(a, b):
	if a[1] > b[1]:
		return true
	return false

func _enter_tree():
	get_tree().set_auto_accept_quit(false)

func _ready():
	print("User directory: ", OS.get_user_data_dir())

	var cfg = Config.get_config("user://config.json")
	if Config.get_value("user://config.json", "autosaves_enabled"):
		autosave_timer = Config.get_value("user://config.json", "autosave_timer") * 60

	var folder = Directory.new()
	if folder.dir_exists(session_dir):
		folder.open(session_dir)
		print("Loading session data from current version: ", session_dir)
	else:
		# Create folder for saving
		var imported = false
		# Import from old versions instead
		for dir in import_dirs:
			if folder.dir_exists(dir):
				folder.open(dir)
				print("Importing session data from old version: ", dir)
				imported = true
				break
		
		if not imported:
			print("No compatible old session data found.")
			return

	var FileClass = File.new() # get_modified_time is not static for some reason
	var files = []
	folder.list_dir_begin(true, true)
	while true:
		var next_file = folder.get_next()
		var cur_file = folder.get_current_dir().plus_file(next_file)
		if next_file.empty():
			break
		if not cur_file.ends_with(".clrsession"):
			continue

		var time = FileClass.get_modified_time(cur_file)
		files.push_back([cur_file, time])

	files.sort_custom(self, "sort_time")

	if files.size() < 1:
		return

	var file = Serializer.BlockFileReader.new()
	for newest_file in files:
		if file.open(newest_file[0]) == OK:
			print("Loading session-file: ", newest_file[0])
			break

	var num_docs = 0
	if file.error_code == OK:
		while true:
			var sector = file.next_sector()
			if sector == null:
				break
			match sector:
				"STORAGE":
					data = file.read_json_sector()
				"SESSION":
					temp_data = file.read_json_sector()
				"DOCUMENT":
					var val = file.read_json_sector()
					if not val:
						printerr("Can't load document")
					else:
						App.add_doc(val)
						num_docs += 1
				_:
					printerr("Skipping unknown file sector ", sector)
		file.close()
		print("Loaded ", num_docs, " documents from session data")
		Serializer.dump_migration_stats()

	var num_auto_saves = Config.get_value("user://config.json", "num_autosaves")
	if files.size() > num_auto_saves:
		print("Deleting old auto-saves.")
		while files.size() > num_auto_saves:
			var oldest_file = files.pop_back()[0]
			folder.remove(oldest_file)

func _process(delta):
	time_since_last_autosave += delta
	if autosave_timer != null:
		if autosave_timer < time_since_last_autosave:
			var date = OS.get_datetime()
			save_session("autosave_{month}_{day}_{hour}_{minute}.clrsession".format(date))
			time_since_last_autosave = 0.0

func save_session(path):
	if path.is_rel_path():
		path = session_dir.plus_file(path)

		var folder = Directory.new()
		if not folder.dir_exists(session_dir):
			folder.make_dir_recursive(session_dir)
	
	emit_signal("before_session_save")
	var sess_data = {}
	for obj in get_tree().get_nodes_in_group("session_data"):
		var result = obj.call("get_session_data")
		if result:
			for key in result.keys():
				sess_data[key] = Serializer.serialize(result[key])

	print("Saving ", path)

	var file = Serializer.BlockFileWriter.new()
	file.open(path)
	file.write_header()
	file.write_json_sector("STORAGE", data)
	file.write_json_sector("SESSION", sess_data)
	for doc in App.open_docs:
		if doc.users > 0:
			doc.push_undo(tr("Save Session Data"))
			file.write_json_sector("DOCUMENT", doc.get_data())
	file.close()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if Jobs.current_jobs.size():
			var node = preload("res://Widgets/Dialog/WaitForTask.tscn").instance()
			Dialog.queue_dialog(node)
			yield(Jobs, "all_jobs_finished")
		var date = OS.get_datetime()
		save_session("exit_{month}_{day}_{hour}_{minute}.clrsession".format(date))
		get_tree().quit()

func store(path, value):
	data[path] = Serializer.serialize(value)

func recover(path, def_value = null):
	if temp_data.has(path):
		return Serializer.deserialize(temp_data[path])
	elif data.has(path):
		return Serializer.deserialize(data[path])
	else:
		return def_value