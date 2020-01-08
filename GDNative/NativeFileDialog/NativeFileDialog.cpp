#include <nfd.h>
#include "NativeFileDialog.h"

using namespace godot;

extern "C" void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options *o) {
	godot::Godot::gdnative_init(o);
}

extern "C" void GDN_EXPORT godot_gdnative_terminate(godot_gdnative_terminate_options *o) {
	godot::Godot::gdnative_terminate(o);
}

extern "C" void GDN_EXPORT godot_nativescript_init(void *handle) {
	godot::Godot::nativescript_init(handle);

	godot::register_class<godot::NativeFileDialog>();
}

void NativeFileDialog::_register_methods()
{
	register_method("show", &NativeFileDialog::show);

	register_property<NativeFileDialog, int>("mode", &NativeFileDialog::mode, NativeFileDialog::Mode::MODE_OPEN_ANY);
	register_property<NativeFileDialog, String>("current_dir", &NativeFileDialog::current_dir, "");
	register_property<NativeFileDialog, String>("current_file", &NativeFileDialog::current_file, "");

	PoolStringArray default_filters;
	default_filters.push_back("Any;*");
	register_property<NativeFileDialog, PoolStringArray>("filters", &NativeFileDialog::filters, default_filters);

	register_signal<NativeFileDialog>("about_to_show");
	register_signal<NativeFileDialog>("popup_hide");
	register_signal<NativeFileDialog>("custom_action", "action", GODOT_VARIANT_TYPE_STRING);
	register_signal<NativeFileDialog>("dir_selected", "dir", GODOT_VARIANT_TYPE_STRING);
	register_signal<NativeFileDialog>("file_selected", "path", GODOT_VARIANT_TYPE_STRING);
	register_signal<NativeFileDialog>("files_selected", "paths", GODOT_VARIANT_TYPE_POOL_STRING_ARRAY);
}

void NativeFileDialog::_init()
{

}

void NativeFileDialog::show()
{
	NFD_Init();
	emit_signal("about_to_show");

	char* outPath = nullptr;
	char* defaultPath = nullptr;
	char* defaultName = nullptr;

	if(!current_dir.empty()) defaultPath = current_dir.alloc_c_string();
	if(!current_file.empty()) defaultName = current_file.alloc_c_string();

	const nfdpathset_t* path_set = nullptr;
	nfdu8filteritem_t* filter_items = new nfdu8filteritem_t[filters.size()];
	nfdresult_t result = NFD_CANCEL;

	for(int i = 0; i < filters.size(); i++)
	{
		int delimiter = filters[i].find_last(";");
		PoolStringArray specs = filters[i].substr(0, delimiter).split(",");
		String spec("");
		for(int i = 0; i < specs.size(); i++)
		{
			if(i != 0)
				spec += ",";
			spec += specs[i].get_extension();
		}
		
		filter_items[i].spec = spec.alloc_c_string();
		filter_items[i].name = filters[i].substr(delimiter + 1, filters[i].length() - delimiter - 1).alloc_c_string();
	}
	
	switch (mode)
	{
	case MODE_OPEN_ANY:
	case MODE_OPEN_FILE:
	case MODE_SAVE_FILE:
		if(mode == MODE_SAVE_FILE)
			result = NFD_SaveDialogU8(&outPath, filter_items, filters.size(), defaultPath, defaultName);
		else
			result = NFD_OpenDialogU8(&outPath, filter_items, filters.size(), defaultPath);
		
		if(result == NFD_OKAY)
		{
			emit_signal("file_selected", String(outPath));
			NFD_FreePath(outPath);
		}
		else
			emit_signal("custom_action", "cancel");
		break;
	case MODE_OPEN_FILES:
	{
		result = NFD_OpenDialogMultipleU8(&path_set, filter_items, filters.size(), defaultPath);

		PoolStringArray paths;
		nfdpathsetsize_t count;
		NFD_PathSet_GetCount(path_set, &count);
		paths.resize(count);
		auto writer = paths.write();

		for(int i = 0; i < count; i++)
		{
			char* path = nullptr;
			NFD_PathSet_GetPathU8(path_set, i, &path);
			writer[i] = path;
			NFD_PathSet_FreePathU8(path);
		}
		NFD_PathSet_Free(path_set);
		

		if(result == NFD_OKAY)
			emit_signal("files_selected", paths);
		else
			emit_signal("custom_action", "cancel");

		break;
	}
	case MODE_OPEN_DIR:
		result = NFD_PickFolderU8(&outPath, defaultPath);
		if(result == NFD_OKAY)
		{
			emit_signal("dir_selected", String(outPath));
			NFD_FreePath(outPath);
		}
		else
			emit_signal("custom_action", "cancel");
		break;
	
	default:
		Godot::print("Invalid mode for NativeFileDialog");
		break;
	}
	emit_signal("popup_hide");

	if(defaultPath) godot::api->godot_free(defaultPath);
	if(defaultName) godot::api->godot_free(defaultName);
	for(int i = 0; i < filters.size(); i++)
	{
		godot::api->godot_free(const_cast<char*>(filter_items[i].name));
		godot::api->godot_free(const_cast<char*>(filter_items[i].spec));
	}
	delete[] filter_items;
	NFD_Quit();
}