#pragma once

#include <cstdint>
#include <expected>
#include <string>

namespace os {

using byte = uint8_t;

using patritial_num_t         = uint32_t;
using job_id_t                = uint32_t;
constexpr uint32_t MaxMemSize = 640;

enum class MemState : uint16_t { Idle, Full, Used };

constexpr inline std::string state_to_string(MemState state) {
    switch (state) {
        case MemState::Idle:
            return "Idle";
        case MemState::Full:
            return "Full";
        case MemState::Used:
            return "Used";
        default:
            return "Unknown";
    }
}

enum class DynamicMemAllocType : uint8_t {
    FirstFit = 0,
    RecursiveFirstFit,
    BestFit,
    WorstFit,
};

enum class Err : uint8_t {
    OutOfMem = 0,
    NoThatAllocMethod,
    NoThatPartital,
    CanNotInsertAnExistIdleMem,
    NoEnoughIdlePartialMem2Alloc,
    SortError,
    NoThatJob,
    FreeMemBiggerThanJobHold,
    AllocMemForExistJob,
    FreeMemForIdleMem,
    CanNotMergeAJob,
    
};

using Result = std::expected< bool, Err >;
using Error  = std::unexpected< Err >;

} // namespace os
