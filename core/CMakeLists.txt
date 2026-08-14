cmake_minimum_required(VERSION 3.22)
project(MobileFortressCore CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Fetch godot-cpp
include(FetchContent)
FetchContent_Declare(
    godot-cpp
    GIT_REPOSITORY https://github.com/godotengine/godot-cpp.git
    GIT_TAG        godot-4.2.2-stable
)
FetchContent_MakeAvailable(godot-cpp)

# EnTT from FetchContent
FetchContent_Declare(
    EnTT
    GIT_REPOSITORY https://github.com/skypjack/entt.git
    GIT_TAG        v3.13.0
)
FetchContent_MakeAvailable(EnTT)

# FlatBuffers from FetchContent
FetchContent_Declare(
    flatbuffers
    GIT_REPOSITORY https://github.com/google/flatbuffers.git
    GIT_TAG        v23.5.26
)
set(FLATBUFFERS_BUILD_TESTS OFF CACHE BOOL "Disable flatbuffers tests" FORCE)
set(FLATBUFFERS_BUILD_FLATC ON CACHE BOOL "Build flatc" FORCE)
FetchContent_MakeAvailable(flatbuffers)

# Generate FlatBuffers header
set(SCHEMA_FILE "${CMAKE_CURRENT_SOURCE_DIR}/src/schema/simulation_state.fbs")
set(GENERATED_HEADER "${CMAKE_CURRENT_BINARY_DIR}/simulation_state_generated.h")
add_custom_command(
    OUTPUT ${GENERATED_HEADER}
    COMMAND flatc -c -o "${CMAKE_CURRENT_BINARY_DIR}" "${SCHEMA_FILE}"
    DEPENDS flatc "${SCHEMA_FILE}"
)

# Source files
file(GLOB_RECURSE SOURCES "src/cpp/*.cpp" "src/cpp/*.h" "src/cpp/*.hpp")

# GDExtension library
add_library(mobile_fortress_core SHARED ${SOURCES} ${GENERATED_HEADER})
target_include_directories(mobile_fortress_core PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_link_libraries(mobile_fortress_core PRIVATE godot::cpp EnTT::EnTT flatbuffers)

# Native C++ suite (Q3/S7) — no Godot process / godot-cpp
FetchContent_Declare(
    doctest
    GIT_REPOSITORY https://github.com/doctest/doctest.git
    GIT_TAG        v2.4.11
)
# doctest 2.4.11 still declares cmake_minimum_required < 3.5
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
FetchContent_MakeAvailable(doctest)

enable_testing()
add_executable(sim_world_tests
    src/cpp/sim_world.cpp
    tests/native/sim_world_test.cpp
    ${GENERATED_HEADER}
)
target_include_directories(sim_world_tests PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src/cpp"
    "${CMAKE_CURRENT_BINARY_DIR}"
)
target_link_libraries(sim_world_tests PRIVATE flatbuffers doctest::doctest)
add_test(NAME sim_world_tests COMMAND sim_world_tests)
