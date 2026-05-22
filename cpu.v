`timescale 1ns / 1ps

//================ PROGRAM COUNTER =================
module pc_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'd0;
        else
            pc <= next_pc;
    end
endmodule

//================ CONTROL UNIT =================
module control_unit (
    input  wire [5:0] opcode,
    output reg        reg_write,
    output reg        alu_src,
    output reg        mem_to_reg,
    output reg        mem_read,
    output reg        mem_write,
    output reg [3:0]  alu_ctrl
);
    always @(*) begin
        reg_write  = 0;
        alu_src    = 0;
        mem_to_reg = 0;
        mem_read   = 0;
        mem_write  = 0;
        alu_ctrl   = 4'b0000;

        case (opcode)
            6'b000000: begin reg_write=1; alu_ctrl=4'b0000; end
            6'b000001: begin reg_write=1; alu_ctrl=4'b0001; end
            6'b000010: begin reg_write=1; alu_ctrl=4'b0010; end
            6'b000011: begin reg_write=1; alu_ctrl=4'b0011; end
            6'b000100: begin reg_write=1; alu_ctrl=4'b0110; end
            6'b000101: begin reg_write=1; alu_src=1; alu_ctrl=4'b0000; end
            6'b000110: begin reg_write=1; alu_src=1; mem_to_reg=1; mem_read=1; end
            6'b000111: begin alu_src=1; mem_write=1; end
            6'b001000: begin reg_write=1; alu_ctrl=4'b0100; end
            6'b001001: begin reg_write=1; alu_ctrl=4'b1001; end
            default: ;
        endcase
    end
endmodule

//================ REGISTER FILE =================
module reg_file (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] regs [0:31];
    integer i;

    assign rd1 = (rs1==0) ? 32'd0 : regs[rs1];
    assign rd2 = (rs2==0) ? 32'd0 : regs[rs2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            for (i=0;i<32;i=i+1) regs[i] <= 32'd0;
        else if (we && rd!=0)
            regs[rd] <= wd;
    end
endmodule

//================ ALU =================
module alu_32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] y
);
    wire [63:0] mul_res = a * b;

    always @(*) begin
        case (alu_ctrl)
            4'b0000: y = a + b;
            4'b0001: y = a - b;
            4'b0010: y = a & b;
            4'b0011: y = a | b;
            4'b0100: y = mul_res[31:0];
            4'b0110: y = a ^ b;
            4'b1001: y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default: y = 32'd0;
        endcase
    end
endmodule

//================ TOP MODULE =================
module cpu_core (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] imem_rdata,
    input  wire [31:0] dmem_rdata,

    output wire [31:0] imem_addr,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire        dmem_we,
    output wire        dmem_re
);

    wire [31:0] pc, instr;
    wire [31:0] r1, r2, alu_out, imm_ext, result;
    wire reg_write, alu_src, mem_to_reg, mem_read, mem_write;
    wire [3:0] alu_ctrl;
    wire [4:0] rd;

    assign instr = imem_rdata;
    assign imem_addr = pc;

    assign imm_ext = {{16{instr[15]}}, instr[15:0]};

    assign rd = (instr[31:26]==6'b000101 || instr[31:26]==6'b000110) ?
                instr[20:16] : instr[15:11];

    pc_reg PC (.clk(clk), .rst_n(rst_n), .next_pc(pc+4), .pc(pc));

    control_unit CU (
        .opcode(instr[31:26]),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_ctrl(alu_ctrl)
    );

    reg_file RF (
        .clk(clk), .rst_n(rst_n), .we(reg_write),
        .rs1(instr[25:21]), .rs2(instr[20:16]),
        .rd(rd), .wd(result),
        .rd1(r1), .rd2(r2)
    );

    alu_32 ALU (
        .a(r1),
        .b(alu_src ? imm_ext : r2),
        .alu_ctrl(alu_ctrl),
        .y(alu_out)
    );

    assign dmem_addr  = alu_out;
    assign dmem_wdata = r2;
    assign dmem_we    = mem_write;
    assign dmem_re    = mem_read;

    assign result = mem_to_reg ? dmem_rdata : alu_out;

endmodule
