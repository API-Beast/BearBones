extends HBoxContainer

var deactivation_immunity = 0
var is_active = false
var connections = {}
var current_menu = WeakRef.new()
var current_button = null

func _ready():
	for node in get_children():
		node.connect("pressed", self, "make_active")
		node.connect("pressed", self, "show_menu", [node])

func connect_button(target, obj, function, menu_name):
	connections[target] = [obj, function, menu_name]

func make_active():
	is_active = true
	deactivation_immunity = get_tree().get_frame()

func _input(e):
	if Dialog.is_blocking():
		return

	if is_active and e is InputEventMouseButton and e.is_pressed() and (get_tree().get_frame() != deactivation_immunity):
		is_active = false

func _process(delta):
	if is_active:
		var mouse_pos = get_global_mouse_position()
		var btn = null
		for node in get_children():
			if node.get_global_rect().has_point(mouse_pos):
				btn = node
		if btn and btn != current_button:
			show_menu(btn)

func show_menu(node):
	var conn = connections[node]
	if current_menu.get_ref():
		current_menu.get_ref().hide()
		current_menu = WeakRef.new()

	current_menu = weakref(conn[0].call(conn[1], node, conn[2]))
	current_button = node