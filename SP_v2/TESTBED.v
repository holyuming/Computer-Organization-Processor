//========================================
//  version 2
//  released: 2021.12.24
//========================================

`timescale 1ns/10ps
`include "SP.v"
`include "PATTERN.v"
`include "PATTERN_p.v"
`include "MEM.v"

module TESTBED;

// wire connection
wire clk,rst_n,in_valid,out_valid,mem_wen;
wire [11:0] mem_addr;
wire [31:0] inst,mem_dout,inst_addr,mem_din;

initial begin
    $fsdbDumpfile("SP.fsdb");
    $fsdbDumpvars(0,"+mda");
end

SP My_SP(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .out_valid(out_valid),
    .mem_wen(mem_wen),
    .inst(inst),
    .mem_dout(mem_dout),
    .inst_addr(inst_addr),
    .mem_addr(mem_addr),
    .mem_din(mem_din)
);

MEM My_MEM(
    .Q(mem_dout),
    .CLK(clk),
    .CEN(1'b0),
    .WEN(mem_wen),
    .A(mem_addr),
    .D(mem_din),
    .OEN(1'b0)
);

// modify "PATTERN My_PATTERN" to "PATTERN_p My_PATTERN" for pipelined design 
PATTERN My_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .out_valid(out_valid),
    .inst(inst),
    .inst_addr(inst_addr)
);

endmodule