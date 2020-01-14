extends Resource
class_name Shard

export var id := ""
var queued_update = null
var obsolete := false
var parent:ShardStorage = null

signal was_updated(reason)
signal marked_as_obsolete()

func update(reason:="general_update")->void:
	queued_update = reason

func notify_shard_update(obj, parent): pass
func notify_shard_obsolete(obj, parent): pass
func mark_as_obsolete()->void:
	obsolete = true
	emit_signal("marked_as_obsolete")

func process_signals()->void:
	if queued_update:
		emit_signal("was_updated", queued_update)
		queued_update = null

func update_values(parent):
	pass

func get_type() -> String:
	return "Shard"

func get_id_prefix() -> String:
	return "S"

func is_valid() -> bool:
	return true

func sanitize():
	pass

# Tracking
var undo_imprint         := {}
var universal_imprint    := {}

# var tempoary_imprint     := {}
# var use_tempoary_imprint := false

# func _get(property):
# 	if use_tempoary_imprint:
# 		if tempoary_imprint.has(property):
# 			return tempoary_imprint[property]
# 	return self.get(property)

# func _set(property, value):
# 	if use_tempoary_imprint:
# 		tempoary_imprint[property] = value
# 	else:
# 		self.set(property, value)

func store_new_imprint()->Dictionary:
	undo_imprint = create_imprint()
	universal_imprint = create_imprint(true)
	return undo_imprint

func get_undo_imprint()->Dictionary:
	return undo_imprint

func create_imprint(universal=false)->Dictionary:
	var result = {}
	if universal:
		for p in get_property_list():
			if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_STORAGE:
				result[p.name] = Functions.clone(self.get(p.name))
	else:
		for name in get_undo_properties():
			result[name] = Functions.clone(self.get(name))
	result.type = self.get_script()
	return result

func apply_imprint(new_imprint)->void:
	for name in get_undo_properties():
		if new_imprint.has(name):
			self.set(name, new_imprint[name])
	sanitize()

func apply_universal_imprint(imprint)->void:
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_STORAGE:
			if imprint.has(p.name):
				self.set(p.name, imprint[p.name])

func was_modified():
	if undo_imprint.empty():
		return true
		
	for name in get_undo_properties():
		if undo_imprint.has(name):
			if typeof(undo_imprint[name]) != typeof(get(name)) or undo_imprint[name] != get(name):
				return true
	return false

func was_property_modified(prop):
	if universal_imprint.empty():
		return true
	
	if universal_imprint.has(prop):
		if universal_imprint[prop] != get(prop):
			return true

	return false

func get_undo_properties():
	return []