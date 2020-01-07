extends Object
class_name ShardStorage

var id_increment := 0
var objects:ShardList
var obsolete_objects_cache = []

var undo_stack:UndoStack = null

var undo_push_timer := 0.0
var intermediate_change := false
var modified := false
var has_shard_update := false

var read_only := false

signal on_shard_updated()
signal on_composition_change()
signal on_shard_added(shard)
signal on_shard_removed(shard)

func _init():
	undo_stack = UndoStack.new()
	undo_stack.db = self
	objects = ShardList.new()

func clear_data()->void:
	undo_stack = UndoStack.new()
	undo_stack.db = self
	objects = ShardList.new()
	obsolete_objects_cache = []

func delete_shard(shard) -> void:
	objects.remove(shard)
	obsolete_objects_cache.push_back(shard)

	for obj in objects.values():
		if obj != shard:
			obj.notify_shard_obsolete(shard, self)
	has_shard_update = true
	emit_signal("on_shard_removed", shard)
	emit_signal("on_composition_change")

func on_shard_updated(reason, shard):
	has_shard_update = true
	for obj in objects.values():
		if obj != shard:
			obj.notify_shard_update(shard, self)
	if shard.was_modified():
		intermediate_change = true
		dirty_cache()

func generate_id(prefix := "") -> String:
	id_increment += 1
	var id = prefix + ("%04X" % id_increment)
	if objects.by_id.has(id):
		id = generate_id(prefix)
	return id

func shards_by_type(t:String) -> Array:
	return objects.get_by_type(t)

func store_by_id(obj):
	objects.add(obj)

	obj.parent = self
	obj.connect("was_updated", self, "on_shard_updated", [obj])
	obj.connect("marked_as_obsolete", self, "delete_shard", [obj])
	has_shard_update = true
	emit_signal("on_shard_added", obj)
	emit_signal("on_composition_change")

	return obj

func store_shard(obj):
	var id = generate_id(obj.get_id_prefix())
	obj.id = id
	store_by_id(obj)

	dirty_cache()
	obj.update_values(self)
	return obj

func has_id(id:String)->bool:
	return objects.by_id.has(id)

func get_shard_by_id(id:String):
	if objects.by_id.has(id):
		return objects.by_id[id]
	else:
		return null

func mark_id_as_obsolete(id:String)->void:
	if objects.has(id):
		delete_shard(objects.by_id[id])

func dirty_cache()->void:
	modified = true

### Undo Things

func undo()->void:
	if intermediate_change:
		push_undo(tr("Tweak Properties"))
	undo_stack.undo()
	finalize_state()

func redo()->void:
	undo_stack.redo()
	finalize_state()

func finalize_state()->void:
	for obj in objects.values():
		obj.undo_imprint = obj.create_imprint(false)
	obsolete_objects_cache = []

func _process(dt:float)->void:
	if has_shard_update:
		emit_signal("on_shard_updated")
		has_shard_update = false

	for obj in objects.values():
		obj.process_signals()
	if undo_push_timer > 0.0:
		if Actions.current_action:
			undo_push_timer = 0.0
		else:
			undo_push_timer -= dt
			if undo_push_timer < 0.0:
				push_undo(tr("Tweak Properties"))

func push_undo(name:String)->void:
	var changed_objects = []
	for obj in objects.values():
		if obj.has_method("was_modified") and obj.was_modified():
			changed_objects.push_back(obj)
	
	if changed_objects.size() == 0 and obsolete_objects_cache.size() == 0:
		return
	
	var ids = []
	var old_states = []
	var new_states = []

	var buffer_size = changed_objects.size() + obsolete_objects_cache.size()
	
	ids.resize(buffer_size)
	old_states.resize(buffer_size)
	new_states.resize(buffer_size)
	
	var i = 0
	
	for obj in changed_objects:
		ids[i] = obj.id
		old_states[i] = obj.get_undo_imprint()
		new_states[i] = obj.store_new_imprint()
		i += 1
	
	for obj in obsolete_objects_cache:
		if not obj.id in ids:
			ids[i] = obj.id
			old_states[i] = obj.store_new_imprint()
			new_states[i] = {}
			i += 1
	
	obsolete_objects_cache = []
	undo_stack.push(name, ids, old_states, new_states)

	undo_push_timer = 0.0
	intermediate_change = false
	
func start_undo_push_timer()->void:
	if intermediate_change:
		undo_push_timer = 1.5
	intermediate_change = false

func apply_imprint(id:String, imprint:Dictionary)->void:
	var obj = null
	if objects.has(id):
		obj = objects.by_id[id]
	if not obj or obj.obsolete:
		printerr("\t\t", id, " doesn't exist.")
		return
		
	obj.apply_imprint(imprint)
	obj.update("undo_redo")

func create_from_imprint(id:String, imprint:Dictionary)->void:
	var obj = null

	if objects.has(id):
		obj = objects.by_id[id]
		if obj and not obj.obsolete:
			printerr("\t\t", id, " still exists.")
			return
	
	var script = imprint.type
	obj = script.new()
	obj.apply_imprint(imprint)
	store_by_id(obj)
	obj.update("undo_redo")