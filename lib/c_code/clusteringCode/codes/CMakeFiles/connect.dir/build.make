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
include codes/CMakeFiles/connect.dir/depend.make

# Include the progress variables for this target.
include codes/CMakeFiles/connect.dir/progress.make

# Include the compile flags for this target's objects.
include codes/CMakeFiles/connect.dir/flags.make

codes/CMakeFiles/connect.dir/depend.make.mark: codes/CMakeFiles/connect.dir/flags.make
codes/CMakeFiles/connect.dir/depend.make.mark: codes/connect.cpp

codes/CMakeFiles/connect.dir/connect.o: codes/CMakeFiles/connect.dir/flags.make
codes/CMakeFiles/connect.dir/connect.o: codes/connect.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /optemo/site/lib/c_code/clusteringCode/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object codes/CMakeFiles/connect.dir/connect.o"
	/usr/bin/c++   $(CXX_FLAGS) -o codes/CMakeFiles/connect.dir/connect.o -c /optemo/site/lib/c_code/clusteringCode/codes/connect.cpp

codes/CMakeFiles/connect.dir/connect.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to codes/CMakeFiles/connect.dir/connect.i"
	/usr/bin/c++  $(CXX_FLAGS) -E /optemo/site/lib/c_code/clusteringCode/codes/connect.cpp > codes/CMakeFiles/connect.dir/connect.i

codes/CMakeFiles/connect.dir/connect.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly codes/CMakeFiles/connect.dir/connect.s"
	/usr/bin/c++  $(CXX_FLAGS) -S /optemo/site/lib/c_code/clusteringCode/codes/connect.cpp -o codes/CMakeFiles/connect.dir/connect.s

codes/CMakeFiles/connect.dir/connect.o.requires:

codes/CMakeFiles/connect.dir/connect.o.provides: codes/CMakeFiles/connect.dir/connect.o.requires
	$(MAKE) -f codes/CMakeFiles/connect.dir/build.make codes/CMakeFiles/connect.dir/connect.o.provides.build

codes/CMakeFiles/connect.dir/connect.o.provides.build: codes/CMakeFiles/connect.dir/connect.o

codes/CMakeFiles/connect.dir/depend: codes/CMakeFiles/connect.dir/depend.make.mark

codes/CMakeFiles/connect.dir/depend.make.mark:
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --magenta --bold "Scanning dependencies of target connect"
	cd /optemo/site/lib/c_code/clusteringCode && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /optemo/site/lib/c_code/clusteringCode /optemo/site/lib/c_code/clusteringCode/codes /optemo/site/lib/c_code/clusteringCode /optemo/site/lib/c_code/clusteringCode/codes /optemo/site/lib/c_code/clusteringCode/codes/CMakeFiles/connect.dir/DependInfo.cmake

# Object files for target connect
connect_OBJECTS = \
"CMakeFiles/connect.dir/connect.o"

# External object files for target connect
connect_EXTERNAL_OBJECTS =

codes/connect: codes/CMakeFiles/connect.dir/connect.o
codes/connect: cppconn/libmysqlcppconn-static.a
codes/connect: codes/CMakeFiles/connect.dir/build.make
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX executable connect"
	cd /optemo/site/lib/c_code/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/connect.dir/cmake_clean_target.cmake
	cd /optemo/site/lib/c_code/clusteringCode/codes && /usr/bin/c++     -headerpad_max_install_names -fPIC $(connect_OBJECTS) $(connect_EXTERNAL_OBJECTS)  -o connect  -L/usr/local/mysql/lib -L/optemo/site/lib/c_code/clusteringCode/cppconn -lmysqlcppconn-static -lmysqlclient_r 

# Rule to build all files generated by this target.
codes/CMakeFiles/connect.dir/build: codes/connect

codes/CMakeFiles/connect.dir/requires: codes/CMakeFiles/connect.dir/connect.o.requires

codes/CMakeFiles/connect.dir/clean:
	cd /optemo/site/lib/c_code/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/connect.dir/cmake_clean.cmake

