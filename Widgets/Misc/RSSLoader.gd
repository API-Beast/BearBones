extends VBoxContainer

export var url = ""
export var item_limit = 4

var items = []

const Item = preload("res://Widgets/Misc/RSSItem.tscn")

class ItemData:
	var title = "~No Title~"
	var description = "~No Text~"
	var pub_date = null
	var link = null
	var height = 100

func _ready():
	load_cache()
	$HTTPRequest.connect("request_completed", self, "on_rss_loaded")
	$HTTPRequest.request(url)

func build_items():
	for node in get_children():
		if node is Control:
			node.free()

	var i = 0
	for item in items:
		var node = Item.instance()
		node.get_node("Title").text = item.title
		node.get_node("Text").bbcode_text = item.description
		node.link = item.link

		if i != 0:
			add_child(HSeparator.new())

		add_child(node)
		node.get_node("TextSizer").text = item.description
		node.get_node("TextSizer").get_line_count() # Force cache recalculation
		node.get_node("Text").rect_min_size.y = node.get_node("TextSizer").get_minimum_size().y + 22
		node.get_node("TextSizer").visible = false
		
		i += 1

func on_rss_loaded(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		if response_code >= 200 or response_code < 30:
			load_rss(body)
			
			# Make a local copy to keep Newsfeed functional without internet
			var file = File.new()
			file.open("user://cached_newsfeed.rss", File.WRITE)
			file.store_buffer(body)
			file.close()
			return

	print("Failed loading Newsfeed from ", url, " ; Result: ", result, " Response Code: ", response_code)

func load_cache():
	# Make a local copy to keep Newsfeed functional without internet
	var file = File.new()
	if file.file_exists("user://cached_newsfeed.rss"):
		print("Loading cached newsfeed...")
		file.open("user://cached_newsfeed.rss", File.READ)
		load_rss(file.get_buffer(file.get_len()))
		file.close()

func load_rss(body):
	var parser = XMLParser.new()
	parser.open_buffer(body)
	items = []

	while not parser.read():
		var type = parser.get_node_type()
		if type != XMLParser.NODE_ELEMENT:
			continue

		var name = parser.get_node_name()
		if name != "item":
			continue

		items.push_back(parse_item(parser))
		if items.size() >= item_limit:
			break
	
	build_items()

func parse_item(parser):
	var data = ItemData.new()
	while not parser.read():
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "item":
			break
		if type != XMLParser.NODE_ELEMENT:
			continue
		
		match parser.get_node_name():
			"title":
				parser.read()
				data.title = parser.get_node_data().strip_edges()
			"description":
				parser.read()
				data.description = parser.get_node_data().strip_edges()
			"pubDate":
				parser.read()
				data.pub_date = parser.get_node_data().strip_edges()
			"link":
				parser.read()
				data.link = parser.get_node_data().strip_edges()
			"height":
				parser.read()
				data.height = parser.get_node_data().to_int()
	return data


		

				
				

