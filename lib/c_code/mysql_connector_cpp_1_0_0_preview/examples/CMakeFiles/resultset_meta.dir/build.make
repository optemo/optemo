# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 2.4

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canoncical targets will work.
.SUFFIXES:

.SUFFIXES: .hpux_make_needs_suffix_list

# Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/bin/cmake

# The command to remove a file.
RM = /usr/local/bin/cmake -E remove -f

# The program to use to edit the cache.
CMAKE_EDIT_COMMAND = /usr/local/bin/ccmake

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview

# Include any dependencies generated for this target.
include examples/CMakeFiles/resultset_meta.dir/depend.make

# Include the progress variables for this target.
include examples/CMakeFiles/resultset_meta.dir/progress.make

# Include the compile flags for this target's objects.
include examples/CMakeFiles/resultset_meta.dir/flags.make

examples/CMakeFiles/resultset_meta.dir/depend.make.mark: examples/CMakeFiles/resultset_meta.dir/flags.make
examples/CMakeFiles/resultset_meta.dir/depend.make.mark: examples/resultset_meta.cpp

examples/CMakeFiles/resultset_meta.dir/resultset_meta.o: examples/CMakeFiles/resultset_meta.dir/flags.make
examples/CMakeFiles/resultset_meta.dir/resultset_meta.o: examples/resultset_meta.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object examples/CMakeFiles/resultset_meta.dir/resultset_meta.o"
	/usr/bin/c++   $(CXX_FLAGS) -o examples/CMakeFiles/resultset_meta.dir/resultset_meta.o -c /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples/resultset_meta.cpp

examples/CMakeFiles/resultset_meta.dir/resultset_meta.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to examples/CMakeFiles/resultset_meta.dir/resultset_meta.i"
	/usr/bin/c++  $(CXX_FLAGS) -E /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples/resultset_meta.cpp > examples/CMakeFiles/resultset_meta.dir/resultset_meta.i

examples/CMakeFiles/resultset_meta.dir/resultset_meta.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly examples/CMakeFiles/resultset_meta.dir/resultset_meta.s"
	/usr/bin/c++  $(CXX_FLAGS) -S /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples/resultset_meta.cpp -o examples/CMakeFiles/resultset_meta.dir/resultset_meta.s

examples/CMakeFiles/resultset_meta.dir/resultset_meta.o.requires:

examples/CMakeFiles/resultset_meta.dir/resultset_meta.o.provides: examples/CMakeFiles/resultset_meta.dir/resultset_meta.o.requires
	$(MAKE) -f examples/CMakeFiles/resultset_meta.dir/build.make examples/CMakeFiles/resultset_meta.dir/resultset_meta.o.provides.build

examples/CMakeFiles/resultset_meta.dir/resultset_meta.o.provides.build: examples/CMakeFiles/resultset_meta.dir/resultset_meta.o

examples/CMakeFiles/resultset_meta.dir/depend: examples/CMakeFiles/resultset_meta.dir/depend.make.mark

examples/CMakeFiles/resultset_meta.dir/depend.make.mark:
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --magenta --bold "Scanning dependencies of target resultset_meta"
	cd /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples/CMakeFiles/resultset_meta.dir/DependInfo.cmake

# Object files for target resultset_meta
resultset_meta_OBJECTS = \
"CMakeFiles/resultset_meta.dir/resultset_meta.o"

# External object files for target resultset_meta
resultset_meta_EXTERNAL_OBJECTS =

examples/resultset_meta: examples/CMakeFiles/resultset_meta.dir/resultset_meta.o
examples/resultset_meta: cppconn/libmysqlcppconn-static.a
examples/resultset_meta: examples/CMakeFiles/resultset_meta.dir/build.make
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX executable resultset_meta"
	cd /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples && $(CMAKE_COMMAND) -P CMakeFiles/resultset_meta.dir/cmake_clean_target.cmake
	cd /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples && /usr/bin/c++     -headerpad_max_install_names -fPIC $(resultset_meta_OBJECTS) $(resultset_meta_EXTERNAL_OBJECTS)  -o resultset_meta  -L/usr/local/mysql/lib -L/Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/cppconn -lmysqlcppconn-static -lmysqlclient_r 

# Rule to build all files generated by this target.
examples/CMakeFiles/resultset_meta.dir/build: examples/resultset_meta

examples/CMakeFiles/resultset_meta.dir/requires: examples/CMakeFiles/resultset_meta.dir/resultset_meta.o.requires

examples/CMakeFiles/resultset_meta.dir/clean:
	cd /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples && $(CMAKE_COMMAND) -P CMakeFiles/resultset_meta.dir/cmake_clean.cmake

