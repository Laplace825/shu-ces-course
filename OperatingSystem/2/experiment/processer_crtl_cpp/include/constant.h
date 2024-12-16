#pragma once

#include <cstdint>

namespace os {

enum class SechdulerType : uint8_t {
    PriorityFirst, // Priority Scheduling
    RoundRobin,    // Round Robin
};

enum class Err : uint8_t {
    NoRunningProcess = 0,
    NoEnoughProcess,
    PcbCreateFailed,
    PcbInsertEmpty,
    PcbInsertHead,
    PcbExist,
};

} // namespace os
