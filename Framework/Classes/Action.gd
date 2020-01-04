class_name Action

var targets = []
var target_shards = []
var target_ids = []
var doc = null
var canvas = null
var center_pos := Vector2()
var visual_center := Vector2()
var start_pos := Vector2()
var finished := false
var focus = null
var draw_guideline := false

func start(pos, p_targets, p_canvas, p_focus):
	var accum = 0
	var assoc = {}

	_pre_execute(p_targets, pos)

	for shard in p_targets:
		var dict = {}
		dict["shard"] = shard
		dict["original_state"] = shard.create_imprint()
		assoc[shard] = dict
		if _filter(dict):
			self.targets.push_back(dict)
			self.target_shards.push_back(shard)
			self.target_ids.push_back(shard.id)
			if shard.has_method("get_center"):
				self.visual_center += shard.get_center()
				self.center_pos += shard.position
				accum += 1

	self.canvas = p_canvas
	self.doc = p_canvas.doc
	start_pos = pos

	if targets.size() == 0:
		finished = true
		return

	if assoc.has(p_focus):
		focus = assoc[p_focus]
	if not focus or not _filter(focus):
		focus = self.targets[0]
	if not focus:
		finished = true
		return

	if accum != 0:
		self.visual_center /= accum
		self.center_pos /= accum

	for target in targets:
		if "position" in target.shard:
			target["offset"] = target.shard.position - center_pos

	_execute()
	if is_instant_action():
		confirm(pos)
	else:
		if not finished:
			for target in targets:
				_start(target, pos)
				_update(target, pos)

func abort():
	for target in targets:
		target.shard.apply_imprint(target.original_state)
	finished = true

func confirm(pos):
	for target in targets:
		_update(target, pos)
		target.shard.update()
	_finish(pos)

	doc.push_undo(tr(self.Label))
	finished = true

func update(pos):
	for target in targets:
		_update(target, pos)
		target.shard.update()
	
func is_instant_action():
	return false

func is_finished():
	return finished == true

func _pre_execute(trgts, pos):
	pass

func _execute():
	pass

func _start(target, pos):
	pass

func _finish(pos):
	pass

func _update(target, pos):
	pass

func _filter(target):
	return true