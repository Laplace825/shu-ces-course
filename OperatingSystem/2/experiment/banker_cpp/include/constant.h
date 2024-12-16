#pragma once

#include <cstdint>

namespace banker {

// how many types of resources
constexpr uint8_t SystemResourcesTypeNum = 4;

enum class Err : uint8_t {
    RequireBeyondMaxResources = 0,
    RequireBeyondCurrentResources,
    NotEnoughRecources,
    ProcessNotExist,
    NoSafeSequence,
};

enum class SystemResourcesType : uint8_t {
    IOTypst = 0,
    Memory,
    Buffer,
    Bus,
};

// Max resources for each system resources
enum class MaxSystemResources : uint8_t {
    IOTypst = 10,
    Memory  = 5,
    Buffer  = 7,
    Bus     = 10,
};

#define getMaxSystemResourcesNum(type) \
    static_cast< uint8_t >(::banker::MaxSystemResources::type)

#define transSystemResource2int(type) \
    static_cast< uint8_t >(::banker::SystemResourcesType::type)
} // namespace banker
