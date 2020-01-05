#pragma once

#include <Godot.hpp>
#include <Sprite.hpp>

namespace godot {

class HelloWorld : public Node {
	GODOT_CLASS(HelloWorld, Node)

private:
	float time_passed;

public:
	static void _register_methods();

	HelloWorld();
	~HelloWorld();
	void _init();

	String get_string();
};

}
