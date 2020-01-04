extends Node

func _init():
	FileRouter.register_type("image/png" , "PNG-Image" , Image, [], ["*.png"])
	FileRouter.register_type("image/jpeg", "JPEG-Image", Image, [], ["*.jpeg", "*.jpg"])
	FileRouter.register_type("image/webp", "WebP-Image", Image, [], ["*.webp"])

	FileRouter.add_conversion_routine(Image, ImageTexture, self, "image_to_image_texture")

	FileRouter.add_import_routine("image/*", Image, self, "load_image")
	FileRouter.add_export_routine("image/png", Image, self, "save_png")

func image_to_image_texture(input:Image)->ImageTexture:
	var img_tex = ImageTexture.new()
	img_tex.create_from_image(input)
	return img_tex

func load_image(path:String)->Image:
	var img = Image.new()
	img.load(path)
	return img

func save_png(img:Image, path:String):
	return img.save_png(path)