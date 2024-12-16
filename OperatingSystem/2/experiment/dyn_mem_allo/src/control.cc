#include "control.h"

#include <algorithm>
#include <print>
#include <ranges>
#include <utility>

#include "constant.h"
#include "memlist.h"

namespace os {

void MemControl::show_all() const noexcept {
    m_mem_list.show([](auto* cur) { return true; });
    std::println();
}

void MemControl::show_idle_mem() const noexcept {
    std::println("   ");
    for (const auto& [key, item] : m_idle_table) {
        std::println("-> Partial {}", key);
        std::println("\t | <idle_begin>: {:^4d}\t |\n"
                     "\t | <idle_size>: {:^4d}\t | \n"
                     "\t | <State>: {}\t |",
          item.idle_begin, item.idle_size, state_to_string(item.state));
    }

    // m_mem_list.show([](auto* cur) { return cur->state == MemState::Idle; });
}

Result MemControl::free_job(job_id_t id) noexcept {
    auto [job_node, e] = m_mem_list.find_job_by_id(id);
    if (!e.has_value()) {
        return e;
    }
    if (job_node->state == MemState::Idle) {
        return Error(Err::FreeMemForIdleMem);
    }
    // now the job_node must be a job
    auto job_node_next = job_node->next;
    auto job_node_prev = job_node->prev;
    uint8_t condition  = 0b0000;
    if (job_node_prev && job_node_prev->state == MemState::Idle) {
        condition = 0b1100;
    }
    else if (!job_node_prev) {
        condition = 0b0000;
    }

    if (job_node_next && job_node_next->state == MemState::Idle) {
        condition |= 0b0011;
    }

    // 1111 for both side is idle
    // 1100 for prev is idle
    // 0011 for next is idle
    // 0000 for both side is not idle(nullptr)
    switch (condition) {
        case 0b1111: {
            auto job_node_next_next = job_node_next->next;
            job_node_prev->size += job_node->size + job_node_next->size;
            auto e = m_mem_list.remove_job(job_node->id.id);
            patritial_num_t small_par_num = std::min(
              job_node_prev->next->id.par_num, job_node_prev->id.par_num);
            patritial_num_t bigger_par_num = std::max(
              job_node_prev->next->id.par_num, job_node_prev->id.par_num);
            auto& item_smaller        = m_idle_table.at(small_par_num);
            item_smaller.begin        = job_node_prev->begin;
            item_smaller.state        = MemState::Idle;
            item_smaller.idle_size    = job_node_prev->size;
            item_smaller.idle_begin   = job_node_prev->begin;
            job_node_prev->id.par_num = small_par_num;
            m_idle_table.erase(bigger_par_num);
            if (!e.has_value()) {
                return e;
            }
            job_node_prev->next->prev = nullptr;
            job_node_prev->next->next = nullptr;
            delete job_node_prev->next;
            job_node_prev->next = job_node_next_next;
            if (job_node_prev->next->next) {
                job_node_prev->next->next->prev = job_node_prev;
            }
            return !e.has_value() ? e : true;
        }
        case 0b1100: {
            job_node_prev->size += job_node->size;
            job_node_prev->state = MemState::Idle;

            auto e = m_mem_list.remove_job(job_node->id.id);
            m_idle_table.at(job_node_prev->id.par_num).idle_size =
              job_node_prev->size;

            return !e.has_value() ? e : true;
        }
        case 0b0011: {
            job_node_next->size += job_node->size;
            job_node_next->begin = job_node->begin;
            auto& item           = m_idle_table.at(job_node_next->id.par_num);
            item.idle_begin      = job_node_next->begin;
            item.idle_size       = job_node_next->size;
            auto e               = m_mem_list.remove_job(job_node->id.id);
            return !e.has_value() ? e : true;
        }
        default: {
            job_node->state = MemState::Idle;
            // find the biggest par_num in m_idle_table
            patritial_num_t gen_par_num = 0;
            for (auto k : std::views::keys(m_idle_table)) {
                gen_par_num = std::max(gen_par_num, k);
            }

            job_node->id.par_num = gen_par_num + 1;
            m_idle_table.insert({
              job_node->id.par_num, {.idle_begin = job_node->begin,
                                     .idle_size = job_node->size,
                                     .begin     = job_node->begin,
                                     .state     = MemState::Idle}
            });
            return true;
        }
    }
    return true;
}

Result MemControl::alloc_first_fit(job_id_t id, uint32_t size) noexcept {
    if (size > m_max_size) {
        return Error(Err::OutOfMem);
    }
    auto [mem_node, e] = m_mem_list.find_enough_idle_mem(size);
    if (!e.has_value()) {
        return e;
    }

    if (mem_node->size == size) {
        mem_node->state = MemState::Full;
        m_idle_table.erase(mem_node->id.par_num);
        mem_node->id.id = id;
        return true;
    }

    auto job_node   = new MemNode();
    job_node->id.id = id;
    job_node->begin = mem_node->begin;
    job_node->size  = size;
    job_node->state = MemState::Used;

    mem_node->size -= size;
    mem_node->begin += size;
    mem_node->state = MemState::Idle;

    auto& item      = m_idle_table.at(mem_node->id.par_num);
    item.idle_size  = mem_node->size;
    item.idle_begin = mem_node->begin;
    item.state      = MemState::Idle;

    auto mem_node_prev = mem_node->prev;
    if (!mem_node_prev) {
        job_node->next = mem_node;
        mem_node->prev = job_node;
        job_node->prev = nullptr;

        m_mem_list.update_head_from(mem_node);
        return true;
    }

    job_node->next      = mem_node;
    job_node->prev      = mem_node_prev;
    mem_node->prev      = job_node;
    mem_node_prev->next = job_node;
    m_mem_list.update_head_from(mem_node);
    return true;
}

Result MemControl::alloc_recursive_first_fit(
  job_id_t id, uint32_t size) noexcept {
    if (size > m_max_size) {
        return Error(Err::OutOfMem);
    }

    // FIXME: Cur will pointer to Invalid mem because of free (which merge idle
    // mem)
    static MemNode* cur = m_mem_list.m_head;

    while (cur->state != MemState::Idle) {
        cur = cur->next;
    }

    auto tmp = cur;

    while (cur && !(cur->size >= size && cur->state == MemState::Idle)) {
        cur = cur->next;
    }

    if (!cur) {
        cur = m_mem_list.m_head;

        while (cur != tmp) {
            if (cur->size >= size && cur->state == MemState::Idle) {
                break;
            }
            cur = cur->next;
        }
        if (cur == tmp) {
            return Error(Err::NoEnoughIdlePartialMem2Alloc);
        }
    }

    if (!cur) {
        return Error(Err::NoEnoughIdlePartialMem2Alloc);
    }

    if (cur->size == size) {
        cur->state = MemState::Full;
        m_idle_table.erase(cur->id.par_num);
        cur->id.id = id;

        cur = cur->next;
        while (cur && cur->state != MemState::Idle) {
            cur = cur->next;
        }
        if (!cur) {
            cur = m_mem_list.m_head;
            while (cur->state != MemState::Idle) {
                cur = cur->next;
            }
        }
        return true;
    }

    auto job_node   = new MemNode();
    job_node->id.id = id;
    job_node->begin = cur->begin;
    job_node->size  = size;
    job_node->state = MemState::Used;

    cur->size -= size;
    cur->begin += size;
    cur->state = MemState::Idle;

    auto& item      = m_idle_table.at(cur->id.par_num);
    item.idle_size  = tmp->size;
    item.idle_begin = tmp->begin;
    item.state      = MemState::Idle;

    auto cur_prev = cur->prev;
    if (!cur_prev) {
        // cur_prev is nullptr
        job_node->next = cur;
        cur->prev      = job_node;
        job_node->prev = nullptr;

        m_mem_list.update_head_from(cur);

        cur = cur->next;
        while (cur && cur->state != MemState::Idle) {
            cur = cur->next;
        }
        if (!cur) {
            cur = m_mem_list.m_head;

            while (cur->state != MemState::Idle) {
                cur = cur->next;
            }
        }

        return true;
    }

    job_node->next = cur;
    job_node->prev = cur_prev;
    cur->prev      = job_node;
    cur_prev->next = job_node;
    m_mem_list.update_head_from(cur);
    cur = cur->next;
    while (cur && cur->state != MemState::Idle) {
        cur = cur->next;
    }
    if (!cur) {
        cur = m_mem_list.m_head;

        while (cur->state != MemState::Idle) {
            cur = cur->next;
        }
    }

    return true;
}

Result MemControl::alloc_bw_fit_impl(
  job_id_t id, uint32_t size, bool asc) noexcept {
    auto copyted = m_mem_list.copy();
    // m_mem_list.sort(false);
    copyted.sort(asc);
    if (size > m_max_size) {
        return Error(Err::OutOfMem);
    }
    auto [tmp, e] = copyted.find_enough_idle_mem(size);
    auto mem_node = m_mem_list.m_head;
    while (mem_node->id.par_num != tmp->id.par_num ||
           mem_node->state != MemState::Idle)
    {
        mem_node = mem_node->next;
    }

    if (!e.has_value()) {
        return e;
    }

    if (mem_node->size == size) {
        mem_node->state = MemState::Full;
        m_idle_table.erase(mem_node->id.par_num);
        mem_node->id.id = id;
        return true;
    }

    auto job_node   = new MemNode();
    job_node->id.id = id;
    job_node->begin = mem_node->begin;
    job_node->size  = size;
    job_node->state = MemState::Used;

    mem_node->size -= size;
    mem_node->begin += size;
    mem_node->state = MemState::Idle;

    auto& item      = m_idle_table.at(mem_node->id.par_num);
    item.idle_size  = mem_node->size;
    item.idle_begin = mem_node->begin;
    item.state      = MemState::Idle;

    auto mem_node_prev = mem_node->prev;
    if (!mem_node_prev) {
        job_node->next = mem_node;
        mem_node->prev = job_node;
        job_node->prev = nullptr;

        m_mem_list.update_head_from(mem_node);
        return true;
    }

    job_node->next      = mem_node;
    job_node->prev      = mem_node_prev;
    mem_node->prev      = job_node;
    mem_node_prev->next = job_node;
    m_mem_list.update_head_from(mem_node);
    return true;
}

Result MemControl::alloc_best_fit(job_id_t id, uint32_t size) noexcept {
    return alloc_bw_fit_impl(id, size, true);
}

Result MemControl::alloc_worst_fit(job_id_t id, uint32_t size) noexcept {
    return alloc_bw_fit_impl(id, size, false);
}

} // namespace os
