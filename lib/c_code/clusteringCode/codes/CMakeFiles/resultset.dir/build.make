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
include codes/CMakeFiles/resultset.dir/depend.make

# Include the progress variables for this target.
include codes/CMakeFiles/resultset.dir/progress.make

# Include the compile flags for this target's objects.
include codes/CMakeFiles/resultset.dir/flags.make

codes/CMakeFiles/resultset.dir/depend.make.mark: codes/CMakeFiles/resultset.dir/flags.make
codes/CMakeFiles/resultset.dir/depend.make.mark: codes/resultset.cpp

codes/CMakeFiles/resultset.dir/resultset.o: codes/CMakeFiles/resultset.dir/flags.make
codes/CMakeFiles/resultset.dir/resultset.o: codes/resultset.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /optemo/site/lib/c_code/clusteringCode/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object codes/CMakeFiles/resultset.dir/resultset.o"
	/usr/bin/c++   $(CXX_FLAGS) -o codes/CMakeFiles/resultset.dir/resultset.o -c /optemo/site/lib/c_code/clusteringCode/codes/resultset.cpp

codes/CMakeFiles/resultset.dir/resultset.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to codes/CMakeFiles/resultset.dir/resultset.i"
	/usr/bin/c++  $(CXX_FLAGS) -E /optemo/site/lib/c_code/clusteringCode/codes/resultset.cpp > codes/CMakeFiles/resultset.dir/resultset.i

codes/CMakeFiles/resultset.dir/resultset.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly codes/CMakeFiles/resultset.dir/resultset.s"
	/usr/bin/c++  $(CXX_FLAGS) -S /optemo/site/lib/c_code/clusteringCode/codes/resultset.cpp -o codes/CMakeFiles/resultset.dir/resultset.s

codes/CMakeFiles/resultset.dir/resultset.o.requires:

codes/CMakeFiles/resultset.dir/resultset.o.provides: codes/CMakeFiles/resultset.dir/resultset.o.requires
	$(MAKE) -f codes/CMakeFiles/resultset.dir/build.make codes/CMakeFiles/resultset.dir/resultset.o.provides.build

codes/CMakeFiles/resultset.dir/resultset.o.provides.build: codes/CMakeFiles/resultset.dir/resultset.o

codes/CMakeFiles/resultset.dir/depend: codes/CMakeFiles/resultset.dir/depend.make.mark

codes/CMakeFiles/resultset.dir/depend.make.mark:
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --magenta --bold "Scanning dependencies of target resultset"
	cd /optemo/site/lib/c_code/clusteringCode && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /optemo/site/lib/c_code/clusteringCode /optemo/site/lib/c_code/clusteringCode/codes /optemo/site/lib/c_code/clusteringCode /optemo/site/lib/c_code/clusteringCode/codes /optemo/site/lib/c_code/clusteringCode/codes/CMakeFiles/resultset.dir/DependInfo.cmake

# Object files for target resultset
resultset_OBJECTS = \
"CMakeFiles/resultset.dir/resultset.o"

# External object files for target resultset
resultset_EXTERNAL_OBJECTS =

codes/resultset: codes/CMakeFiles/resultset.dir/resultset.o
codes/resultset: cppconn/libmysqlcppconn-static.a
codes/resultset: codes/CMakeFiles/resultset.dir/build.make
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX executable resultset"
	cd /optemo/site/lib/c_code/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/resultset.dir/cmake_clean_target.cmake
	cd /optemo/site/lib/c_code/clusteringCode/codes && /usr/bin/c++     -headerpad_max_install_names -fPIC $(resultset_OBJECTS) $(resultset_EXTERNAL_OBJECTS)  -o resultset  -L/usr/local/mysql/lib -L/optemo/site/lib/c_code/clusteringCode/cppconn -lmysqlcppconn-static -lmysqlclient_r 

# Rule to build all files generated by this target.
codes/CMakeFiles/resultset.dir/build: codes/resultset

codes/CMakeFiles/resultset.dir/requires: codes/CMakeFiles/resultset.dir/resultset.o.requires

codes/CMakeFiles/resultset.dir/clean:
	cd /optemo/site/lib/c_code/clusteringCode/codes && $(CMAKE_COMMAND) -P CMakeFiles/resultset.dir/cmake_clean.cmake

