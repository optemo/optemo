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
CMAKE_SOURCE_DIR = /optemo/site/lib/c_code/clusteringCode

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /optemo/site/lib/c_code/clusteringCode

# Include any dependencies generated for this target.
include codes/CMakeFiles/prepared_statement.dir/depend.make

# Include the progress variables for this target.
include codes/CMakeFiles/prepared_statement.dir/progress.make

# Include the compile flags for this target's objects.
include codes/CMakeFiles/prepared_statement.dir/flags.make

codes/CMakeFiles/prepared_statement.dir/depend.make.mark: codes/CMakeFiles/prepared_statement.dir/flags.make
codes/CMakeFiles/prepared_statement.dir/depend.make.mark: codes/prepared_statement.cpp

codes/CMakeFiles/prepared_statement.dir/prepared_statement.o: codes/CMakeFiles/prepared_statement.dir/flags.make
codes/CMakeFiles/prepared_statement.dir/prepared_statement.o: codes/prepared_statement.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /optemo/site/lib/c_code/clusteringCode/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object codes/CMakeFiles/prepared_statement.dir/prepared_statement.o"
	/usr/bin/c++   $(CXX_FLAGS) -o codes/CMakeFiles/prepared_statement.dir/prepared_statement.o -c /optemo/site/lib/c_code/clusteringCode/codes/prepared_statement.cpp

codes/CMakeFiles/prepared_statement.dir/prepared_statement.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to codes/CMakeFiles/prepared_statement.dir/prepared_statement.i"
	/usr/bin/c++  $(CXX_FLAGS) -E /optemo/site/lib/c_code/clusteringCode/codes/prepared_statement.cpp > codes/CMakeFiles/prepared_statement.dir/prepared_statement.i

codes/CMakeFiles/prepared_statement.dir/prepared_statement.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly codes/CMakeFiles/prepared_statement.dir/prepared_statement.s"
	/usr/bin/c++  $(CXX_FLAGS) -S /optemo/site/lib/c_code/clusteringCode/codes/prepared_statement.cpp -o codes/CMakeFiles/prepared_statement.dir/prepared_statement.s

codes/CMakeFiles/prepared_statement.dir/prepared_statement.o.requires:

codes/CMakeFiles/prepared_statement.dir/prepared_statement.o.provides: codes/CMakeFiles/prepared_statement.dir/prepared_statement.o.requires
	$(MAKE) -f codes/CMakeFiles/prepared_statement.dir/build.make codes/CMakeFiles/prepared_statement.dir/prepared_statement.o.provides.build

codes/CMakeFiles/prepared_statement.dir/prepared_statement.o.provides.build: codes/CMakeFiles/prepared_statement.dir/prepared_statement.o

codes/CMakeFiles/prepared_statement.dir/depend: codes/CMakeFiles/prepared_statement.dir/depend.make.mark

codes/CMakeFiles/prepared_statement.dir/depend.make.mark:
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --magenta --bold "Scanning dependencies of target prepared_statement"
	cd /optemo/site/lib/c_code/clusteringCode && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /optemo/site/lib/c_code/clusteringCode /optemo/site/lib/c_code/clusteringCode/codes /optemo/site/lib/c_code/clusteringCode /optemo/site/lib/c_code/clusteringCode/codes /optemo/site/lib/c_code/clusteringCode/codes/CMakeFiles/prepared_statement.dir/DependInfo.cmake

# Object files for target prepared_statement
prepared_statement_OBJECTS = \
"CMakeFiles/prepared_statement.dir/prepared_statement.o"

# External object files for target prepared_statement
prepared_statement_EXTERNAL_OBJECTS =

codes/prepared_statement: codes/CMakeFiles/prepared_statement.dir/prepared_statement.o
codes/prepared_statement: cppconn/libmysqlcppconn-static.a
codes/prepared_statement: codes/CMakeFiles/prepared_statement.dir/build.make
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX executable prepared_statement"
	cd /optemo/site/lib/c_code/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/prepared_statement.dir/cmake_clean_target.cmake
	cd /optemo/site/lib/c_code/clusteringCode/codes && /usr/bin/c++     -headerpad_max_install_names -fPIC $(prepared_statement_OBJECTS) $(prepared_statement_EXTERNAL_OBJECTS)  -o prepared_statement  -L/usr/local/mysql/lib -L/optemo/site/lib/c_code/clusteringCode/cppconn -lmysqlcppconn-static -lmysqlclient_r 

# Rule to build all files generated by this target.
codes/CMakeFiles/prepared_statement.dir/build: codes/prepared_statement

codes/CMakeFiles/prepared_statement.dir/requires: codes/CMakeFiles/prepared_statement.dir/prepared_statement.o.requires

codes/CMakeFiles/prepared_statement.dir/clean:
	cd /optemo/site/lib/c_code/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/prepared_statement.dir/cmake_clean.cmake
