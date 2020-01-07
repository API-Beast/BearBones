#pragma once

#include <Godot.hpp>
#include <Node.hpp>
#include <Image.hpp>
#include <Vector2.hpp>

namespace godot {

class Clipboard : public Node {
	GODOT_CLASS(Clipboard, Node)

public:
	static void _register_methods();

	Clipboard();
	~Clipboard();
	void _init();

	void clear();

	bool has_text();
	bool set_text(String text);
	String get_text();

	bool has_image();
	bool set_image(Ref<Image> img);
	Variant get_image();

	Vector2 get_image_size();
};

}
