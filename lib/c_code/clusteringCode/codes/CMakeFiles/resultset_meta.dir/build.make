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
include codes/CMakeFiles/resultset_meta.dir/depend.make

# Include the progress variables for this target.
include codes/CMakeFiles/resultset_meta.dir/progress.make

# Include the compile flags for this target's objects.
include codes/CMakeFiles/resultset_meta.dir/flags.make

codes/CMakeFiles/resultset_meta.dir/depend.make.mark: codes/CMakeFiles/resultset_meta.dir/flags.make
codes/CMakeFiles/resultset_meta.dir/depend.make.mark: codes/resultset_meta.cpp

codes/CMakeFiles/resultset_meta.dir/resultset_meta.o: codes/CMakeFiles/resultset_meta.dir/flags.make
codes/CMakeFiles/resultset_meta.dir/resultset_meta.o: codes/resultset_meta.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /Users/maryam/clusteringCode/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object codes/CMakeFiles/resultset_meta.dir/resultset_meta.o"
	/usr/bin/c++   $(CXX_FLAGS) -o codes/CMakeFiles/resultset_meta.dir/resultset_meta.o -c /Users/maryam/clusteringCode/codes/resultset_meta.cpp

codes/CMakeFiles/resultset_meta.dir/resultset_meta.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to codes/CMakeFiles/resultset_meta.dir/resultset_meta.i"
	/usr/bin/c++  $(CXX_FLAGS) -E /Users/maryam/clusteringCode/codes/resultset_meta.cpp > codes/CMakeFiles/resultset_meta.dir/resultset_meta.i

codes/CMakeFiles/resultset_meta.dir/resultset_meta.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly codes/CMakeFiles/resultset_meta.dir/resultset_meta.s"
	/usr/bin/c++  $(CXX_FLAGS) -S /Users/maryam/clusteringCode/codes/resultset_meta.cpp -o codes/CMakeFiles/resultset_meta.dir/resultset_meta.s

codes/CMakeFiles/resultset_meta.dir/resultset_meta.o.requires:

codes/CMakeFiles/resultset_meta.dir/resultset_meta.o.provides: codes/CMakeFiles/resultset_meta.dir/resultset_meta.o.requires
	$(MAKE) -f codes/CMakeFiles/resultset_meta.dir/build.make codes/CMakeFiles/resultset_meta.dir/resultset_meta.o.provides.build

codes/CMakeFiles/resultset_meta.dir/resultset_meta.o.provides.build: codes/CMakeFiles/resultset_meta.dir/resultset_meta.o

codes/CMakeFiles/resultset_meta.dir/depend: codes/CMakeFiles/resultset_meta.dir/depend.make.mark

codes/CMakeFiles/resultset_meta.dir/depend.make.mark:
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --magenta --bold "Scanning dependencies of target resultset_meta"
	cd /Users/maryam/clusteringCode && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/maryam/clusteringCode /Users/maryam/clusteringCode/codes /Users/maryam/clusteringCode /Users/maryam/clusteringCode/codes /Users/maryam/clusteringCode/codes/CMakeFiles/resultset_meta.dir/DependInfo.cmake

# Object files for target resultset_meta
resultset_meta_OBJECTS = \
"CMakeFiles/resultset_meta.dir/resultset_meta.o"

# External object files for target resultset_meta
resultset_meta_EXTERNAL_OBJECTS =

codes/resultset_meta: codes/CMakeFiles/resultset_meta.dir/resultset_meta.o
codes/resultset_meta: cppconn/libmysqlcppconn-static.a
codes/resultset_meta: codes/CMakeFiles/resultset_meta.dir/build.make
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX executable resultset_meta"
	cd /Users/maryam/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/resultset_meta.dir/cmake_clean_target.cmake
	cd /Users/maryam/clusteringCode/codes && /usr/bin/c++     -headerpad_max_install_names -fPIC $(resultset_meta_OBJECTS) $(resultset_meta_EXTERNAL_OBJECTS)  -o resultset_meta  -L/usr/local/mysql/lib -L/Users/maryam/clusteringCode/cppconn -lmysqlcppconn-static -lmysqlclient_r 

# Rule to build all files generated by this target.
codes/CMakeFiles/resultset_meta.dir/build: codes/resultset_meta

codes/CMakeFiles/resultset_meta.dir/requires: codes/CMakeFiles/resultset_meta.dir/resultset_meta.o.requires

codes/CMakeFiles/resultset_meta.dir/clean:
	cd /Users/maryam/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/resultset_meta.dir/cmake_clean.cmake

