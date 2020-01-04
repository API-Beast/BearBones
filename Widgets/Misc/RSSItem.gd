extends VBoxContainer

export var link = ""

func open_link():
    OS.shell_open(link)

func open_meta_link(url):
    OS.shell_open(url)

func _ready():
    $Title.connect("pressed", self, "open_link")
    $Link.connect("pressed", self, "open_link")
    $Text.connect("meta_clicked", self, "open_meta_link")