cmake_minimum_required(VERSION 3.6)
project(Clipboard)

add_library(Clipboard SHARED Clipboard.cpp Clipboard.h)
target_link_libraries(Clipboard PUBLIC clip godot-cpp -static-libgcc -static-libstdc++ -static winpthread)
set_target_properties(Clipboard PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/GDNative
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/GDNative)

add_subdirectory(clip)