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

# Source files
file(GLOB_RECURSE SOURCES "src/cpp/*.cpp" "src/cpp/*.h" "src/cpp/*.hpp")

# GDExtension library
add_library(mobile_fortress_core SHARED ${SOURCES})
target_link_libraries(mobile_fortress_core PRIVATE godot::cpp EnTT::EnTT)
