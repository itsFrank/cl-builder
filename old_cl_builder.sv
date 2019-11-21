/* 
    File: cl_builder.sv
    Author: Francis O'Brien
    Email: francis.obrien@mail.utoronto.ca
    Create Date: 09-18-2018
    -----------------------------------------
    Desc
        A cache line building module.
        Accepts single data elements and constructs cachelines out of them,
        making complete cachelines available at the output while simultaneously
        building a new one internally
    -----------------------------------------
    History
        09-18-2018: created
        09-19-2018: added eviction functionality
*/

module CL_BUILDER
#(
    parameter DATA_WIDTH = 32,
    parameter DATA_PER_CL = 16,
    parameter CL_WIDTH = 512,
    parameter EVICTION_POLICY = "ALL_ZEROS" //possible values: 'ALL_ONES', 'ALL_ZEROS'
)
(
    input logic clk,
    input logic reset,

    input logic evict,

    input logic cl_rd,
    input logic data_wr,
    input logic [DATA_WIDTH - 1 : 0 ] data_in,

    output logic cl_valid,
    output logic full,
    output logic alm_full,
    output logic [CL_WIDTH - 1 : 0 ] out_cl
);

    logic build_alm_full;
    logic [7:0] write_ptr;
    logic [DATA_WIDTH - 1 : 0 ] build_cl [DATA_PER_CL - 1 : 0];

    assign build_alm_full = write_ptr == DATA_PER_CL - 1;

    assign full = write_ptr == DATA_PER_CL;
    assign alm_full = build_alm_full && cl_valid;

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            write_ptr   <= '0;
            out_cl      <= '0;
            cl_valid    <= 0;

            for (i = 0; i < DATA_PER_CL; i = i + 1) begin
                build_cl[i] <= '0;
            end
        end

        if (cl_rd & ~cl_valid) $fatal("Attempting to read CL when no valid CL at output");
        if (data_wr & full) $fatal("Attempting to insert data when module is full");

        if (~evict) begin
            if (data_wr & cl_rd) begin
                if (~build_alm_full) begin //Append to build cl and clear out
                    build_cl[write_ptr] <= data_in;
                    write_ptr <= write_ptr + 1;

                    cl_valid <= 0;
                    out_cl <= '0;
                end
                else begin //Replace out with newly completed build cl, reset ptr
                    for (i = 0; i < DATA_PER_CL - 1; i = i + 1) begin
                        out_cl[i * DATA_WIDTH +: DATA_WIDTH] <= build_cl[i];
                        build_cl[i] <= '0;
                    end
                    out_cl[(DATA_PER_CL - 1) * DATA_WIDTH +: DATA_WIDTH] <= data_in;

                    cl_valid <= 1;
                    write_ptr <= '0;
                end

            end
            else if (data_wr) begin
                if (~cl_valid) begin
                    if (~build_alm_full) begin //Append to build
                        build_cl[write_ptr] <= data_in;
                        write_ptr <= write_ptr + 1;
                    end
                    else begin //Send newly complete build to out, reset ptr
                        for (i = 0; i < DATA_PER_CL - 1; i = i + 1) begin
                            out_cl[i * DATA_WIDTH +: DATA_WIDTH] <= build_cl[i];
                            build_cl[i] <= '0;
                        end
                        out_cl[(DATA_PER_CL - 1) * DATA_WIDTH +: DATA_WIDTH] <= data_in;

                        cl_valid <= 1;
                        write_ptr <= '0;
                    end
                end
                else begin //Append to build, ptr value will trigger full flag
                    build_cl[write_ptr] <= data_in;
                    write_ptr <= write_ptr + 1;
                end
            end
            else if (cl_rd) begin
                if (full) begin //Replace out with build, reset ptr
                    for (i = 0; i < DATA_PER_CL; i = i + 1) begin
                        out_cl[i * DATA_WIDTH +: DATA_WIDTH] <= build_cl[i];
                        build_cl[i] <= '0;
                    end

                    cl_valid <= 1;
                    write_ptr <= '0;
                end
                else begin //Clear out
                    out_cl <= '0;
                    cl_valid <= 0;
                end
            end
        end
        else begin //evict
            for (i = 0; i < DATA_PER_CL; i = i + 1) begin
                if (i < write_ptr) begin
                    out_cl[i * DATA_WIDTH +: DATA_WIDTH] <= build_cl[i];
                end
                else begin
                    if (EVICTION_POLICY == "ALL_ZEROS") begin
                        out_cl[i * DATA_WIDTH +: DATA_WIDTH] <= '0;
                    end
                    else if (EVICTION_POLICY == "ALL_ONES") begin
                        out_cl[i * DATA_WIDTH +: DATA_WIDTH] <= '1;
                    end
                end

                build_cl[i] <= '0;
            end

            write_ptr <= '0;
            cl_valid <= 1;
        end
    end