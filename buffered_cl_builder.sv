/* 
    File: buffered_cl_builder.sv
    Author: Francis O'Brien
    Email: francis.obrien@mail.utoronto.ca
    Create Date: 11-24-2019
    -----------------------------------------
    Desc
        An extension of the cl_builder module with output CL buffer & input alm_full signal
    -----------------------------------------
    History
        11-24-2019: created
*/

module buffered_cl_builder
#(
    parameter DATA_WIDTH = 32,
    parameter DATA_PER_CL = 16,
    parameter CL_WIDTH = 512,
    parameter EVICTION_POLICY = "ALL_ZEROS", //possible values: 'ALL_ONES', 'ALL_ZEROS'
    parameter BUFFER_DEPTH = 8, // Number of CLs that can be buffered
    parameter ALM_FULL_DIFF = 4 // If #available spots < this value -> alm_full is asserted
)
(
    input logic clk,
    input logic reset,

    input logic evict,

    input logic data_wr,
    input logic [DATA_WIDTH - 1 : 0 ] data_in,

    input logic cl_rd,
    output logic alm_full,
    output logic out_cl_valid,
    output logic [CL_WIDTH - 1 : 0 ] out_cl
);

    // Internal Signals
    logic clb_out_cl_valid;
    logic [CL_WIDTH - 1 : 0 ] clb_out_cl;

    i_fifo #(.DATA_WIDTH(CL_WIDTH), .COUNT_WIDTH($clog2(BUFFER_DEPTH))) buffer_fifo ();

    assign buffer_fifo.reset = reset;
    assign buffer_fifo.rd_en = cl_rd;

    assign out_cl_valid    = ~buffer_fifo.empty;
    assign out_cl       = buffer_fifo.data_out;
    assign alm_full     = buffer_fifo.alm_full;

    always_ff @(posedge clk) begin
        buffer_fifo.wr_en   <= clb_out_cl_valid;
        buffer_fifo.data_in <= clb_out_cl;
    end

    cl_builder #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_PER_CL(DATA_PER_CL),
        .CL_WIDTH(CL_WIDTH),
        .EVICTION_POLICY(EVICTION_POLICY)
    ) cl_builder_internal_mod (
        .clk(clk),
        .reset(reset),

        .evict(evict),

        .data_wr(data_wr),
        .data_in(data_in),

        .out_cl_valid(clb_out_cl_valid),
        .out_cl(clb_out_cl)
    );

    SCFIFO #(
        .FWFT("ON"),
        .DATA_WIDTH(CL_WIDTH),
        .DEPTH(BUFFER_DEPTH),
        .COUNT_WIDTH($clog2(BUFFER_DEPTH)),
        .ALM_FULL_DIFF(ALM_FULL_DIFF),
        .ALM_EMPTY_DIFF(0)
    ) buffer_fifo_mod (
        .clock(clk), 
        .fifo_if(buffer_fifo)
    );

endmodule