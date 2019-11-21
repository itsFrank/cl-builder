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

    input logic data_wr,
    input logic [DATA_WIDTH - 1 : 0 ] data_in,

    output logic cl_valid,
    output logic [CL_WIDTH - 1 : 0 ] out_cl
);

    logic                       build_data_valid    [DATA_PER_CL];
    logic [DATA_WIDTH - 1 : 0 ] build_cl            [DATA_PER_CL];

    logic [DATA_PER_CL - 1 : 0][DATA_WIDTH - 1 : 0 ] out_cl_elements;

    logic build_cl_full;
    
    assign build_cl_full = build_data_valid[DATA_PER_CL-1];
    assign out_cl = out_cl_elements;
    always_ff @(posedge clk) begin
        cl_valid <= build_cl_full;

        // Data insert
        if (data_wr) begin
            build_cl[0]         <= data_in;
            build_data_valid[0] <= 1;
        end
        else if (build_cl_full || evict) begin
            build_data_valid[0] <= 0;
        end
        
        // Data object chain
        for (int i = 1; i < DATA_PER_CL; i++) begin
            // Valid bit asserted when previous data is pushed forward and de-asserted when a complete CL is produced
            if (build_cl_full || evict) begin
                build_data_valid[i] <= 0;
            end
            else if (data_wr) begin
                build_data_valid[i] <= build_data_valid[i-1];
            end

            if (data_wr) begin
                build_cl[i] <= build_cl[i-1];
            end
        end

        // Move data to out cl
        for (int i = 0; i < DATA_PER_CL; i++) begin
            if (build_data_valid[i]) begin
                out_cl_elements[i] <= build_cl[i]
            end
            else begin
                if (EVICTION_POLICY == "ALL_ZEROS") begin
                    out_cl_elements[i] <= '0;
                end
                else if (EVICTION_POLICY == "ALL_ONES") begin
                    out_cl_elements[i] <= '1;
                end
            end
        end
    end



endmodule