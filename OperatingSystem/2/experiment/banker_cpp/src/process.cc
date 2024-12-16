#include "process.h"

#include <algorithm>
#include <array>
#include <cstdint>
#include <format>
#include <print>
#include <string>

#include "constant.h"

namespace banker {

uint32_t Controller::generate_id() {
    static uint32_t id = 0;
    return id++;
}

Result Controller::check_process_id(uint32_t process_id) const noexcept {
    if (process_id >= m_processes.size()) {
        return Error(Err::ProcessNotExist);
    }
    return true;
}

Controller::Controller(uint32_t resources_num) : m_processes(resources_num) {
    for (auto& process : m_processes) {
        process = Process(generate_id());
    }
    constexpr auto init = std::array< uint32_t, SystemResourcesTypeNum >{
      getMaxSystemResourcesNum(IOTypst),
      getMaxSystemResourcesNum(Memory),
      getMaxSystemResourcesNum(Buffer),
      getMaxSystemResourcesNum(Bus),
    };

    m_available = init;
    for (auto i = 0; i < SystemResourcesTypeNum; i++) {
        m_system_resources[static_cast< SystemResourcesType >(i)] = init[i];
    }
}

Result Controller::allocate_system_resources(
  SystemResourcesType type, uint32_t num) noexcept {
    if (m_system_resources[type] < num) {
        return Error(Err::NotEnoughRecources);
    }
    m_system_resources[type] -= num;
    return true;
}

Result Controller::release_system_resources(
  SystemResourcesType type, uint32_t num) noexcept {
    m_system_resources[type] += num;
    return true;
}

Result Controller::check_enough(const Process::resources_t& re) const noexcept {
    for (uint32_t i = 0; i < SystemResourcesTypeNum; i++) {
        if (re[i] > m_available[i]) {
            return Error(Err::NotEnoughRecources);
        }
    }
    return true;
}

Result Controller::in_max_require(
  uint32_t process_id, Process::resources_t max_require) noexcept {
    if (auto err = check_process_id(process_id); !err.has_value()) {
        return err;
    }
    for (uint32_t i = 0; i < SystemResourcesTypeNum; i++) {
        if (max_require[i] >
            m_max_system_resources.at(static_cast< SystemResourcesType >(i)))
        {
            return Error(Err::RequireBeyondMaxResources);
        }
    }
    m_processes[process_id].set_max_require(max_require);
    return true;
}

Result Controller::in_require(
  uint32_t process_id, Process::resources_t require) noexcept {
    if (auto err = check_process_id(process_id); !err.has_value()) {
        return err;
    }
    if (auto err = check_enough(require); !err.has_value()) {
        return err;
    }
    if (auto err = m_processes[process_id].get(require); !err.has_value()) {
        return err;
    }
    for (uint32_t i = 0; i < SystemResourcesTypeNum; i++) {
        m_available[i] -= require[i];
        m_system_resources[static_cast< SystemResourcesType >(i)] -= require[i];
    }
    return true;
}

Result Controller::release(uint32_t process_id) noexcept {
    if (auto err = check_process_id(process_id); !err.has_value()) {
        return err;
    }
    auto rel = this->m_processes[process_id].release_all();
    for (uint32_t i = 0; i < SystemResourcesTypeNum; i++) {
        m_available[i] += rel[i];
        m_system_resources[static_cast< SystemResourcesType >(i)] += rel[i];
    }
    return true;
}

Result Controller::is_safe() const noexcept {
    auto is_all_true = [](const auto& arr) -> bool {
        return std::ranges::all_of(arr, [](bool b) { return b; });
    };

    auto arr_small = [](const auto& a, const auto& b) -> bool {
        for (uint32_t i = 0; i < a.size(); i++) {
            if (a[i] > b[i]) {
                return false;
            }
        }
        return true;
    };

    auto arr_add = [](const auto& a, const auto& b) -> auto {
        auto res = a;
        for (uint32_t i = 0; i < a.size(); i++) {
            res[i] += b[i];
        }
        return res;
    };

    const auto& processes = m_processes;
    auto work             = m_available;
    auto finished         = std::vector< bool >(processes.size(), false);

    while (!is_all_true(finished)) {
        auto found = std::ranges::find_if(processes, [&](const Process& p) {
            return !finished[p.id()] && arr_small(p.need(), work);
        });
        if (found != processes.end()) {
            auto idx      = found->id();
            work          = arr_add(work, processes[idx].m_hold);
            finished[idx] = true;
        }
        else {
            return Error(Err::NoSafeSequence);
        }
    }

    return true;
}

std::string Controller::resources_hold(uint32_t process_id) const noexcept {
    if (auto err = check_process_id(process_id); !err.has_value()) {
        return "Error: " + std::to_string(uint32_t(err.error()));
    }
    auto res = std::string();
    for (uint32_t i = 0; i < SystemResourcesTypeNum; i++) {
        res += std::format("{} ", m_processes[process_id].m_hold[i]);
    }
    return res;
}

std::array< uint32_t, SystemResourcesTypeNum > Controller::available()
  const noexcept {
    return m_available;
}

void Controller::print() const noexcept {
    for (const auto& p : m_processes) {
        p.print();
    }
}

} // namespace banker
