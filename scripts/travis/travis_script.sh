#!/bin/bash

set -e
set -x

# main script of travis
if [ ${TASK} == "lint" ]; then
    make lint
    make doxygen 2>log.txt
    (cat log.txt| grep -v ENABLE_PREPROCESSING |grep -v "unsupported tag" |grep warning) && exit 1
    exit 0
fi

if [ ${TRAVIS_OS_NAME} == "osx" ]; then
    export NO_OPENMP=1
fi

if [ ${TASK} == "unittest_gtest" ]; then
    cp make/config.mk .
    make -f scripts/packages.mk gtest
    if [ ${TRAVIS_OS_NAME} != "osx" ]; then
        echo "USE_S3=1" >> config.mk
        echo "export CXX = g++-7" >> config.mk
    else
        echo "USE_S3=0" >> config.mk
        echo "USE_OPENMP=0" >> config.mk
    fi
    echo "GTEST_PATH="${CACHE_PREFIX} >> config.mk
    echo "BUILD_TEST=1" >> config.mk
    make all
    test/unittest/dmlc_unittest
fi

if [ ${TASK} == "cmake_test" ]; then
    # Build dmlc-core with CMake, including unit tests
    rm -rf build
    mkdir build && cd build
    if [ ${TRAVIS_OS_NAME} == "osx" ]; then
        CC=gcc-7 CXX=g++-7 cmake .. -DGOOGLE_TEST=ON
    else
        cmake .. -DGOOGLE_TEST=ON
    fi
    make
    cd ..
    ./build/test/unittest/dmlc_unit_tests
fi
