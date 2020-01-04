extends Reference
class_name UndoStack

var buffer = null
var db = null

class UndoRingBuffer:
	var size = 256
	var data = []
	
	var start = 0
	var cursor = 0
	var end = 0
	
	func _init(_size):
		data = []
		data.resize(_size)
		size = _size
		
	func adjust():
		var new_start = end - size
		if new_start > start:
			start = new_start
			
		if cursor < start:
			cursor = start
		if cursor > end:
			cursor = end
	
	func move_cursor(steps):
		cursor += steps
		adjust()
		
	func push(element):
		data[cursor % size] = element
		cursor += 1
		end = cursor
		adjust()
	
	func get_rel(i):
		i += cursor
		i = i % size
		return data[i]
	
	func get(i):
		i += start
		i = i % size
		return data[i]
	
	func get_available_steps_forward():
		return end - cursor
	
	func get_available_steps_backward():
		return cursor - start

class ChangeCollection:
	export var label = "Unknown"
	export var changes = []
	
	func _init():
		# Whoops
		changes = changes.duplicate()

	func undo(db):
		for change in changes:
			change.undo(db)
		
	func redo(db):
		for i in range(1, changes.size()+1):
			changes[changes.size() - i].redo(db)

	func print_summary():
		print("Undo Step summary for: ", label)
		for change in changes:
			change.print_summary()

class ItemStateChange:
	export var itemID = ""
	export var before_state = {}
	export var after_state = {}
	
	func undo(db):
		if before_state.empty():
			#print("\tnull -> {}: Undo Creation of ", itemID)
			db.mark_id_as_obsolete(itemID)
		elif after_state.empty():
			#print("\t{} -> null: Undo Deletion of ", itemID)
			db.create_from_imprint(itemID, before_state)
		else:
			#print("\t{} -> {}: Revert to original state ", itemID)
			db.apply_imprint(itemID, before_state)
	
	func redo(db):
		if after_state.empty():
			#print("\t{} -> null: Redo Deletion of ", itemID)
			db.mark_id_as_obsolete(itemID)
		elif before_state.empty():
			#print("\tnull -> {}: Redo Creation of ", itemID)
			db.create_from_imprint(itemID, after_state)
		else:
			#print("\t{} -> {}: Reapply modifications ", itemID)
			db.apply_imprint(itemID, after_state)

	func print_summary():
		if before_state.empty():
			print("\tnull -> {}: Creation of ", itemID)
		elif after_state.empty():
			print("\t{} -> null: Deletion of ", itemID)
		else:
			print("\t{} -> {}: Modification of ", itemID)

func _init():
	buffer = UndoRingBuffer.new(10000)

func push(label, ids, old_states, new_states):
	var collection = ChangeCollection.new()
	for i in ids.size():
		if ids[i] == null:
			break

		var item = ItemStateChange.new()
		item.itemID = ids[i]
		item.before_state = old_states[i].duplicate()
		item.after_state = new_states[i].duplicate()
		collection.changes.push_back(item)
	collection.label = label
	buffer.push(collection)
	#collection.print_summary()
	return collection

func rewind(steps):
	steps = min(steps, buffer.get_available_steps_backward())
	for i in steps:
		var step = buffer.get_rel(-1-i)
		#print("Rewind: ", step.label)
		#step.print_summary()
		step.undo(db)
	buffer.move_cursor(-steps)

func advance(steps):
	steps = min(steps, buffer.get_available_steps_forward())
	for i in steps:
		var step = buffer.get_rel(i)
		#print("Reapply: ", step.label)
		#step.print_summary()
		step.redo(db)
	buffer.move_cursor(steps)

func undo():
	rewind(1)

func redo():
	advance(1)

func get_undo_step():
	return buffer.get_rel(-1)

func get_redo_step():
	return buffer.get_rel(0)

func _marshall_get_data():
	return {"list":get_data()}

func _marshall_load_data(data):
	return load_data(data["list"])

func get_data():
	var data = []
	for i in buffer.get_available_steps_backward():
		data.push_back(buffer.get_rel(-1-i))
	return data

func load_data(state):
	state.invert()
	for item in state:
		if item is ItemStateChange or item is ChangeCollection:
			buffer.push(item)