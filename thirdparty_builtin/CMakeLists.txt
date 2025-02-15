# Copyright (c) 2017-2024, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

set(_blt_tpl_targets) # tracks names of enabled tpl targets

if(ENABLE_GBENCHMARK OR ENABLE_GTEST OR ENABLE_GMOCK)
  if("${CMAKE_CXX_STANDARD}" STREQUAL "" OR
     "${CMAKE_CXX_STANDARD}" LESS 14)
      message(WARNING "GoogleTest, GoogleMock, and GoogleBenchmark require C++14 or later. "
                      "Set BLT_CXX_STD to 'c++14' or higher before loading BLT.")
  endif()
endif()

# NOTE: GoogleBenchmark, GoogleTest, and GoogleMock all rely on GNUInstallDir.
# This was causing bleeding of settings in BLT projects that don't use that,
# so we removed it and temporarily created variables it was creating, if the user
# project has not set them already. These are restored to their values below.
set(CMAKE_INSTALL_BINDIR_saved ${CMAKE_INSTALL_BINDIR})
if(NOT CMAKE_INSTALL_BINDIR)
  set(CMAKE_INSTALL_BINDIR "bin")
endif()

set(CMAKE_INSTALL_DOCDIR_saved ${CMAKE_INSTALL_DOCDIR})
if(NOT CMAKE_INSTALL_DOCDIR)
  set(CMAKE_INSTALL_DOCDIR "share/docs")
endif()

set(CMAKE_INSTALL_INCLUDEDIR_saved ${CMAKE_INSTALL_INCLUDEDIR})
if(NOT CMAKE_INSTALL_INCLUDEDIR)
  set(CMAKE_INSTALL_INCLUDEDIR "include")
endif()

set(CMAKE_INSTALL_LIBDIR_saved ${CMAKE_INSTALL_LIBDIR})
if(NOT CMAKE_INSTALL_LIBDIR)
  set(CMAKE_INSTALL_LIBDIR "lib")
endif()

if(ENABLE_TESTS)
    include(CTest)

    # Note: Users can pass extra compiler flags to gtest 
    #       with the 'gtest_extra_flags' variable and extra 
    #       compile definitions with the 'gtest_defines' variable.


    # The following flag should be added to gtest's dependents, 
    # but not to gtest in shared Windows builds
    if(WIN32 AND BUILD_SHARED_LIBS)
        list(APPEND gtest_export_defines "-DGTEST_LINKED_AS_SHARED_LIBRARY=1")
    endif()

    # Explicitly enable/disable death tests
    if(ENABLE_GTEST_DEATH_TESTS)
        list(APPEND gtest_defines "-DGTEST_HAS_DEATH_TEST=1")
    else()
        list(APPEND gtest_defines "-DGTEST_HAS_DEATH_TEST=0")
    endif()

    if(gtest_disable_pthreads)
      list(APPEND gtest_defines "-DGTEST_HAS_PTHREAD=0")
    endif()

    #
    # Use BLT's ENABLE_GMOCK option to set the build options for 
    # gtest's cmake project
    #
    
    if(ENABLE_GMOCK)
        
        # In BLT ENABLE_GMOCK implies ENABLE_GTEST,
        # IF ENABLE_GTEST is OFF, force to ON
        if(NOT ENABLE_GTEST)
            set(ENABLE_GTEST ON CACHE BOOL "")
        endif()
        
        set(BUILD_GMOCK ON  CACHE BOOL "")
        set(BUILD_GTEST OFF CACHE BOOL "")
    else()
        set(BUILD_GMOCK OFF CACHE BOOL "")
        set(BUILD_GTEST ON  CACHE BOOL "")
    endif()

    message(STATUS "Google Test Support is ${ENABLE_GTEST}")
    message(STATUS "Google Mock Support is ${ENABLE_GMOCK}")

    # GoogleMock and GoogleTest both require the C language enabled.
    # This can cause problems due to the language being enabled globally
    # but variables like CMAKE_C_COMPILE_OBJECT being created directory scoped.
    # Enable the C language for them but omit a warning.
    if(ENABLE_GTEST OR ENABLE_GMOCK)
      get_property(_enabled_langs GLOBAL PROPERTY ENABLED_LANGUAGES)
      if(NOT "C" IN_LIST _enabled_langs)
          message(WARNING "Enabling the C language due to Google Mock|Test requiring it. To quiet this warning, add C to your project(...) call.")
          enable_language(C)
      endif()
    endif()

    #
    # Guard of googletest w/ ENABLE_GTEST
    # In BLT, ENABLE_GTEST is also required when using ENABLE_GMOCK
    #
    
    if(ENABLE_GTEST)
        
        #
        # gtest 1.8 emits many warnings related to dll-interface 
        # issues on windows, so we add flags to work around these
        # warnings, so they don't mask warnings we care about
        #
        # For more info see: https://github.com/LLNL/blt/issues/79
        # 
        
        blt_append_custom_compiler_flag( FLAGS_VAR gtest_extra_flags
                                         DEFAULT " " 
                                         MSVC  "/wd4251" "/wd4275" )

        set (INSTALL_GMOCK OFF CACHE BOOL "")
        set (INSTALL_GTEST OFF CACHE BOOL "")

        # Enable builtin google test 
        add_subdirectory(googletest
                         ${BLT_BUILD_DIR}/thirdparty_builtin/googletest)

        if(UNIX AND NOT APPLE)
            find_package( Threads )
            set(gtest_extra_libs ${CMAKE_THREAD_LIBS_INIT})
        endif()

        blt_register_library(NAME gtest
                             INCLUDES ${gtest_SOURCE_DIR}/include
                             LIBRARIES gtest_main gtest ${gtest_extra_libs}
                             COMPILE_FLAGS ${gtest_extra_flags}
                             DEFINES  ${gtest_defines} ${gtest_export_defines}
                             TREAT_INCLUDES_AS_SYSTEM ON
                             )

        blt_add_target_definitions(TO gtest TARGET_DEFINITIONS ${gtest_defines})

        list(APPEND _blt_tpl_targets gtest gtest_main)

        if(ENABLE_GMOCK)
            blt_register_library(NAME gmock
                                 INCLUDES ${gmock_SOURCE_DIR}/include
                                 LIBRARIES gmock_main gmock
                                 COMPILE_FLAGS ${gtest_extra_flags}
                                 DEFINES  ${gtest_defines}
                                 TREAT_INCLUDES_AS_SYSTEM ON
                                 )
            list(APPEND _blt_tpl_targets gmock gmock_main)
        endif()
    endif()

    # Enable Fruit (FortRan UnIT testing) support
    if (ENABLE_FORTRAN)
        message(STATUS "Fruit Support is ${ENABLE_FRUIT}")
        message(STATUS "Fruit MPI Support is ${ENABLE_FRUIT_MPI}")
        if(ENABLE_FRUIT)
            add_subdirectory(fruit-3.4.1
                             ${BLT_BUILD_DIR}/thirdparty_builtin/fruit-3.4.1)
	    list(APPEND _blt_tpl_targets fruit)
	    if(ENABLE_MPI AND ENABLE_FRUIT_MPI)
	        list(APPEND _blt_tpl_targets fruit_mpi)
	    endif()
        endif()
    endif()

endif()

if(ENABLE_BENCHMARKS)
    if(NOT ENABLE_TESTS)
        message(FATAL_ERROR "ENABLE_BENCHMARKS requires ENABLE_TESTS to be ON")
    endif()

    message(STATUS "Google Benchmark Support is ${ENABLE_GBENCHMARK}")

    if(ENABLE_GBENCHMARK)
        if(WIN32 AND BUILD_SHARED_LIBS)
          message(FATAL_ERROR "Google Benchmark cannot be built when BUILD_SHARED_LIBS=ON or on Windows")
        endif()

        set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "")
        add_subdirectory(benchmark-1.8.0
                         ${BLT_BUILD_DIR}/thirdparty_builtin/benchmark-1.8.0)

        if (UNIX AND NOT APPLE)
          find_library(RT_LIBRARIES rt)
        endif()

        blt_register_library(NAME      gbenchmark
                             INCLUDES  ${benchmark_SOURCE_DIR}/include ${benchmark_SOURCE_DIR}
                             LIBRARIES benchmark ${RT_LIBRARIES}
                             TREAT_INCLUDES_AS_SYSTEM ON)

        list(APPEND _blt_tpl_targets gbenchmark)
    endif()

    # This sets up a target to run the benchmarks
    add_custom_target(${BLT_RUN_BENCHMARKS_TARGET_NAME}
                      COMMAND ctest -C Benchmark -L Benchmark -VV
                      WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
endif()

# Restore user set install variables

foreach(_var CMAKE_INSTALL_BINDIR CMAKE_INSTALL_DOCDIR CMAKE_INSTALL_INCLUDEDIR CMAKE_INSTALL_LIBDIR)
    if(${_var}_saved)
      set(${_var} ${${_var}_saved} CACHE PATH "")
    endif()
endforeach()

# Set the folder property of the blt thirdparty libraries 
if(ENABLE_FOLDERS)
    foreach(tpl ${_blt_tpl_targets})
        blt_set_target_folder(TARGET ${tpl} FOLDER blt/thirdparty)
    endforeach()
endif()
