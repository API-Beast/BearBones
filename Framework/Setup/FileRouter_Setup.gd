extends Node

func _init():
	FileRouter.add_conversion(Image, ImageTexture, self, "image_to_image_texture")

	FileRouter.add_route("load", "image/*", Image, self, "load_image")
	FileRouter.add_route("save", "image/png", Image, self, "save_png")

func image_to_image_texture(input:Image)->ImageTexture:
	var img_tex = ImageTexture.new()
	img_tex.create_from_image(input)
	return img_tex

func load_image(path:String)->Image:
	var img = Image.new()
	img.load(path)
	return img
