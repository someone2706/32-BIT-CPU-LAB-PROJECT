`timescale 1ns / 1ps

module cpu_tb;

    reg clk, rst_n;

    wire [31:0] imem_addr, dmem_addr, dmem_wdata;
    reg  [31:0] imem_rdata, dmem_rdata;
    wire dmem_we, dmem_re;

    cpu_core DUT (
        .clk(clk), .rst_n(rst_n),
        .imem_rdata(imem_rdata),
        .dmem_rdata(dmem_rdata),
        .imem_addr(imem_addr),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_re(dmem_re)
    );

    // Instruction memory
    reg [31:0] imem [0:63];
    always @(*) imem_rdata = imem[imem_addr[7:2]];

    // Data memory
    reg [31:0] dmem [0:255];
    always @(posedge clk) if (dmem_we) dmem[dmem_addr[7:0]] <= dmem_wdata;
    always @(*) dmem_rdata = dmem_re ? dmem[dmem_addr[7:0]] : 32'd0;

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        #10 rst_n = 1;

        // Program
        imem[0] = 32'b000101_00000_00001_0000000000001010; // ADDI R1 = 10
        imem[1] = 32'b000101_00000_00010_0000000000010100; // ADDI R2 = 20
        imem[2] = 32'b000000_00001_00010_00011_00000000000; // ADD R3 = R1+R2

        #100;

        $display("R1 = %0d", DUT.RF.regs[1]);
        $display("R2 = %0d", DUT.RF.regs[2]);
        $display("R3 = %0d (EXPECTED 30)", DUT.RF.regs[3]);

        $finish;
    end

endmodule
