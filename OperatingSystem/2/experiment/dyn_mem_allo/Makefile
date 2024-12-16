ROOT=$(pwd)
TARGET=dyn_allo_mem

build-debug: 
	cmake -B build -G Ninja -S . \
  	-DCMAKE_BUILD_TYPE="Debug"
	ninja -v -C build

build-release: 
	cmake -B build -G Ninja -S . \
  	-DCMAKE_BUILD_TYPE="Release"
	ninja -v -C build

clean: 	
	rm -rf build
	rm -rf ./bin/*

rd: build-debug
	./bin/debug/$(TARGET)

rr: build-release
	./bin/release/$(TARGET)

all: build-debug build-release

.PHONY: build-debug build-release clean rr rd all

default: all
