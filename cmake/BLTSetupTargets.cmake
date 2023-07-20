# Copyright (c) 2017-2023, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

# This file is intended to be included in the *-config.cmake files of
# any project using a third-party library.  The macro 
# `blt_install_tpl_setups(DESTINATION <dir>)`  installs this file
# into the destination specified by the argument <dir>.

# BLTInstallableMacros provides helper macros for setting up and creating
# third-party library targets.
include("${CMAKE_CURRENT_LIST_DIR}/BLTInstallableMacros.cmake")
# If the generated TPL config file exists, include it here.
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/BLT-TPL-config.cmake")
  include("${CMAKE_CURRENT_LIST_DIR}/BLT-TPL-config.cmake")
# Otherwise, configure the TPL flags.  We have to prefix these variable with
# BLT so that they never conflict with user-level CMake variables in downstream
# projects.
else()
  set(BLT_ENABLE_CUDA         ${ENABLE_CUDA})
  set(BLT_ENABLE_HIP          ${ENABLE_HIP})
  set(BLT_ENABLE_MPI          ${ENABLE_MPI})
  set(BLT_ENABLE_OPENMP       ${ENABLE_OPENMP})
  set(BLT_ENABLE_FIND_MPI     ${ENABLE_FIND_MPI})
  set(BLT_ENABLE_CLANG_CUDA   ${ENABLE_CLANG_CUDA})
endif()

# Detect if Fortran has been introduced.
get_property(_languages GLOBAL PROPERTY ENABLED_LANGUAGES)
if(_languages MATCHES "Fortran")
    set(_fortran_already_enabled TRUE)
else()
    set(_fortran_already_enabled FALSE)
endif()

# Only update ENABLE_FORTRAN if it is a new requirement, don't turn 
# the flag off if required by an upstream dependency.
if (NOT ENABLE_FORTRAN)
  set(BLT_ENABLE_FORTRAN ${_fortran_already_enabled})
else()
  set(BLT_ENABLE_FORTRAN ENABLE_FORTRAN)
endif()

#------------------------------------
# MPI
#------------------------------------
message(STATUS "MPI Support is ${BLT_ENABLE_MPI}")
if (BLT_ENABLE_MPI AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupMPI.cmake")
  include("${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupMPI.cmake")
endif()


#------------------------------------
# OpenMP
#------------------------------------
message(STATUS "OpenMP Support is ${BLT_ENABLE_OPENMP}")
if (BLT_ENABLE_OPENMP AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupOpenMP.cmake")
  include("${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupOpenMP.cmake")
endif()


#------------------------------------
# CUDA
#------------------------------------
message(STATUS "CUDA Support is ${BLT_ENABLE_CUDA}")
if (BLT_ENABLE_CUDA AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupCUDA.cmake")
  include("${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupCUDA.cmake")
endif()


#------------------------------------
# HIP
#------------------------------------
message(STATUS "HIP Support is ${BLT_ENABLE_HIP}")
if (BLT_ENABLE_HIP AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupHIP.cmake")
  include("${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupHIP.cmake")
endif()
