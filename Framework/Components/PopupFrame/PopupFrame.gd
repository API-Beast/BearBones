extends Control

const RefImagePopup = preload("res://Framework/Components/PopupFrame/RefImagePopup.tscn")

func _ready():
	App.connect("on_doc_composition_changed", self, "mirror_shards")
	App.connect("on_shard_update", self, "mirror_shards")
	App.connect("on_active_doc_changed", self, "clear_shards")

func clear_shards():
	var container = self
	for node in container.get_children():
		node.queue_free()
	mirror_shards()

func mirror_shards():
	var doc = App.current_doc
	if not doc:
		return

	if not is_inside_tree():
		return

	var container = self
	var shards = doc.shards_by_type("RefImage")
	for shard in shards:
		if container.has_node(shard.id): continue
		if not shard.visible: continue
		if not shard.is_valid(): continue
		
		var type = shard.get_type()
		var node = null
		match type:
			"RefImage":
				node = RefImagePopup.instance()
		node.name = shard.id
		container.add_child(node)
		node.set_shard(shard)
		initialize_popup_frame(node, shard)

	for node in container.get_children():
		if not doc.has_id(node.name):
			node.queue_free()

func initialize_popup_frame(node, shard):
	if not shard.initialized:
		var ideal_size = node.get_ideal_size()
		var ratio = ideal_size.normalized()
		var size = min(max(OS.window_size.length()/8.0, 300), ideal_size.length()*2.0)
		shard.size = (ratio * size).round()+Vector2(8, 13)
		shard.position = (shard.size * Vector2(rand_range(0.0, 0.50), rand_range(0.0, 0.50))).round()
		shard.initialized = true
		shard.update()
		node.adjust_position()