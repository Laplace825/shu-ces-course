#pragma once
#include <map>

#include "constant.h"

namespace os {

struct MemIdleTableItem {
    uint32_t idle_begin;
    uint32_t idle_size;
    uint32_t begin;
    MemState state;
};

using MemIdleTable = std::map< patritial_num_t, MemIdleTableItem >;

} // namespace os
