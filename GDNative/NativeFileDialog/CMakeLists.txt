cmake_minimum_required(VERSION 3.6)
project(NativeFileDialog)

add_subdirectory(nativefiledialog-extended)

add_library(NativeFileDialog SHARED NativeFileDialog.cpp NativeFileDialog.h)
target_link_libraries(NativeFileDialog PUBLIC nfd godot-cpp -static-libgcc -static-libstdc++ -static winpthread)
set_target_properties(NativeFileDialog PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/GDNative
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/GDNative)