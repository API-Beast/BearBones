extends Node

var list = []
const MaxSize = 16

signal list_changed()

func _ready():
    list = Config.load_config_file("user://last_files.json", [])

func add(new_path):
    new_path = ProjectSettings.globalize_path(new_path)
    if list.front() != new_path:
        list.erase(new_path)
        list.push_front(new_path)
        clean_list()
        emit_signal("list_changed")
        save_list()

func clean_list():
    var file = File.new()
    var new_list = []
    for item in list:
        if item and file.file_exists(item):
            new_list.push_back(item)
    list = new_list
    if list.size() > MaxSize:
        list.resize(MaxSize)

func save_list():
    Config.save_config_file("user://last_files.json", list)