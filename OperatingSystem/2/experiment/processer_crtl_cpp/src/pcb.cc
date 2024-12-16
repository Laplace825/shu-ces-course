#include "pcb.h"

#include <cstddef>

#include "constant.h"

namespace os {

PcbController::ResTuple PcbController::finish_one() noexcept {
    // this must be true; because we have at least 2 process
    auto [front, _]         = pop_front();
    front->next             = nullptr;
    front->prev             = nullptr;
    front->cpu_require_time = 0;
    front->state            = PCB::State::Finish;
    front->cpu_hold_time    = front->cpu_max_require_time;
    return ret_true_type(front);
}

PcbController::ResTuple PcbController::schedule_running_pf() noexcept {
    if (empty()) {
        return ret_false_type(Err::NoEnoughProcess);
    }
    else if (m_process_count == 1) {
        return finish_one();
    }

    // at least 2 processes
    PCB* next_tmp = m_now_running->next;

    m_now_running->cpu_hold_time += m_time_slice;
    m_now_running->priority += 3;
    if (m_now_running->cpu_require_time - m_time_slice <= 0) {
        m_now_running->next->state = PCB::State::Running;
        return finish_one();
    }
    else {
        // at least 2 process, and will not finish
        if (m_now_running->priority <= next_tmp->priority) {
            m_now_running->cpu_require_time -= m_time_slice;
            next_tmp->state      = PCB::State::Waiting;
            m_now_running->state = PCB::State::Running;
            return ret_true_type(m_now_running);
        }
        else {
            // find a process with smaller priority
            // the priority more near to 0, the higher priority it will be
            // running.

            PCB* tmp = next_tmp->next;
            while (tmp != nullptr) {
                if (tmp->priority >= m_now_running->priority) {
                    break;
                }
                tmp = tmp->next;
            }
            if (!tmp) {
                // tmp == nullptr
                tmp = m_now_running;
                m_now_running->cpu_require_time -= m_time_slice;
                m_process_count -= 1;
                push_back(m_now_running);
                m_tail->state        = PCB::State::Waiting;
                m_now_running->state = PCB::State::Running;
                return ret_true_type(tmp);
            }
            else {
                // insert to the front of tmp
                // if we go to this branch, then tmp must not be nullptr, so
                // there must be at least 3 process
                m_now_running->cpu_require_time -= m_time_slice;
                m_now_running->state = PCB::State::Waiting;
                m_head               = m_now_running->next;
                m_head->prev         = nullptr;
                m_head->state        = PCB::State::Running;
                PCB* tmp_prev        = tmp->prev;
                tmp->prev            = m_now_running;
                PCB* tmp_ret         = m_now_running;
                m_now_running->next  = tmp;
                m_now_running->prev  = tmp_prev;
                tmp_prev->next       = m_now_running;
                m_now_running        = m_head;
                return ret_true_type(tmp_ret);
            }
        }
    }
}

PcbController::ResTuple PcbController::schedule_running_rr() noexcept {
    if (m_process_count < 1) {
        return ret_false_type(Err::NoEnoughProcess);
    }
    else if (m_process_count == 1) {
        return finish_one();
    }

    m_now_running->cpu_hold_time += m_time_slice;
    if (m_now_running->cpu_require_time - m_time_slice <= 0) {
        m_now_running->next->state = PCB::State::Running;
        return finish_one();
    }
    else {
        m_now_running->cpu_require_time -= m_time_slice;
        m_now_running->state = PCB::State::Waiting;

        // this must be true; because we have at least 2 process
        auto [front, _] = pop_front();
        push_back(front);
        m_now_running->state = PCB::State::Running;
        return ret_true_type(front);
    }
}

Result PcbController::insert_pcb_pf(PCB* pcb) noexcept {
    if (pcb == nullptr) {
        return Error(Err::PcbInsertEmpty);
    }

    if (m_head == pcb) {
        return Error(Err::PcbInsertHead);
    }

    if (empty()) {
        m_head        = pcb;
        m_head->state = PCB::State::Running;
        m_now_running = m_head;
        m_tail        = pcb;
        m_process_count += 1;
        return true;
    }

    if (m_process_count == 1) {
        if (pcb->priority <= m_head->priority) {
            m_head->state = PCB::State::Waiting;
            pcb->state    = PCB::State::Running;
            pcb->next     = m_head;
            m_head->prev  = pcb;
            m_head        = pcb;
            m_head->prev  = nullptr;
            m_tail        = m_head->next;
            m_tail->next  = nullptr;
            m_process_count += 1;
            m_now_running = m_head;
            return true;
        }
        else {
            pcb->state = PCB::State::Waiting;
            push_back(pcb);
            return true;
        }
    }

    // check if insert an existing pcb
    PCB* tmp = m_head;
    while (tmp != nullptr) {
        if (tmp->pid == pcb->pid) {
            return Error(Err::PcbExist);
        }
        tmp = tmp->next;
    }

    tmp = m_head;
    while (tmp != nullptr) {
        if (tmp->priority >= pcb->priority) {
            break;
        }
        tmp = tmp->next;
    }

    if (!tmp) {
        push_back(pcb);
        return true;
    }

    // insert to the front of tmp
    PCB* tmp_prev  = tmp->prev;
    tmp->prev      = pcb;
    pcb->next      = tmp;
    pcb->prev      = tmp_prev;
    tmp_prev->next = pcb;

    m_process_count += 1;

    return true;
}

Result PcbController::insert_pcb_rr(PCB* pcb) noexcept {
    if (pcb == nullptr) {
        return Error(Err::PcbInsertEmpty);
    }

    if (m_head == pcb) {
        return Error(Err::PcbInsertHead);
    }

    if (empty()) {
        m_head        = pcb;
        m_head->state = PCB::State::Running;
        m_now_running = m_head;
        m_tail        = pcb;
        m_process_count += 1;
        return true;
    }

    if (m_process_count == 1) {
        push_back(pcb);
        return true;
    }

    // check if insert an existing pcb
    PCB* tmp = m_head;
    while (tmp != nullptr) {
        if (tmp->pid == pcb->pid) {
            return Error(Err::PcbExist);
        }
        tmp = tmp->next;
    }

    push_back(pcb);
    return true;
}

} // namespace os
