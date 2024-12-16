#include <cstdlib>
#include <print>
#include <string>

#include "control.h"
#include "memlist.h"

// #define "\033[1;32m"
// #define "\033[1;33m"
// #define RED "\033[1;31m"
// #define "\033[1;34m"
//
// #define "\033[0m"

#define check_error(expr)                          \
    if (auto e = expr; !e.has_value()) {           \
        std::println("Error: {}", int(e.error())); \
    }

/* Total Idle Mem 640KB

  Task:
  - Job 1: alloc 130
  - Job 2: alloc 60
  - Job 3: alloc 100
  - Job 2: free
  - Job 4: alloc 200
  - Job 3: free
  - Job 1: free
  - Job 5: alloc 140
  - Job 6: alloc 60
  - Job 7: alloc 50
  - Job 6: free

**/

int main() {
    // get from envetiment variable
    std::string alloc_type = "";
    alloc_type             = getenv("MEM_ALLOC_TYPE");

    os::DynamicMemAllocType type;

    if (alloc_type == "FirstFit") {
        type = os::DynamicMemAllocType::FirstFit;
    }
    else if (alloc_type == "RecursiveFirstFit") {
        type = os::DynamicMemAllocType::RecursiveFirstFit;
    }
    else if (alloc_type == "BestFit") {
        type = os::DynamicMemAllocType::BestFit;
    }
    else if (alloc_type == "WorstFit") {
        type = os::DynamicMemAllocType::WorstFit;
    }
    else {
        std::println("Error: {}", int(os::Err::NoThatAllocMethod));
        return 1;
    }

    auto ctrl = os::MemControl(type);

    std::println(R"("
  ## Total Idle Mem 640KB
  Task:
  - Job 1: alloc 130
  - Job 2: alloc 60
  - Job 3: alloc 100
  - Job 2: free
  - Job 4: alloc 200
  - Job 3: free
  - Job 1: free
  - Job 5: alloc 140
  - Job 6: alloc 60
  - Job 7: alloc 50
  - Job 6: free
")");

    std::println("Init");
    ctrl.show_all();

    check_error(ctrl.alloc_job(1, 130));
    std::println("Alloc Job 1: 130KB");
    ctrl.show_all();

    check_error(ctrl.alloc_job(2, 60));
    std::println("Alloc Job 2: 60KB");
    ctrl.show_all();

    check_error(ctrl.alloc_job(3, 100));
    std::println("Alloc Job 3: 100KB");
    ctrl.show_all();

    check_error(ctrl.free_job(2));
    std::println("Free Job 2");
    ctrl.show_all();

    check_error(ctrl.alloc_job(4, 60));
    std::println("Alloc Job 4: 60KB");
    ctrl.show_all();

    check_error(ctrl.free_job(3));
    std::println("Free Job 3");
    ctrl.show_all();

    check_error(ctrl.free_job(1));
    std::println("Free Job 1");
    ctrl.show_all();

    check_error(ctrl.alloc_job(5, 140));
    std::println("Alloc Job 5: 140KB");
    ctrl.show_all();

    check_error(ctrl.alloc_job(6, 60));
    std::println("Alloc Job 6: 60KB");
    ctrl.show_all();

    check_error(ctrl.alloc_job(7, 50));
    std::println("Alloc Job 7: 50KB");
    ctrl.show_all();

    check_error(ctrl.free_job(6));
    std::println("Free Job 6");
    ctrl.show_all();

    std::println("< Done >");

    return 0;
}
