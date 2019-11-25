`include "svunit_defines.svh"
`include "../cl_builder.sv"
`include "../buffered_cl_builder.sv"

`include "config/test_macros.sv"

`timescale 1 ps / 1 ps
module buffered_cl_builder_unit_test;
    import test_pkg::*;
    import svunit_pkg::svunit_testcase;

    string name = "buffered_cl_builder_ut";
    svunit_testcase svunit_ut;

    //===================================
    // Parameters & Signals for UUT
    //===================================
    localparam DATA_WIDTH = $bits(t_uint64);
    localparam DATA_PER_CL = $bits(t_cl) / $bits(t_uint64);
    localparam CL_WIDTH = $bits(t_cl);
    localparam EVICTION_POLICY = "ALL_ONES";
    
    localparam BUFFER_DEPTH = 8;
    localparam ALM_FULL_DIFF = 4;

    logic clk;
    logic reset;
    logic evict;
    logic data_wr;
    t_uint64 data_in;
    logic cl_rd;
    logic alm_full;
    logic out_cl_valid;
    t_cl out_cl;
    
    // Unit test tracked signals
    logic test_insert_1_element;
    logic test_insert_2_elements;
    logic test_insert_full_cl;
    logic test_insert_2_simultaneous_cls;
    logic test_insert_4_simultaneous_cls;
    logic test_insert_til_alm_full;

    //===================================
    // This is the UUT that we're 
    // running the Unit Tests on
    //===================================
    buffered_cl_builder #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_PER_CL(DATA_PER_CL),
        .CL_WIDTH(CL_WIDTH),
        .EVICTION_POLICY(EVICTION_POLICY),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .ALM_FULL_DIFF(ALM_FULL_DIFF)
    ) my_buffered_cl_builder(.*);


    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);
    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    localparam NUM_TEST_CLS = 4;
    t_cl test_in_cls    [NUM_TEST_CLS];
    t_cl test_out_cls   [NUM_TEST_CLS];

    task setup();
        svunit_ut.setup();

        // Init test Data
        for (int i = 0; i < NUM_TEST_CLS; i++) begin
            for (int j = 0; j < DATA_PER_CL; j++) begin
                automatic int value = (i*DATA_PER_CL) + j + 1;
                test_in_cls[i].u64[j] = t_uint64'(value);
                test_out_cls[i].u64[DATA_PER_CL - j - 1] = t_uint64'(value);
            end
        end

        reset   = 1;
        evict   = 0;
        data_wr = 0;
        data_in = '0;
        cl_rd   = 0;

        `TICK;`TICK;`TICK;`TICK;`TICK;
        reset = 0;
        `TICK;`TICK;`TICK;`TICK;`TICK;

    endtask


    //===================================
    // Here we deconstruct anything we 
    // need after running the Unit Tests
    //===================================
    task teardown();
        svunit_ut.teardown();
        /* Place Teardown Code Here */
    endtask

    //===================================
    // Unit Tests
    //===================================
    `SVUNIT_TESTS_BEGIN

        `SVTEST(insert_1_element)
            test_insert_1_element = 1;
            `FAIL_IF(out_cl_valid)
            data_in = test_in_cls[0].u64[0];
            data_wr = 1;
            
            `TICK
            
            `FAIL_IF(out_cl_valid)
            data_wr = 0;
            
            `TICK

            `FAIL_IF(out_cl_valid)
            evict = 1;

            `TICK
            evict = 0;

            while (~out_cl_valid) begin
                `TICK
            end  

            cl_rd = 1;
            `FAIL_UNLESS_LOG(out_cl.u64[0] == test_in_cls[0].u64[0], $sformatf("failed #%0d, exp: %8h, got: %8h", 0, test_in_cls[0].u64[0], out_cl.u64[0]));
            for (int i = 1; i < DATA_PER_CL; i++) begin
                `FAIL_UNLESS_LOG(out_cl.u64[i] == t_uint64'('1), $sformatf("failed #%0d, exp: %8h, got: %8h", i, t_uint64'('1), out_cl.u64[i]));
            end
            `TICK
            cl_rd = 0;
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            test_insert_1_element = 0;
        `SVTEST_END

        `SVTEST(insert_2_elements)
            test_insert_2_elements = 1;
            `FAIL_IF(out_cl_valid)
            data_in = test_in_cls[0].u64[0];
            data_wr = 1;
            
            `TICK
            
            `FAIL_IF(out_cl_valid)
            data_in = test_in_cls[0].u64[1];

            `TICK

            `FAIL_IF(out_cl_valid)
            data_wr = 0;
            
            `TICK

            `FAIL_IF(out_cl_valid)
            evict = 1;

            `TICK
             evict = 0;

            while (~out_cl_valid) begin
                `TICK
            end  
            
            cl_rd = 1;           
            `FAIL_UNLESS_LOG(out_cl.u64[0] == test_in_cls[0].u64[1], $sformatf("failed #%0d, exp: %8h, got: %8h", 0, test_in_cls[0].u64[0], out_cl.u64[1]));
            `FAIL_UNLESS_LOG(out_cl.u64[1] == test_in_cls[0].u64[0], $sformatf("failed #%0d, exp: %8h, got: %8h", 1, test_in_cls[0].u64[1], out_cl.u64[0]));
            for (int i = 2; i < DATA_PER_CL; i++) begin
                `FAIL_UNLESS_LOG(out_cl.u64[i] == t_uint64'('1), $sformatf("failed #%0d, exp: %8h, got: %8h", i, t_uint64'('1), out_cl.u64[i]));
            end

            `TICK
            cl_rd = 0;
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            test_insert_2_elements = 0;
        `SVTEST_END

        `SVTEST(insert_full_cl)
            test_insert_full_cl = 1;
            `FAIL_IF(out_cl_valid)
            
            data_wr = 1;
            for (int i = 0; i < DATA_PER_CL; i++) begin
                data_in = test_in_cls[0].u64[i];
                `TICK;
            end
            data_wr = 0;

            while (~out_cl_valid) begin
                `TICK
            end  
            
            cl_rd = 1;   
            for (int i = 0; i < DATA_PER_CL; i++) begin
                `FAIL_UNLESS_LOG(out_cl.u64[i] == test_out_cls[0].u64[i], $sformatf("failed #%0d, exp: %8h, got: %8h", i, test_out_cls[0].u64[i], out_cl.u64[i]));
            end

            `TICK
            cl_rd = 0;
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            test_insert_full_cl = 0;
        `SVTEST_END

        `SVTEST(insert_2_simultaneous_cls)
            test_insert_2_simultaneous_cls = 1;
            `FAIL_IF(out_cl_valid)
            
            // Insert 1st CL
            data_wr = 1;
            for (int i = 0; i < DATA_PER_CL; i++) begin
                data_in = test_in_cls[0].u64[i];
                `TICK;
            end
            for (int i = 0; i < DATA_PER_CL; i++) begin
                data_in = test_in_cls[1].u64[i];
                `TICK;
            end
            data_wr = 0;
            `TICK;`TICK;`TICK;`TICK;`TICK;
            cl_rd = 1;  

            `FAIL_IF(~out_cl_valid)
            for (int i = 0; i < DATA_PER_CL; i++) begin
                `FAIL_UNLESS_LOG(out_cl.u64[i] == test_out_cls[0].u64[i], $sformatf("failed #%0d, exp: %8h, got: %8h", i, test_out_cls[0].u64[i], out_cl.u64[i]));
            end

            `TICK
            
            `FAIL_IF(~out_cl_valid)
            for (int i = 0; i < DATA_PER_CL; i++) begin
                `FAIL_UNLESS_LOG(out_cl.u64[i] == test_out_cls[1].u64[i], $sformatf("failed #%0d, exp: %8h, got: %8h", i, test_out_cls[1].u64[i], out_cl.u64[i]));
            end
            
            `TICK
            cl_rd = 0; 
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            test_insert_2_simultaneous_cls = 0;
        `SVTEST_END

        `SVTEST(insert_4_simultaneous_cls)
            test_insert_4_simultaneous_cls = 1;
            `FAIL_IF(out_cl_valid)
            
            // Insert 1st CL
            data_wr = 1;
            for (int i = 0; i < NUM_TEST_CLS; i++) begin
                for (int j = 0; j < DATA_PER_CL; j++) begin
                    data_in = test_in_cls[i].u64[j];
                    `TICK;
                end
            end
            data_wr = 0;
            `TICK;`TICK;`TICK;`TICK;`TICK;
            cl_rd = 1;  
            for (int i = 0; i < NUM_TEST_CLS; i++) begin
                `FAIL_IF(~out_cl_valid)
                for (int j = 0; j < DATA_PER_CL; j++) begin
                    `FAIL_UNLESS_LOG(out_cl.u64[j] == test_out_cls[i].u64[j], $sformatf("failed CL: %0d - #%0d, exp: %8h, got: %8h", i, j, test_out_cls[i].u64[j], out_cl.u64[j]));
                end
                `TICK;
            end
            `TICK
            cl_rd = 0; 
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            `TICK
            `FAIL_IF(out_cl_valid)
            test_insert_4_simultaneous_cls = 0;
        `SVTEST_END

        
        `SVTEST(insert_til_alm_full)
            int cycles_til_flag = 0;
            test_insert_til_alm_full = 1;
            `FAIL_IF(out_cl_valid)
            
            // Insert 1st CL
            data_wr = 1;
            for (int i = 0; i < NUM_TEST_CLS; i++) begin
                for (int j = 0; j < DATA_PER_CL; j++) begin
                    data_in = test_in_cls[i].u64[j];
                    `FAIL_IF(alm_full)
                    `TICK;
                end
            end

            while (~alm_full) begin
                `TICK
                cycles_til_flag = cycles_til_flag + 1;
            end

            `FAIL_UNLESS_LOG(cycles_til_flag < 4, $sformatf("failed exp: %0d, got: %0d", 4, cycles_til_flag));

        `SVTEST_END
    `SVUNIT_TESTS_END

endmodule
