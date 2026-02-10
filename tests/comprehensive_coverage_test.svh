`ifndef COMPREHENSIVE_COVERAGE_TEST_SVH
`define COMPREHENSIVE_COVERAGE_TEST_SVH

// Comprehensive test to maximize functional coverage
class comprehensive_coverage_test extends router_base_test;
    `uvm_component_utils(comprehensive_coverage_test)

    function new(string name = "comprehensive_coverage_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        collision_vseq collision_seq;
        priority_vseq priority_seq;
        disable_vseq disable_seq;
        back_to_back_vseq back2back_seq;
        directed_data_vseq directed_seq;
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting comprehensive coverage test", UVM_LOW)
        
        // Test 1: Collision scenarios with Port A priority
        `uvm_info(get_type_name(), "=== Test 1: Collision with Port A Priority ===", UVM_LOW)
        collision_seq = collision_vseq::type_id::create("collision_seq");
        collision_seq.num_collisions = 100;  // Increase iterations
        collision_seq.test_port_a_priority = 1;
        collision_seq.start(m_env.m_vseqr);
        #10000;
        
        // Test 1b: Collision scenarios with Port B priority
        `uvm_info(get_type_name(), "=== Test 1b: Collision with Port B Priority ===", UVM_LOW)
        collision_seq = collision_vseq::type_id::create("collision_seq_b");
        collision_seq.num_collisions = 100;  // Increase iterations
        collision_seq.test_port_a_priority = 0;  // Port B wins
        collision_seq.start(m_env.m_vseqr);
        #10000;
        
        // Test 2: Change priority and test collisions again
        `uvm_info(get_type_name(), "=== Test 2: Priority Switching ===", UVM_LOW)
        priority_seq = priority_vseq::type_id::create("priority_seq");
        priority_seq.start(m_env.m_vseqr);
        #10000;
        
        // Test 3: Disable scenarios
        `uvm_info(get_type_name(), "=== Test 3: Disable Router Scenarios ===", UVM_LOW)
        disable_seq = disable_vseq::type_id::create("disable_seq");
        disable_seq.start(m_env.m_vseqr);
        #10000;
        
        // Test 4: Back-to-back transactions to all ports
        `uvm_info(get_type_name(), "=== Test 4: Back-to-Back All Ports ===", UVM_LOW)
        back2back_seq = back_to_back_vseq::type_id::create("back2back_seq");
        back2back_seq.start(m_env.m_vseqr);
        #10000;
        
        // Test 5: Directed data patterns to each port
        `uvm_info(get_type_name(), "=== Test 5: Directed Data Patterns ===", UVM_LOW)
        directed_seq = directed_data_vseq::type_id::create("directed_seq");
        directed_seq.start(m_env.m_vseqr);
        #10000;
        
        `uvm_info(get_type_name(), "Comprehensive coverage test complete", UVM_LOW)
        
        phase.drop_objection(this);
    endtask

endclass

`endif
