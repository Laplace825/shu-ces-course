#pragma once

#include <cstdint>
#include <print>

#include "constant.h"

namespace os {

struct MemNode {
    using id_t = union {
        job_id_t id;
        patritial_num_t par_num;
    };

    id_t id;
    uint32_t begin;
    uint32_t size;
    MemNode* prev;
    MemNode* next;
    MemState state;
};

class MemList {
    friend class MemControl;

  private:
    MemNode* m_head;
    MemNode* m_tail;

  public:
    using find_type = std::pair< MemNode*, Result >;

    MemList() : m_head(nullptr), m_tail(nullptr) {}

    MemList copy() const noexcept;

    ~MemList() {
        MemNode* cur = m_head;
        while (cur != nullptr) {
            MemNode* next = cur->next;
            cur->next     = nullptr;
            cur->prev     = nullptr;
            delete cur;
            cur = next;
        }
    }

    // double direction linklist sort by idle_size
    void sort(bool asc = true) noexcept;

    template < typename Fn >
    void show(Fn&& fn) const noexcept {
        MemNode* cur = m_head;
        while (cur != nullptr && fn(cur)) {
            switch (cur->state) {
                case MemState::Idle: {
                    std::println("-> Partial {}", cur->id.par_num);
                    break;
                }
                default: {
                    std::println("-> JobId {}", cur->id.id);
                }
            }

            std::println("\t | <idle_begin>: {:^4d}\t |\n"
                         "\t | <idle_size>: {:^4d}\t | \n"
                         "\t | <State>: {}\t |",
              cur->begin, cur->size, state_to_string(cur->state));
            cur = cur->next;
        }
    }

    void push_back(MemNode* node) noexcept;

    find_type find_by_id(uint32_t id) const noexcept;
    find_type find_job_by_id(uint32_t id) const noexcept;

    find_type find_enough_idle_mem(uint32_t size) const noexcept;

    void update_head_from(MemNode* node) noexcept;

    find_type pop_front() noexcept;
    find_type pop_back() noexcept;

    find_type remove(uint32_t id) noexcept;
    Result remove_job(uint32_t id) noexcept;
};

} // namespace os
