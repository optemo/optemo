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
CMAKE_SOURCE_DIR = /Users/maryam/clusteringCode

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/maryam/clusteringCode

# Include any dependencies generated for this target.
include codes/CMakeFiles/statement.dir/depend.make

# Include the progress variables for this target.
include codes/CMakeFiles/statement.dir/progress.make

# Include the compile flags for this target's objects.
include codes/CMakeFiles/statement.dir/flags.make

codes/CMakeFiles/statement.dir/depend.make.mark: codes/CMakeFiles/statement.dir/flags.make
codes/CMakeFiles/statement.dir/depend.make.mark: codes/statement.cpp

codes/CMakeFiles/statement.dir/statement.o: codes/CMakeFiles/statement.dir/flags.make
codes/CMakeFiles/statement.dir/statement.o: codes/statement.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /Users/maryam/clusteringCode/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object codes/CMakeFiles/statement.dir/statement.o"
	/usr/bin/c++   $(CXX_FLAGS) -o codes/CMakeFiles/statement.dir/statement.o -c /Users/maryam/clusteringCode/codes/statement.cpp

codes/CMakeFiles/statement.dir/statement.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to codes/CMakeFiles/statement.dir/statement.i"
	/usr/bin/c++  $(CXX_FLAGS) -E /Users/maryam/clusteringCode/codes/statement.cpp > codes/CMakeFiles/statement.dir/statement.i

codes/CMakeFiles/statement.dir/statement.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly codes/CMakeFiles/statement.dir/statement.s"
	/usr/bin/c++  $(CXX_FLAGS) -S /Users/maryam/clusteringCode/codes/statement.cpp -o codes/CMakeFiles/statement.dir/statement.s

codes/CMakeFiles/statement.dir/statement.o.requires:

codes/CMakeFiles/statement.dir/statement.o.provides: codes/CMakeFiles/statement.dir/statement.o.requires
	$(MAKE) -f codes/CMakeFiles/statement.dir/build.make codes/CMakeFiles/statement.dir/statement.o.provides.build

codes/CMakeFiles/statement.dir/statement.o.provides.build: codes/CMakeFiles/statement.dir/statement.o

codes/CMakeFiles/statement.dir/depend: codes/CMakeFiles/statement.dir/depend.make.mark

codes/CMakeFiles/statement.dir/depend.make.mark:
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --magenta --bold "Scanning dependencies of target statement"
	cd /Users/maryam/clusteringCode && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/maryam/clusteringCode /Users/maryam/clusteringCode/codes /Users/maryam/clusteringCode /Users/maryam/clusteringCode/codes /Users/maryam/clusteringCode/codes/CMakeFiles/statement.dir/DependInfo.cmake

# Object files for target statement
statement_OBJECTS = \
"CMakeFiles/statement.dir/statement.o"

# External object files for target statement
statement_EXTERNAL_OBJECTS =

codes/statement: codes/CMakeFiles/statement.dir/statement.o
codes/statement: cppconn/libmysqlcppconn-static.a
codes/statement: codes/CMakeFiles/statement.dir/build.make
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX executable statement"
	cd /Users/maryam/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/statement.dir/cmake_clean_target.cmake
	cd /Users/maryam/clusteringCode/codes && /usr/bin/c++     -headerpad_max_install_names -fPIC $(statement_OBJECTS) $(statement_EXTERNAL_OBJECTS)  -o statement  -L/usr/local/mysql/lib -L/Users/maryam/clusteringCode/cppconn -lmysqlcppconn-static -lmysqlclient_r 

# Rule to build all files generated by this target.
codes/CMakeFiles/statement.dir/build: codes/statement

codes/CMakeFiles/statement.dir/requires: codes/CMakeFiles/statement.dir/statement.o.requires

codes/CMakeFiles/statement.dir/clean:
	cd /Users/maryam/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/statement.dir/cmake_clean.cmake

