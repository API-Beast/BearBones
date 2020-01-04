extends Control

func set_strength(strength):
	material.set_shader_param("dither_strength", strength)

func set_pattern(pattern):
	var dither_tex = ImageCache.get_tex(pattern, Texture.FLAG_REPEAT)
	material.set_shader_param("dither_sampler", dither_tex)