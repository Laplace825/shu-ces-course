#include <cstdint>
#include <iostream>
#include <print>
#include <string>
#include <vector>

#include "constant.h"
#include "pcb.h"

#define GREEN "\033[1;32m"
#define GOLD "\033[1;33m"
#define RED "\033[1;31m"
#define BLUE "\033[1;34m"

#define RESET "\033[0m"

#define check_error(expr)                                    \
    if (auto e = expr; !e.has_value()) {                     \
        std::println(RED "Error: {}" RESET, int(e.error())); \
    }

int main() {
    std::string algo_choose;
    std::print(GREEN "Which Sechduling Algorithm ('rr' or 'pf') >>> " RESET);
    std::getline(std::cin, algo_choose);

    os::SechdulerType sechduler_algo;
    if (algo_choose == "rr") {
        sechduler_algo = os::SechdulerType::RoundRobin;
    }
    else if (algo_choose == "pf") {
        sechduler_algo = os::SechdulerType::PriorityFirst;
    }
    else {
        std::println(RED "Error: Invalid Algorithm" RESET);
        return 1;
    }

    uint32_t time_slice;
    std::print(GREEN "Time Slice >>> " RESET);
    std::cin >> time_slice;

    uint32_t process_number = 0;

    std::print(GREEN "How many processes >>> " RESET);
    std::cin >> process_number;

    os::PcbController ctrl(sechduler_algo, time_slice);

    for (uint32_t i = 0; i < process_number; ++i) {
        uint32_t priority;
        int32_t cpu_max_require_time;
        std::print(GREEN "<Priority> <CPU Max Require Time> >>> " RESET);
        std::cin >> priority >> cpu_max_require_time;
        check_error(ctrl.new_pcb(priority, cpu_max_require_time));
    }

    std::vector< uint32_t > order;

    // use to pause the program
    std::string c;

    uint32_t counter = 0;

    while (!ctrl.empty()) {
        std::println(BLUE "Input to continue... " RESET);
        std::getline(std::cin, c);
        std::println(GOLD
          "============== {} Turn (before schedule) =============" RESET,
          ++counter);
        ctrl.print();
        auto [p, e] = ctrl.schedule();
        if (!e.has_value()) {
            std::println(RED "Error: {}" RESET, int(e.error()));
        }
        else {
            if (p) {
                std::println(GREEN "Runned {}" RESET, p->pid);
                order.push_back(p->pid);
                if (p->cpu_require_time <= 0) {
                    std::println(GREEN "Process {} is Finished" RESET, p->pid);
                    delete p;
                }
            }
        }
    }

    std::println(GOLD "Run order <PID>" RESET);
    for (auto pid : order) {
        std::print(BLUE "{} " RESET, pid);
    }
    std::println();

    return 0;
}
