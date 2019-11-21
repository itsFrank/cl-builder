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

    logic                       build_data_valid    [DATA_PER_CL];
    logic [DATA_WIDTH - 1 : 0 ] build_cl            [DATA_PER_CL];

    always_ff @(posedge clk) begin
        for (int i = 1; i < DATA_PER_CL; i++) begin
            if (data_wr) begin
                build_cl[i] <= build_cl[i-1];
                build_data_valid[i] <= build_data_valid[i-1];
            end
            else begin
                
            end
        end
    end



endmodule