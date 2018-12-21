cmake_minimum_required(VERSION 3.12)
project(netube)

add_custom_target(netube ALL
        COMMAND swift build
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        SOURCES Sources/netube/main.swift)
