## ---------------------------------------------------------------------
##
## Copyright (C) 2021 - 2023 by the deal.II authors
##
## This file is part of the deal.II library.
##
## The deal.II library is free software; you can use it, redistribute
## it, and/or modify it under the terms of the GNU Lesser General
## Public License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
## The full text of the license can be found in the file LICENSE.md at
## the top level directory of deal.II.
##
## ---------------------------------------------------------------------

#
# Try to find the Kokkos library
#
# This module exports
#
#   KOKKOS_INCLUDE_DIRS
#   KOKKOS_INTERFACE_LINK_FLAGS
#

set(KOKKOS_DIR "" CACHE PATH "An optional hint to a Kokkos installation")
set_if_empty(KOKKOS_DIR "$ENV{KOKKOS_DIR}")


if(DEAL_II_TRILINOS_WITH_KOKKOS OR DEAL_II_PETSC_WITH_KOKKOS)
  # Let ArborX know that we have found Kokkos
  set(Kokkos_FOUND ON)
  # Let deal.II know that we have found Kokkos
  set(KOKKOS_FOUND ON)
else()
  # silence a warning when including FindKOKKOS.cmake
  set(CMAKE_CXX_EXTENSIONS OFF)
  find_package(Kokkos 3.7.0 QUIET
    HINTS ${KOKKOS_DIR} ${Kokkos_DIR} $ENV{Kokkos_DIR}
    )

  set(KOKKOS_FOUND ${Kokkos_FOUND})

  if(Kokkos_FOUND)
    # We need to disable SIMD vectorization for CUDA device code.
    # Otherwise, nvcc compilers from version 9 on will emit an error message like:
    # "[...] contains a vector, which is not supported in device code". We
    # would like to set the variable in check_01_cpu_feature but at that point
    # we don't know if CUDA support is enabled in Kokkos
    if(Kokkos_ENABLE_CUDA)
      set(DEAL_II_VECTORIZATION_WIDTH_IN_BITS 0)
      # Require lambda support to use Kokkos as a backend
      KOKKOS_CHECK(OPTIONS CUDA_LAMBDA)

      # Disable a bunch of annoying warnings generated by boost, template code,
      # and in other random places:
      #
      # integer conversion resulted in a change of sign:
      enable_if_supported(DEAL_II_CXX_FLAGS "-Xcudafe --diag_suppress=68")
      # variable "i" was set but never used:
      enable_if_supported(DEAL_II_CXX_FLAGS "-Xcudafe --diag_suppress=550")
      # loop is not reachable:
      enable_if_supported(DEAL_II_CXX_FLAGS "-Xcudafe --diag_suppress=128")
      # warning #186-D: pointless comparison of unsigned integer with zero
      enable_if_supported(DEAL_II_CXX_FLAGS "-Xcudafe --diag_suppress=186")
      # warning #177-D: variable "n_max_face_orientations" was declared but never referenced
      enable_if_supported(DEAL_II_CXX_FLAGS "-Xcudafe --diag_suppress=177")
      # warning #284-D: NULL reference is not allowed
      enable_if_supported(DEAL_II_CXX_FLAGS "-Xcudafe --diag_suppress=284")
    endif()
  endif()

  set(_target Kokkos::kokkos)
  process_feature(KOKKOS
    TARGETS REQUIRED _target
    )
endif()
