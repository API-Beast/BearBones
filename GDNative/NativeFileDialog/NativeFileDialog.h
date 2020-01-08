#pragma once

#include <Godot.hpp>
#include <Node.hpp>
#include <Image.hpp>
#include <Vector2.hpp>

namespace godot {

class NativeFileDialog : public Node
{
	GODOT_CLASS(NativeFileDialog, Node)

public:
	static void _register_methods();
	
	// enums
	enum Mode {
		MODE_OPEN_FILE = 0,
		MODE_OPEN_FILES = 1,
		MODE_OPEN_DIR = 2,
		MODE_OPEN_ANY = 3,
		MODE_SAVE_FILE = 4,
	};

	// properties
	int mode;
	String current_dir;
	String current_file;
	PoolStringArray filters;

	// methods
	void show();

	// signals
	/*
	signal file_selected(String)
	signal dir_selected(String)
	signal files_selected(PoolStringArray)
	signal about_to_show()
	signal popup_hide()
	signal costum_action(String)
	*/
};


}
