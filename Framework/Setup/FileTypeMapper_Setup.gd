extends Node

func _init():
	FileTypeMapper.register_type("image/png" , "PNG-Image" , Image, [], ["*.png"])
	FileTypeMapper.register_type("image/jpeg", "JPEG-Image", Image, [], ["*.jpeg", "*.jpg"])
	FileTypeMapper.register_type("image/webp", "WebP-Image", Image, [], ["*.webp"])