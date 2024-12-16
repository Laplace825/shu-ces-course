#pragma once

#include <algorithm>
#include <array>
#include <cstdint>
#include <expected>
#include <initializer_list>
#include <map>
#include <print>
#include <string>
#include <vector>

#include "constant.h"

namespace banker {

using Result = std::expected< bool, Err >;
using Error  = std::unexpected< Err >;

class Process {
    friend class Controller;

  public:
    using resources_t = std::array< uint32_t, SystemResourcesTypeNum >;

    Process(uint32_t id = 0) : m_id(id), m_hold({0}) {};

    // Get the max require of each system resources
    Process(std::initializer_list< uint32_t > m) : m_hold({0}) {
        std::move(m.begin(), m.end(), m_max_require.begin());
        std::copy(m_max_require.begin(), m_max_require.end(), m_need.begin());
    }

    void set_max_require(resources_t max_require) {
        m_max_require = max_require;
        m_need        = max_require;
    }

    Result get(const resources_t& to_consume) {
        for (uint32_t i = 0; i < SystemResourcesTypeNum; ++i) {
            if (to_consume[i] > m_need[i]) {
                return Error(Err::RequireBeyondCurrentResources);
            }
        }
        for (uint32_t i = 0; i < SystemResourcesTypeNum; ++i) {
            if (to_consume[i] > m_max_require[i]) {
                return Error(Err::RequireBeyondMaxResources);
            }
        }
        for (uint32_t i = 0; i < SystemResourcesTypeNum; ++i) {
            m_need[i] -= to_consume[i];
            m_hold[i] += to_consume[i];
        }
        return true;
    }

    resources_t release_all() {
        auto hold = m_hold;
        m_hold.fill(0);
        return hold;
    }

    resources_t need() const { return m_need; }

    uint32_t id() const { return m_id; }

    void print() const noexcept {
        std::print("-> Process {}:\n", m_id);
        std::print("\t | Max require:\t");
        for (auto r : m_max_require) {
            std::print("{} ", r);
        }
        std::println(" |");
        std::print("\t | Need:\t");
        for (auto r : m_need) {
            std::print("{} ", r);
        }
        std::println(" |");
        std::print("\t | Hold:\t");
        for (auto r : m_hold) {
            std::print("{} ", r);
        }
        std::println(" |");
    }

  private:
    uint32_t m_id;
    resources_t m_max_require;
    resources_t m_need;
    resources_t m_hold;
};

class Controller {
    // SystemResourcesType -> number
    using system_resources_t = std::map< SystemResourcesType, uint32_t >;

    static uint32_t generate_id();

    Result check_process_id(uint32_t process_id) const noexcept;

    Result allocate_system_resources(
      SystemResourcesType type, uint32_t num) noexcept;

    Result release_system_resources(
      SystemResourcesType type, uint32_t num) noexcept;

    Result check_enough(const Process::resources_t& re) const noexcept;

  public:
    Controller(const Controller&) = default;

    Controller(Controller&&) = default;

    Controller& operator=(const Controller&) = default;

    // input the process id and the resources to require
    Result in_max_require(
      uint32_t process_id, Process::resources_t max_require) noexcept;
    Result in_require(
      uint32_t process_id, Process::resources_t require) noexcept;

    Result release(uint32_t process_id) noexcept;

    Controller() = delete;

    // how many process initially
    Controller(uint32_t process_number);

    // check is system safe
    Result is_safe() const noexcept;

    void print() const noexcept;

    std::string resources_hold(uint32_t process_id) const noexcept;
    std::array< uint32_t, SystemResourcesTypeNum > available() const noexcept;

  private:
    // id -> process
    std::vector< Process > m_processes;

    // SystemResourcesType -> number
    system_resources_t m_system_resources;
    std::array< uint32_t, SystemResourcesTypeNum > m_available;
};

const std::map< SystemResourcesType, uint32_t > m_max_system_resources{
  {{SystemResourcesType::IOTypst, getMaxSystemResourcesNum(IOTypst)},
   {SystemResourcesType::Memory, getMaxSystemResourcesNum(Memory)},
   {SystemResourcesType::Buffer, getMaxSystemResourcesNum(Buffer)},
   {SystemResourcesType::Bus, getMaxSystemResourcesNum(Bus)}}
};
} // namespace banker
