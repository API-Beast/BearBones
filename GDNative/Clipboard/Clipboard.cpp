#include "Clipboard.h"
#include "clip/clip.h"

using namespace godot;

extern "C" void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options *o) {
	godot::Godot::gdnative_init(o);
}

extern "C" void GDN_EXPORT godot_gdnative_terminate(godot_gdnative_terminate_options *o) {
	godot::Godot::gdnative_terminate(o);
}

extern "C" void GDN_EXPORT godot_nativescript_init(void *handle) {
	godot::Godot::nativescript_init(handle);

	godot::register_class<godot::Clipboard>();
}

void Clipboard::_register_methods()
{
	register_method("clear", &Clipboard::clear);
	register_method("has_text", &Clipboard::has_text);
	register_method("get_text", &Clipboard::get_text);
	register_method("set_text", &Clipboard::set_text);
	register_method("has_image", &Clipboard::has_image);
	register_method("get_image", &Clipboard::get_image);
	register_method("set_image", &Clipboard::set_image);
}

Clipboard::Clipboard()
{
}

Clipboard::~Clipboard()
{
	// add your cleanup here
}

void Clipboard::_init()
{
}

void Clipboard::clear()
{
	clip::clear();
}

bool Clipboard::has_text()
{
	return clip::has(clip::text_format());
}

bool Clipboard::set_text(String text)
{
	return clip::set_text(text.utf8().get_data());
}

String Clipboard::get_text()
{
	std::string retVal;
	clip::get_text(retVal);
	return String(retVal.c_str());
}

bool Clipboard::has_image()
{
	return clip::has(clip::image_format());
}

bool Clipboard::set_image(Ref<Image> img)
{
	Image converted;
	converted.copy_from(img);
	converted.convert(Image::FORMAT_RGBA8);

	clip::image_spec spec;
	spec.width = img->get_size().x;
	spec.height = img->get_size().y;
	spec.bits_per_pixel = 32;
	spec.bytes_per_row = spec.width*4;
	spec.red_mask = 0xff;
	spec.green_mask = 0xff00;
	spec.blue_mask = 0xff0000;
	spec.alpha_mask = 0xff000000;
	spec.red_shift = 0;
	spec.green_shift = 8;
	spec.blue_shift = 16;
	spec.alpha_shift = 24;

	auto* data = converted.get_data().read().ptr();
	clip::image clipimg(data, spec);
	return clip::set_image(clipimg);
}

Variant Clipboard::get_image()
{
	if(has_image())
	{
		return Variant(new Image());
	}
	return Variant();
}

Vector2 Clipboard::get_image_size()
{
	return Vector2(0, 0);
}
