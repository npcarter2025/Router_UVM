#include "router_model.h"
#include <cstdio>
#include <cstdint>
#include <queue>

struct RouterState {
    bool global_enable;
    bool priority_port_b;
    std::queue<uint8_t> port_fifos[4];
};

static RouterState router_state;

extern "C" {
    void router_model_init() {
        router_state.global_enable = true;
        router_state.priority_port_b = false;

        for (int i = 0; i < 4; i++) {
            while (!router_state.port_fifos[i].empty()) {
                router_state.port_fifos[i].pop();
            }
        }
        printf("[C++ Model] Router Initialized\n");
    }

    void router_model_write_ctrl(uint32_t data) {
        router_state.global_enable = (data & 0x1);
        router_state.priority_port_b = (data & 0x2) >> 1;
        printf("[C++ Model] Control: enable=%d, priority_b=%d\n", router_state.global_enable, router_model_port_b);

    }

    void router_model_port_a(uint8_t data, uint8_t addr) {
        if (!router_state.global_enable) return;

        if (addr < 4) {
            router_state.port_fifos[addr].push(data);
            printf("[C++ Model] Port A: data=0x%02x -> output[%d]\n", data, addr);
        }
    }

    void router_model_port_b(uint8_t data, uint8_t addr) {
        if (!router_state.global_enable) return;

        if (addr < 4) {
            router_state.port_fifos[addr].push(data);
            printf("[C++ Model] Port B: data=0x%02x -> output[%d]\n", data, addr);
        }
    }

    int router_model_get_output(uint8_t port, uint8_t* data) {
        if (port >= 4) return 0;

        if (!router_state.port_fifos[port].empty()) {
            *data = router_state.port_fifos[port].front();
            router_state.port_fifos[port].pop();
            printf("[C++ Model] Output[%d] = 0x%02x\n", port, *data);
            return 1;
        }
        return 0;
    }
}