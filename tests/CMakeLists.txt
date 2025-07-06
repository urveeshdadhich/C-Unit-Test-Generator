# CMakeLists.txt for Generated Unit Tests

cmake_minimum_required(VERSION 3.16)

# Enable testing
enable_testing()

# Find required packages
find_package(Drogon REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(JSONCPP jsoncpp)

# GoogleTest setup
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/v1.14.0.zip
)

# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Include directories
include_directories(${CMAKE_SOURCE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/controllers)
include_directories(${CMAKE_SOURCE_DIR}/models)
include_directories(${CMAKE_SOURCE_DIR}/plugins)

# Compiler flags
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Coverage flags
if(ENABLE_COVERAGE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -g -O0")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
endif()

# Common libraries
set(COMMON_LIBS
    Drogon::Drogon
    gtest_main
    gmock_main
    ${JSONCPP_LIBRARIES}
)

# Find all test files
file(GLOB TEST_SOURCES "*.cc" "*Test.cc" "*_test.cc")

# Create test executable for each test file
foreach(TEST_SOURCE ${TEST_SOURCES})
    get_filename_component(TEST_NAME ${TEST_SOURCE} NAME_WE)

    # Skip if not a test file
    if(NOT ${TEST_NAME} MATCHES ".*Test$")
        continue()
    endif()

    # Create executable
    add_executable(${TEST_NAME} ${TEST_SOURCE})

    # Link libraries
    target_link_libraries(${TEST_NAME} PRIVATE ${COMMON_LIBS})

    # Add to test suite
    add_test(NAME ${TEST_NAME} COMMAND ${TEST_NAME})

    # Set test properties
    set_tests_properties(${TEST_NAME} PROPERTIES
        TIMEOUT 30
        ENVIRONMENT "GTEST_COLOR=1"
    )
endforeach()

# Create a combined test executable (optional)
if(TEST_SOURCES)
    add_executable(AllTests ${TEST_SOURCES})
    target_link_libraries(AllTests PRIVATE ${COMMON_LIBS})
    add_test(NAME AllTests COMMAND AllTests)
endif()

# Custom target for running tests with coverage
if(ENABLE_COVERAGE)
    add_custom_target(coverage
        COMMAND ${CMAKE_CTEST_COMMAND} --verbose
        COMMAND lcov --capture --directory . --output-file coverage.info
        COMMAND lcov --remove coverage.info '/usr/*' --output-file coverage.filtered.info
        COMMAND genhtml coverage.filtered.info --output-directory coverage-html
        DEPENDS AllTests
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Running tests and generating coverage report"
    )
endif()

# Install test data files
file(GLOB TEST_DATA_FILES "data/*")
if(TEST_DATA_FILES)
    file(COPY ${TEST_DATA_FILES} DESTINATION ${CMAKE_BINARY_DIR}/test_data)
endif()

message(STATUS "Found ${CMAKE_CURRENT_SOURCE_DIR} test sources: ${TEST_SOURCES}")
