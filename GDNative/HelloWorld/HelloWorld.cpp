#include "HelloWorld.h"

using namespace godot;

void HelloWorld::_register_methods()
{
	register_method("get_string", &HelloWorld::get_string);
}

HelloWorld::HelloWorld()
{
}

HelloWorld::~HelloWorld()
{
	// add your cleanup here
}

void HelloWorld::_init()
{

}

String HelloWorld::get_string()
{
	return "Hello World from GDNative!";
}