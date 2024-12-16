#include "memlist.h"

#include <print>
#include <utility>

#include "constant.h"

namespace os {

MemList MemList::copy() const noexcept {
    MemList new_list;
    MemNode *cur = m_head;
    while (cur != nullptr) {
        MemNode *new_node = new MemNode();
        new_node->id      = cur->id;
        new_node->begin   = cur->begin;
        new_node->size    = cur->size;
        new_node->state   = cur->state;
        new_list.push_back(new_node);
        cur = cur->next;
    }
    return new_list;
}

void MemList::sort(bool asc) noexcept {
    // double direction linklist sort by size
    if (m_head == nullptr || m_head->next == nullptr) {
        return;
    }

    MemNode *head = m_head;
    MemNode *tail = nullptr;

    while (head != tail) {
        MemNode *cur  = head;
        MemNode *next = cur->next;
        while (next != tail) {
            if (asc) {
                if (cur->size > next->size) {
                    std::swap(cur->id, next->id);
                    std::swap(cur->begin, next->begin);
                    std::swap(cur->size, next->size);
                    std::swap(cur->state, next->state);
                }
            }
            else {
                if (cur->size < next->size) {
                    std::swap(cur->id, next->id);
                    std::swap(cur->begin, next->begin);
                    std::swap(cur->size, next->size);
                    std::swap(cur->state, next->state);
                }
            }
            cur  = next;
            next = next->next;
        }
        tail = cur;
    }
}

void MemList::push_back(MemNode *node) noexcept {
    if (m_head == nullptr) {
        m_head = node;
        m_tail = node;
        return;
    }

    m_tail->next = node;
    node->prev   = m_tail;
    node->next   = nullptr;
    m_tail       = node;
    return;
}

MemList::find_type MemList::find_by_id(uint32_t id) const noexcept {
    MemNode *cur = m_head;
    while (cur != nullptr) {
        if (cur->id.id == id) {
            return std::make_pair(cur, true);
        }
        cur = cur->next;
    }
    return std::make_pair(nullptr, Error(Err::NoThatJob));
}

MemList::find_type MemList::find_job_by_id(uint32_t id) const noexcept {
    MemNode *cur = m_head;
    while (cur != nullptr) {
        if (cur->id.id == id && cur->state != MemState::Idle) {
            return std::make_pair(cur, true);
        }
        cur = cur->next;
    }
    return std::make_pair(nullptr, Error(Err::NoThatJob));
}

MemList::find_type MemList::find_enough_idle_mem(uint32_t size) const noexcept {
    MemNode *cur = m_head;
    while (cur != nullptr) {
        if (cur->size >= size && cur->state == MemState::Idle) {
            return std::make_pair(cur, true);
        }
        cur = cur->next;
    }
    return std::make_pair(nullptr, Error(Err::NoEnoughIdlePartialMem2Alloc));
}

void MemList::update_head_from(MemNode *node) noexcept {
    if (!node) {
        return;
    }
    auto tmp = node;
    while (tmp->prev) {
        tmp = tmp->prev;
    }
    m_head = tmp;
}

MemList::find_type MemList::pop_front() noexcept {
    if (!m_head) {
        return std::make_pair(nullptr, Error(Err::NoThatJob));
    }
    auto tmp     = m_head;
    m_head       = m_head->next;
    tmp->next    = nullptr;
    m_head->prev = nullptr;
    return std::make_pair(tmp, true);
}

MemList::find_type MemList::pop_back() noexcept {
    if (!m_tail) {
        return std::make_pair(nullptr, Error(Err::NoThatJob));
    }
    auto tmp     = m_tail;
    m_tail       = m_tail->prev;
    m_tail->next = nullptr;
    tmp->prev    = nullptr;
    return std::make_pair(tmp, true);
}

MemList::find_type MemList::remove(uint32_t id) noexcept {
    if (!m_head) {
        return std::make_pair(nullptr, Error(Err::NoThatJob));
    }

    auto [node, e] = find_by_id(id);
    if (!e.has_value()) {
        return std::make_pair(nullptr, e);
    }
    auto prev = node->prev;
    auto next = node->next;
    if (!prev) {
        return pop_front();
    }
    if (!next) {
        return pop_back();
    }

    prev->next = next;
    next->prev = prev;
    node->next = nullptr;
    node->prev = nullptr;

    return std::make_pair(node, true);
}

Result MemList::remove_job(uint32_t id) noexcept {
    if (!m_head) {
        return Error(Err::NoThatJob);
    }

    auto [node, e] = find_job_by_id(id);
    if (!e.has_value()) {
        return e;
    }
    auto prev = node->prev;
    auto next = node->next;
    if (!prev) {
        auto [p, e] = pop_front();
        delete p;
        return e;
    }
    if (!next) {
        auto [p, e] = pop_back();
        delete p;
        return e;
    }

    prev->next = next;
    next->prev = prev;
    node->next = nullptr;
    node->prev = nullptr;
    delete node;

    return true;
}
} // namespace os
