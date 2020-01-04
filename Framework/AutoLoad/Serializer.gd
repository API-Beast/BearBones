extends Node

class BlockFileReader:
	var file := File.new()
	var error_code := FAILED

	func open(path:String)->int:
		error_code = file.open(path, File.READ)
		return error_code
	
	func close()->void:
		if error_code == OK:
			file.close()

	var sector_start := 0
	var sector_length := 0
	var sector_end := 0

	func find_sector(name:String)->bool:
		if error_code != OK:
			return false

		file.seek(0)
		while true:
			var sector = next_sector()
			if sector == name:
				return true
			if sector == null:
				return false
		return false

	func next_sector():
		if error_code != OK:
			return null

		while not file.eof_reached():
			var line := file.get_line()
			if line.begins_with("SECTION "):
				var parts := line.split(" ", false, 2)
				var skip_ahead := 0
				if parts.size() == 3:
					skip_ahead = parts[2].to_int()

				sector_start = file.get_position()
				sector_end = sector_start + skip_ahead

				file.seek(sector_end)
				while not file.eof_reached():
					var old_pos = file.get_position()
					if file.get_line().begins_with("SECTION "):
						file.seek(old_pos)
						break
				sector_end = file.get_position()

				sector_length = sector_end - sector_start
				return parts[1]
		return null

	func read_sector_as_buffer()->PoolByteArray:
		file.seek(sector_start)
		return file.get_buffer(sector_length)

	func read_sector_as_string()->String:
		return read_sector_as_buffer().get_string_from_utf8()
	
	func read_json_sector():
		var text := read_sector_as_string()
		var json = JSON.parse(text)
		if json == null:
			json = {}
		return Serializer.deserialize(json.result)

class BlockFileWriter:
	var file := File.new()
	var error_code := FAILED

	func open(path:String)->int:
		error_code = file.open(path, File.WRITE)
		return error_code
	
	func close()->void:
		if error_code == OK:
			file.close()

	func write_header(header:="AMBIGIOUS CONTAINER v1.0")->void:
		file.seek(0)
		file.store_line(header)
	
	func write_binary_sector(name:String, data:PoolByteArray)->void:
		file.store_line("SECTION "+name+" "+str(data.size()))
		file.store_buffer(data)
		file.store_string("\n")

	func write_text_sector(name:String, text:String)->void:
		var data = text.to_utf8()
		write_binary_sector(name, data)

	func write_json_sector(name:String, val)->void:
		var data = JSON.print(Serializer.serialize(val), " ", false).to_utf8()
		write_binary_sector(name, data)

var type_db := {}
var name_db := {}

func register_type(name:String, type)->void:
	if type_db.has(name):
		printerr("Serializer FIXME: Duplicate registration for type ", name)
	type_db[name] = type
	name_db[type] = name

func has_registry_for(val)->bool:
	return name_db.has(val.get_script())

func get_type_name_for(val)->String:
	if name_db.has(val.get_script()):
		return name_db[val.get_script()]
	return "TypeNotFound"

func get_type_name(type)->String:
	if name_db.has(type):
		return name_db[type]
	return "TypeNotFound"

class NoValue:
	func _init(): pass

var no_value := NoValue.new()

func is_no_value(val)->bool:
	if typeof(val) == TYPE_OBJECT:
		if val == no_value:
			return true
	return false

var migration_stats := {}

func dump_migration_stats():
	for stat in migration_stats.keys():
		print("> Migrated ", migration_stats[stat], " ", stat)
	migration_stats = {}

func transfer_obj_data(target, source):
	var data := {}
	if typeof(source) == TYPE_OBJECT:
		data = get_obj_data(source)
	else:
		data = source

	load_data_into_obj(target, data)
	return target

func get_obj_data(obj)->Dictionary:
	var data := {}
	if obj.has_method("_marshall_get_data"):
		data = obj._marshall_get_data()
	else:
		var properties = []
		if obj.has_method("_marshall_properties"):
			properties = obj._marshall_properties()
		else:
			for p in obj.get_property_list():
				if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and (p.usage & PROPERTY_USAGE_STORAGE):
					properties.push_back(p.name)
		for p in properties:
			data[p] = obj.get(p)
	return data

func load_data_into_obj(obj, data:Dictionary):
	var version := 0
	if data.has("_v"):
		version = data["_v"]
		
	var current_version := 0
	if obj.has_method("_marshall_version"):
		current_version = obj._marshall_version()
	if version != current_version:
		data = obj._marshall_migrate(version, data)

		var stat = str(get_type_name_for(obj), " v", version, " to v", current_version)
		if not migration_stats.has(stat):
			migration_stats[stat] = 0
		migration_stats[stat] += 1

	for key in data.keys():
		data[key] = deserialize(data[key])

	if obj.has_method("_marshall_load_data"):
		obj._marshall_load_data(data)
	else:
		var properties = []
		if obj.has_method("_marshall_properties"):
			properties = obj._marshall_properties()
		else:
			for p in obj.get_property_list():
				if p.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE):
					properties.push_back(p.name)
		for p in properties:
			if data.has(p):
				obj.set(p, data[p])
	if obj.has_method("_marshall_load_data_post"):
		obj._marshall_load_data_post(version, data)
	return obj

func serialize(val):
	match typeof(val):
		TYPE_COLOR:
			return {"_t":"Color", "value":[val.r, val.g, val.b, val.a]}
		TYPE_VECTOR2:
			return {"_t":"Vector2", "value":[val.x, val.y]}
		TYPE_VECTOR3:
			return {"_t":"Vector3", "value":[val.x, val.y, val.z]}
		TYPE_RECT2:
			return {"_t":"Rect2", "value":[val.position.x, val.position.y, val.size.x, val.size.y]}
		TYPE_ARRAY, TYPE_COLOR_ARRAY, TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY, TYPE_STRING_ARRAY, TYPE_INT_ARRAY, TYPE_RAW_ARRAY, TYPE_REAL_ARRAY:
			var ret = []
			ret.resize(val.size())
			for i in range(val.size()):
				ret[i] = serialize(val[i])
			return ret
		TYPE_DICTIONARY:
			var ret = {}
			for key in val.keys():
				ret[key] = serialize(val[key])
			return ret
		TYPE_OBJECT:
			if name_db.has(val):
				return {"_t":"TypeRef", "ref":name_db[val]}

			if not name_db.has(val.get_script()):
				printerr("No type registered for ", val)
				return null
			
			var data = get_obj_data(val)
			var typename = name_db[val.get_script()]
			var version = 0
			if val.has_method("_marshall_version"):
				version = val._marshall_version()

			var ret = {"_t": typename, "_v": version}
			for key in data.keys():
				ret[key] = serialize(data[key])

			return ret
		_:
			return val

func deserialize(data):
	if typeof(data) != TYPE_DICTIONARY:
		if typeof(data) == TYPE_REAL:
			if data == round(data):
				return int(data)
		if typeof(data) == TYPE_ARRAY:
			var ret = []
			for val in data:
				var retVal = deserialize(val)
				if not is_no_value(retVal):
					ret.push_back(retVal)
			return ret
		return data

	if not data.has("_t"):
		var ret = {}
		for key in data.keys():
			var retVal = deserialize(data[key])
			if not is_no_value(retVal):
				ret[key] = retVal
		return ret

	
	var type = data["_t"]
	var val = []
	if data.has("value"):
		val = data["value"]
	match type:
		"Color": return Color(val[0], val[1], val[2], val[3])
		"Vector2": return Vector2(val[0], val[1])
		"Vector3": return Vector3(val[0], val[1], val[2])
		"Rect2": return Rect2(val[0], val[1], val[2], val[3])
		"TypeRef": return type_db[data["ref"]]
		_: pass
	
	if not type_db.has(type):
		printerr("No type registered with name ", type, ". Skipping value.")
		return no_value

	var t = type_db[type]
	var obj = t.new()

	load_data_into_obj(obj, data)

	return obj