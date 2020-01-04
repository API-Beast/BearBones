extends Node

class FileType:
	var mime := ""
	var name := ""
	var features = []
	var extensions = []
	var internal_type = null

class Routine:
	var internal_type = null
	var target_type = null # only used for conversion routines
	var mime_type := ""
	var target = null
	var function := ""

	func call_routine(input):
		if target == null:
			input.call(function)
		else:
			target.call(function, input)

var mime_types = {}
var type_to_mime_map = {}
var import_routines = {}
var export_routines = {}
var conversion_routines = {}

func register_type(mime:String, name:String, internal_type, features:Array = [], extensions = [])->void:
	var new_type = FileType.new()
	new_type.mime = mime
	new_type.name = name
	new_type.features = features.duplicate()
	new_type.extensions = extensions.duplicate()
	new_type.internal_type = internal_type

	mime_types[mime] = new_type
	type_to_mime_map[internal_type] = mime

func add_feature(mime:String, feature:String)->void:
	if mime_types[mime].features.has(feature):
		return
	mime_types[mime].features.push_back(feature)

func add_conversion_routine(from_type, to_type, target, fn:String)->void:
	var routine = Routine.new()
	routine.internal_type = from_type
	routine.target_type = to_type
	routine.target = target
	routine.function = fn

	if has_conversion_routine(from_type, to_type):
		printerr("FileRouter Warning: Duplicate conversion routine for converting ", Serializer.get_type_name(from_type), " to ", Serializer.get_type_name(to_type))

	if conversion_routines.has(from_type):
		conversion_routines[from_type][to_type] = routine
	else:
		conversion_routines[from_type] = {to_type:routine}

func add_export_routine(mime, type, target, fn:String)->void:
	var routine = Routine.new()
	routine.internal_type = type
	routine.mime_type = mime
	routine.target = target
	routine.function = fn

	if has_export_routine(type, mime):
		printerr("FileRouter Warning: Duplicate export routine for exporting ", Serializer.get_type_name(type), " as ", mime)

	if export_routines.has(type):
		export_routines[type][mime] = routine
	else:
		export_routines[type] = {mime:routine}

func add_import_routine(mime, type, target, fn:String)->void:
	var routine = Routine.new()
	routine.internal_type = type
	routine.mime_type = mime
	routine.target = target
	routine.function = fn

	if import_routines.has(mime):
		import_routines[mime][type] = routine
	else:
		import_routines[mime] = {type:routine}

func get_mime_types_with_features(needed_features:Array)->Array:
	var viable_types = []
	for type in mime_types.values():
		var viable = true
		for feature in needed_features:
			if not type.features.has(feature):
				viable = false
				break
		if viable:
			viable_types.push_back(type)
	return viable_types

func get_exportable_as(type)->Array:
	return []

func get_importable_as(type)->Array:
	return []

func generate_filter(types:Array)->Array:
	return []

func path_deduce_mime_type(path:String)->String:
	for type in mime_types.values():
		for extension in type.extensions:
			if path.match(extension):
				return type
	return "auto"

func has_conversion_routine(from, to)->bool:
	if conversion_routines.has(from):
		return conversion_routines[from].has(to)
	return false

func has_export_routine(internal_type, mime_type)->bool:
	if export_routines.has(internal_type):
		return export_routines[internal_type].has(mime_type)
	return false

func import(path:String, mime:="auto"):
	if mime == "auto":
		mime = path_deduce_mime_type(path)
	return import_as(path, mime_types[mime].internal_type, mime)

func import_as(path:String, type, mime:="auto"):
	var routine = null
	if mime == "auto":
		mime = path_deduce_mime_type(path)

	var routines = import_routines[mime]
	if routines.has(type):
		routine = routines[type]
	else:
		for possible_type in routines.keys():
			if has_conversion_routine(possible_type, type):
				routine = routines[possible_type]
	
	var retVal = routine.call_routine(path)
	if routine.internal_type != type:
		return convert(retVal, type)
	return retVal

func export(obj, path:String, mime:="auto"):
	var type = obj.get_script()
	if mime == "auto":
		mime = path_deduce_mime_type(path)
	if mime == "auto":
		mime = type_to_mime_map[type]

	if has_export_routine(type, mime):
		return export_as(obj, type, path, mime)

	if has_export_routine(type, mime_types[mime].internal_type):
		return export_as(obj, mime_types[mime].internal_type, path, mime)
	
	printerr("FileRouter Error: Can't export object of type ", Serializer.get_type_name(type), " to file with mimetype ", mime)

func export_as(obj, type, path:String, mime:String):
	if obj.get_script() != type:
		obj = convert(obj, type)
	
	var routine = export_routines[type][mime]
	routine.call_routine(obj)

func convert(obj, target_type):
	pass