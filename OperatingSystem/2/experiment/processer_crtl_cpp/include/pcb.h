#pragma once

#include <cstddef>
#include <cstdint>
#include <expected>
#include <print>
#include <string>
#include <tuple>

#include "constant.h"

namespace os {

using Result = std::expected< bool, Err >;
using Error  = std::unexpected< Err >;

struct PCB {
    enum class State : uint16_t {
        Finish = 0,
        Running,
        Waiting,
    };
    uint32_t pid;
    uint32_t priority;
    int32_t cpu_max_require_time;
    int32_t cpu_require_time;
    int32_t cpu_hold_time;
    State state;

    PCB* next;
    PCB* prev;

    std::string state_to_string() const noexcept {
        switch (state) {
            case State::Finish:
                return "Finish";
            case State::Running:
                return "Running";
            case State::Waiting:
                return "Waiting";
            default:
                return "Unknown";
        }
    };

    PCB() = default;

    void print() const noexcept {
        std::println("\
-> PID: {}\n\
\t| Priority: {} \t\t\t|\n\
\t| CPU Max Require Time: {} \t|\n\
\t| CPU Require Time: {} \t\t|\n\
\t| CPU Hold Time: {} \t\t|\n\
\t| State: {} \t\t|",
          pid, priority, cpu_max_require_time, cpu_require_time, cpu_hold_time,
          state_to_string());
    }

    void print_short() const noexcept {
        std::println("{}\t {}\t {}\t {}\t {}", pid, priority, cpu_require_time,
          cpu_hold_time, state_to_string());
    }
};

class PcbController {
    PCB* m_now_running;
    PCB* m_head;
    PCB* m_tail;

    uint32_t m_time_slice;
    uint32_t m_process_count;

    SechdulerType m_scheduler_type;

    using ResTuple = std::tuple< PCB*, Result >;

    // shouldn't use this to insert an existing pcb;
    Result insert_pcb_pf(PCB*) noexcept;

    // shouldn't use this to insert an existing pcb;
    Result insert_pcb_rr(PCB*) noexcept;

    ResTuple schedule_running_pf() noexcept;

    // shouldn't use when m_process_count <= 1
    ResTuple schedule_running_rr() noexcept;

    constexpr ResTuple ret_true_type(PCB* pcb = nullptr) const noexcept {
        return std::make_tuple(pcb, true);
    }

    constexpr ResTuple ret_false_type(Err e) const noexcept {
        return std::make_tuple(nullptr, Error(e));
    }

    ResTuple finish_one() noexcept;

    // pop the front pcb and update m_head, m_running
    // the popped pcb's next will be set to nullptr
    ResTuple pop_front() noexcept {
        if (empty()) {
            return ret_false_type(Err::NoEnoughProcess);
        }

        m_process_count -= 1;
        PCB* tmp      = m_head;
        m_head        = m_head->next;
        tmp->next     = nullptr;
        m_now_running = m_head;
        if (!m_process_count) {
            m_head = nullptr;
            m_tail = nullptr;
        }
        else {
            m_head->prev = nullptr;
        }
        return ret_true_type(tmp);
    }

    PCB* front() const noexcept { return m_head; }

    // this won't be failed
    void push_back(PCB* pcb) noexcept {
        if (empty()) {
            m_head        = pcb;
            m_now_running = m_head;
            m_tail        = pcb;
            return;
        }
        m_process_count += 1;
        if (pcb == m_head) {
            m_head->prev = m_tail;
            m_head->next = nullptr;

            m_tail->next  = m_head;
            m_tail->prev  = nullptr;
            PCB* tmp      = m_tail;
            m_tail        = m_head;
            m_head        = tmp;
            m_now_running = m_head;
            return;
        }
        m_tail->next = pcb;
        pcb->prev    = m_tail;
        pcb->next    = nullptr;
        m_tail       = pcb;
    }

    // shouldn't use this to insert an existing pcb;
    Result insert_pcb(PCB* pcb) noexcept {
        // change m_process_count in the insert_pf or insert_rr
        switch (m_scheduler_type) {
            case SechdulerType::PriorityFirst:
                return insert_pcb_pf(pcb);
            case SechdulerType::RoundRobin:
                return insert_pcb_rr(pcb);
        }
    }

  public:
    // true if is empty
    bool empty() const noexcept { return m_head == nullptr; }

    // new a pcb
    Result new_pcb(uint32_t priority, int32_t cpu_max_require_time) noexcept {
        static uint32_t pid       = 0;
        PCB* pcb                  = new PCB();
        pcb->pid                  = pid++;
        pcb->cpu_hold_time        = 0;
        pcb->priority             = priority;
        pcb->cpu_max_require_time = cpu_max_require_time;
        pcb->state                = PCB::State::Waiting;
        pcb->cpu_require_time     = cpu_max_require_time;
        return insert_pcb(pcb);
    }

    PcbController(SechdulerType t, uint16_t time_slice = 1) noexcept
        : m_now_running(nullptr), m_head(nullptr), m_tail(nullptr),
          m_time_slice(time_slice), m_process_count(0), m_scheduler_type(t) {};

    void set_scheduler_type(SechdulerType type) noexcept {
        m_scheduler_type = type;
    }

    void print() const noexcept {
        PCB* tmp = m_head;
        std::println("Now has {} Processes", m_process_count);
        while (tmp != nullptr) {
            tmp->print();
            tmp = tmp->next;
        }
    }

    // return the running process and the error
    //
    // this schedule for one step
    ResTuple schedule() noexcept {
        switch (m_scheduler_type) {
            case SechdulerType::PriorityFirst: {
                return schedule_running_pf();
            }
            case SechdulerType::RoundRobin: {
                return schedule_running_rr();
            }
        }
    }

    ~PcbController() {
        PCB* tmp = m_head;
        while (tmp != nullptr) {
            PCB* next = tmp->next;
            tmp->next = nullptr;
            delete tmp;
            tmp = next;
        }
    }
};

} // namespace os
