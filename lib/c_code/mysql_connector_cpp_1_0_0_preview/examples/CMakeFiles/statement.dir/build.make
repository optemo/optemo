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
include examples/CMakeFiles/statement.dir/depend.make

# Include the progress variables for this target.
include examples/CMakeFiles/statement.dir/progress.make

# Include the compile flags for this target's objects.
include examples/CMakeFiles/statement.dir/flags.make

examples/CMakeFiles/statement.dir/depend.make.mark: examples/CMakeFiles/statement.dir/flags.make
examples/CMakeFiles/statement.dir/depend.make.mark: examples/statement.cpp

examples/CMakeFiles/statement.dir/statement.o: examples/CMakeFiles/statement.dir/flags.make
examples/CMakeFiles/statement.dir/statement.o: examples/statement.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object examples/CMakeFiles/statement.dir/statement.o"
	/usr/bin/c++   $(CXX_FLAGS) -o examples/CMakeFiles/statement.dir/statement.o -c /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples/statement.cpp

examples/CMakeFiles/statement.dir/statement.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to examples/CMakeFiles/statement.dir/statement.i"
	/usr/bin/c++  $(CXX_FLAGS) -E /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples/statement.cpp > examples/CMakeFiles/statement.dir/statement.i

examples/CMakeFiles/statement.dir/statement.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly examples/CMakeFiles/statement.dir/statement.s"
	/usr/bin/c++  $(CXX_FLAGS) -S /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples/statement.cpp -o examples/CMakeFiles/statement.dir/statement.s

examples/CMakeFiles/statement.dir/statement.o.requires:

examples/CMakeFiles/statement.dir/statement.o.provides: examples/CMakeFiles/statement.dir/statement.o.requires
	$(MAKE) -f examples/CMakeFiles/statement.dir/build.make examples/CMakeFiles/statement.dir/statement.o.provides.build

examples/CMakeFiles/statement.dir/statement.o.provides.build: examples/CMakeFiles/statement.dir/statement.o

examples/CMakeFiles/statement.dir/depend: examples/CMakeFiles/statement.dir/depend.make.mark

examples/CMakeFiles/statement.dir/depend.make.mark:
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --magenta --bold "Scanning dependencies of target statement"
	cd /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples/CMakeFiles/statement.dir/DependInfo.cmake

# Object files for target statement
statement_OBJECTS = \
"CMakeFiles/statement.dir/statement.o"

# External object files for target statement
statement_EXTERNAL_OBJECTS =

examples/statement: examples/CMakeFiles/statement.dir/statement.o
examples/statement: cppconn/libmysqlcppconn-static.a
examples/statement: examples/CMakeFiles/statement.dir/build.make
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX executable statement"
	cd /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples && $(CMAKE_COMMAND) -P CMakeFiles/statement.dir/cmake_clean_target.cmake
	cd /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples && /usr/bin/c++     -headerpad_max_install_names -fPIC $(statement_OBJECTS) $(statement_EXTERNAL_OBJECTS)  -o statement  -L/usr/local/mysql/lib -L/Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/cppconn -lmysqlcppconn-static -lmysqlclient_r 

# Rule to build all files generated by this target.
examples/CMakeFiles/statement.dir/build: examples/statement

examples/CMakeFiles/statement.dir/requires: examples/CMakeFiles/statement.dir/statement.o.requires

examples/CMakeFiles/statement.dir/clean:
	cd /Users/maryam/serverFiles/optemo/site/lib/c_code/mysql_connector_cpp_1_0_0_preview/examples && $(CMAKE_COMMAND) -P CMakeFiles/statement.dir/cmake_clean.cmake

