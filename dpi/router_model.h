#ifndef ROUTER_MODEL_H
#define ROUTER_MODEL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
    #endif

    void router_model_init();
    void router_model_write_ctrl(uint32_t data);
    void router_model_port_a(uint8_t data, uint8_t addr);
    void router_model_port_b(uint8_t data, uint8_t addr);
    int router_model_get_output(uint8_t port, uint8_t* data);

    #ifdef __cplusplus
}

#endif


#endif