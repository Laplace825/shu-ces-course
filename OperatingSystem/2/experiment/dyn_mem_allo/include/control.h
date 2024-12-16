#pragma once

#include <cstddef>
#include <cstring>
#include <print>

#include "constant.h"
#include "memlist.h"
#include "memtable.h"

namespace os {

class MemControl {
  private:
    const uint32_t m_max_size;
    DynamicMemAllocType m_alloc_type;
    MemIdleTable m_idle_table;
    MemList m_mem_list;

  private:
    Result alloc_first_fit(job_id_t id, uint32_t size) noexcept;
    Result alloc_recursive_first_fit(job_id_t id, uint32_t size) noexcept;
    Result alloc_best_fit(job_id_t id, uint32_t size) noexcept;
    Result alloc_worst_fit(job_id_t id, uint32_t size) noexcept;
    Result alloc_bw_fit_impl(job_id_t id, uint32_t size, bool asc) noexcept;

  public:
    MemControl(DynamicMemAllocType type = DynamicMemAllocType::FirstFit)
        : m_max_size(MaxMemSize), m_alloc_type(type) {
        m_idle_table.insert({
          0, {.idle_begin = 0,
              .idle_size = m_max_size,
              .begin     = 0,
              .state     = MemState::Idle}
        });
        m_mem_list.push_back(new MemNode{.id = {.par_num = 0},
          .begin                             = 0,
          .size                              = m_max_size,
          .prev                              = nullptr,
          .next                              = nullptr,
          .state                             = MemState::Idle});
    }

    ~MemControl() {}

    void show_all() const noexcept;
    void show_idle_mem() const noexcept;

    Result free_job(job_id_t id) noexcept;

    Result alloc_job(job_id_t id, uint32_t size) noexcept {
        if (size > m_max_size) {
            return Error(Err::OutOfMem);
        }

        switch (m_alloc_type) {
            case DynamicMemAllocType::FirstFit:
                return alloc_first_fit(id, size);
            case DynamicMemAllocType::RecursiveFirstFit:
                return alloc_recursive_first_fit(id, size);
            case DynamicMemAllocType::BestFit:
                return alloc_best_fit(id, size);
            case DynamicMemAllocType::WorstFit:
                return alloc_worst_fit(id, size);
        }
    }
};

} // namespace os
