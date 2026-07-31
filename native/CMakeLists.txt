cmake_minimum_required(VERSION 3.22.1)
project(retrohub_native LANGUAGES CXX)

add_library(retro_bridge SHARED libretro_bridge.cpp)
set_target_properties(retro_bridge PROPERTIES
    OUTPUT_NAME "retro_bridge"
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS NO
)

if(ANDROID)
    target_link_libraries(retro_bridge PRIVATE dl log)
elseif(UNIX)
    target_link_libraries(retro_bridge PRIVATE dl)
endif()
