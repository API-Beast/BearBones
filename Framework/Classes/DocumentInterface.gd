extends ShardStorage
class_name DocumentInterface

var id := ""
var filepath := ""
var users := 0
var export_options := {}
var old_path_root := ""

signal invalidate
signal on_settings_update()

func _init():
	id = str(OS.get_unix_time())+str(randi())

func update_settings():
	emit_signal("on_settings_update")

func get_export_options(id):
	if not export_options.has(id):
		export_options[id] = {}
	return export_options[id]

func set_export_options(id, new_options):
	export_options[id] = new_options

func get_path_root() -> String:
	var basedir = filepath.get_base_dir()
	if basedir == "":
		basedir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS )
	return basedir

func find_file(path) -> String:
	if old_path_root.empty():
		return path
		
	var file = File.new()
	if file.file_exists(path):
		return path

	if path.is_rel_path():
		var abs_path = get_path_root().plus_file(path)
		if file.file_exists(abs_path):
			return abs_path
		return path
	else:
		var rel_path = path
		var root = old_path_root
		if not root.ends_with("/"):
			root += "/"
	
		root = root.replace("\\", "/")
		rel_path = rel_path.replace("\\", "/")
	
		if rel_path.begins_with(root):
			if OS.get_name() == "Windows":
				rel_path = rel_path.replacen(root, "")
			else:
				rel_path = rel_path.replace(root, "")
			var new_path = get_path_root().plus_file(rel_path)
			return new_path
		else:
			return rel_path
			
func open(path:String)->bool:
	return false
	
func get_data(include_session_data:=false)->Dictionary:
	return Serializer.serialize(self)
	
func load_data(content:Dictionary)->void:
	Serializer.load_data_into_obj(self, content)

func _marshall_load_data_post(version, data):
	for obj in objects.by_id.values():
		obj.parent = self

func get_export_suffix() -> String:
	return filepath.get_basename().get_file()

func _process(dt:float)->void:
	._process(dt)

func get_file_type() -> String:
	return "file"

func incr_users() -> void:
	users += 1

func decr_users() -> void:
	users -= 1

func is_file_loaded(file:String) -> bool:
	return false

func get_name():
	if filepath:
		return filepath.get_file()
	else:
		return "Unamed"