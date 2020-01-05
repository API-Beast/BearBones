cmake_minimum_required(VERSION 3.6)
project(HelloWorld)

add_library(HelloWorld SHARED gdlibrary.cpp HelloWorld.cpp HelloWorld.h)
target_link_libraries(HelloWorld PUBLIC godot-cpp -static-libgcc -static-libstdc++ -static winpthread)
set_target_properties(HelloWorld PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/GDNative
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/GDNative)
	#ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/GDNative)