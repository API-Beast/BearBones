class_name ShardList

var by_id = {}
var by_type = {}

func add(obj):
	by_id[obj.id] = obj
	get_by_type(obj.get_type()).append(obj)

func remove(obj):
	by_id.erase(obj.id)
	by_type[obj.get_type()].erase(obj)

func values():
	return by_id.values()

func has(id:String):
	return by_id.has(id)

func get_by_type(t:String)->Array:
	if not by_type.has(t):
		by_type[t] = []
	return by_type[t]

func _marshall_get_data():
	return {"list":by_id.values()}

func _marshall_load_data(data):
	var list = data["list"]
	for obj in list:
		add(obj)
