#include <cstdint>
#include <format>
#include <iostream>
#include <print>
#include <ranges>

#include "constant.h"
#include "process.h"

static const std::string Message = std::format("Simulate {} Resources:\n\
IOTypst Num: {}\n\
Memory Num: {}\n\
Buffer Num: {}\n\
Bus Num: {}",
  banker::SystemResourcesTypeNum, getMaxSystemResourcesNum(IOTypst),
  getMaxSystemResourcesNum(Memory), getMaxSystemResourcesNum(Buffer),
  getMaxSystemResourcesNum(Bus));

static const std::string ErrorCodeMsg = std::format("Error Code:\n\
{}: Require Beyond Max Resources\n\
{}: Require Beyond Current Resources\n\
{}: Not Enough Recources\n\
{}: Process Not Exist\n\
{}: No Safe Sequence",
  uint32_t(banker::Err::RequireBeyondMaxResources),
  uint32_t(banker::Err::RequireBeyondCurrentResources),
  uint32_t(banker::Err::NotEnoughRecources),
  uint32_t(banker::Err::ProcessNotExist),
  uint32_t(banker::Err::NoSafeSequence));

#define GREEN "\033[1;32m"
#define GOLD "\033[1;33m"
#define RED "\033[1;31m"
#define BLUE "\033[1;34m"

#define RESET "\033[0m"

#define check_error(expr)                                           \
    if (auto err = expr; !err.has_value()) {                        \
        std::println(RED "Error: {}" RESET, uint32_t(err.error())); \
        continue;                                                   \
    }

#define system_available(ctrl)                                 \
    std::print(BLUE "Now System Resources available: " RESET); \
    for (auto a : ctrl.available()) {                          \
        std::print(GOLD "{} " RESET, a);                       \
    }                                                          \
    std::println();

int main() {
    std::println(GOLD "{}\n" BLUE "{}" RESET, Message, ErrorCodeMsg);
    uint32_t process_number = 0;

    std::print(GREEN "the number of process >>> " RESET);
    std::cin >> process_number;

    auto ctrl = banker::Controller(process_number);

    for (uint32_t i : std::views::iota(0u, process_number)) {
        std::print(GREEN "the max require of process {} >>> " RESET, i);
        banker::Process::resources_t require;
        for (auto& r : require) {
            std::cin >> r;
        }
        check_error(ctrl.in_max_require(i, require));
    }

    while (true) {
        std::print(GREEN "<Which> process to allocate resources >>> " RESET);
        uint32_t pid;
        std::cin >> pid;
        if (pid >= process_number) {
            std::println(
              RED "Error: {}" RESET, uint32_t(banker::Err::ProcessNotExist));
            continue;
        }
        std::println(
          BLUE "process {} has {}" RESET, pid, ctrl.resources_hold(pid));
        std::print(GREEN "process {} allocate >>> " RESET, pid);

        banker::Process::resources_t require;
        for (auto& r : require) {
            std::cin >> r;
        }
        auto copyed = ctrl;
        if (auto err = ctrl.in_require(pid, require); !err.has_value()) {
            std::println(RED "Error: {}" RESET, uint32_t(err.error()));
            ctrl = std::move(copyed);
            system_available(ctrl);
            continue;
        }
        if (auto err = ctrl.is_safe(); !err.has_value()) {
            std::println(RED "Error: {}" RESET, uint32_t(err.error()));
            ctrl = std::move(copyed);
            system_available(ctrl);
            continue;
        }

        std::println(GOLD "< Safe >" RESET);
        system_available(ctrl);
        ctrl.print();
    }

    return 0;
}
