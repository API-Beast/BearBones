extends Node

var socket = null
var reacquire_timer = 0.0
var fast_quit = false

export var port = 29577

func _init():
	var hello_world = preload("res://GDNative/HelloWorld.gdns").new()
	print(hello_world.get_string())
	hello_world.free()

	var args = OS.get_cmdline_args()
	init_socket()
	fast_quit = (socket == null) and args.size() > 0 and not "--new-window" in args
	if fast_quit:
		OS.window_minimized = true
		var dir = Directory.new()
		print("Existing instance found, closing.")
		if args.size() != 0:
			var temp_socket = PacketPeerUDP.new()
			temp_socket.set_dest_address("127.0.0.1", port)

			# Make file paths absolute
			#var absolute_args = []
			#for arg in args:
			#    if arg.begins_with("--"):
			#        absolute_args.push_back(arg)
			#    else:
			#        absolute_args.push_back(dir.get_current_dir().plus_file(arg))

			temp_socket.put_var(args)

func _enter_tree():
	if fast_quit:
		get_tree().quit()
	else:
		add_to_group("bootstrap")

func on_mdi_initialized(mdi):
	if not fast_quit:
		process_args(OS.get_cmdline_args())

func init_socket():
	socket = PacketPeerUDP.new()
	if socket.listen(port, "127.0.0.1"):
		socket = null
	else:
		print("Acquired UDP port ", port, " for inter-process-communication.")

func process_args(args):
	for arg in args:
		# TODO FIXME
		#if FileImport.can_load(arg):
		if false:
			print("Opening Tab for file: ", arg)
			App.open_file(arg)

func _process(dt):
	if socket:
		while socket.get_available_packet_count() > 0:
			var pkg = socket.get_var()
			process_args(pkg)
	else:
		reacquire_timer += dt
		if reacquire_timer > 20.0:
			init_socket()