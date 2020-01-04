extends Reference
class_name DocumentContext

var doc = null
var selection = []
var focus = null

signal selection_updated()

func _init(new_doc):
	doc = new_doc

func is_focus(shard):
	return shard == focus

func is_selected(shard):
	return selection.has(shard)

func set_focus(shard):
	select(shard)
	focus = shard
	emit_signal("selection_updated")

func select(shard):
	select_impl(shard)
	emit_signal("selection_updated")

func select_impl(shard):
	if not selection.has(shard):
		selection.push_back(shard)
	if focus == null:
		focus = selection.back()

func deselect(s):
	deselect_impl(s)
	emit_signal("selection_updated")

func deselect_impl(shard):
	selection.erase(shard)
	if focus == shard:
		if not selection.empty():
			focus = selection.back()

func deselect_all():
	selection = []
	focus = null
	emit_signal("selection_updated")

func get_implied_selection():
	return selection

func set_selection(new_selection):
	deselect_all()
	for shard in new_selection:
		select(shard)