`timescale 1ns/1ps

module tb_cpu16;

reg clk;
reg reset;

wire [15:0] mem_addr;
wire [15:0] mem_wdata;
wire        mem_we;
reg  [15:0] mem_rdata;

reg [15:0] memory [0:65535];

integer i;

x86_cpu uut (
    .clk       (clk),
    .reset     (reset),
    .mem_addr  (mem_addr),
    .mem_wdata (mem_wdata),
    .mem_we    (mem_we),
    .mem_rdata (mem_rdata)
);

/* Clock */
always #5 clk = ~clk;

/* Combinational read memory */
always @(*) begin
    mem_rdata = memory[mem_addr];
end

/* Synchronous write memory */
always @(posedge clk) begin
    if (mem_we)
        memory[mem_addr] <= mem_wdata;
end

function [15:0] INST;
    input [3:0] opcode;
    input [2:0] dst;
    input [2:0] src;
    begin
        INST = {opcode, dst, 3'b000, src, 3'b000};
    end
endfunction

function [15:0] JMP_INST;
    input [3:0] opcode;
    input [11:0] address;
    begin
        JMP_INST = {opcode, address};
    end
endfunction

initial begin

    /* Initialize testbench signals */
    clk       = 1'b0;
    reset     = 1'b1;
    mem_rdata = 16'h0000;

    /* Initialize whole memory */
    for (i = 0; i < 65536; i = i + 1)
        memory[i] = 16'h0000;

    /* Waveform */
    $dumpfile("wave/cpu16.vcd");
    $dumpvars(0, tb_cpu16);

    /*
     * Program
     */

    /* 0: NOP */
    memory[0] = 16'h0000;

    /* 1: MOV AX,AX */
    memory[1] = INST(4'h1, 3'd0, 3'd0);

    /* 2: MOV BX,BX */
    memory[2] = INST(4'h1, 3'd1, 3'd1);

    /* 3: MOV CX,CX */
    memory[3] = INST(4'h1, 3'd2, 3'd2);

    /* 4: MOV DX,DX */
    memory[4] = INST(4'h1, 3'd3, 3'd3);

    /* 5: ADD AX,BX */
    memory[5] = INST(4'h2, 3'd0, 3'd1);

    /* 6: ADD BX,CX */
    memory[6] = INST(4'h2, 3'd1, 3'd2);

    /* 7: ADD CX,DX */
    memory[7] = INST(4'h2, 3'd2, 3'd3);

    /* 8: ADD DX,AX */
    memory[8] = INST(4'h2, 3'd3, 3'd0);

    /* 9: SUB AX,BX */
    memory[9] = INST(4'h3, 3'd0, 3'd1);

    /* 10: SUB BX,CX */
    memory[10] = INST(4'h3, 3'd1, 3'd2);

    /* 11: SUB CX,DX */
    memory[11] = INST(4'h3, 3'd2, 3'd3);

    /* 12: SUB DX,AX */
    memory[12] = INST(4'h3, 3'd3, 3'd0);

    /* 13: AND AX,BX */
    memory[13] = INST(4'h4, 3'd0, 3'd1);

    /* 14: OR BX,CX */
    memory[14] = INST(4'h5, 3'd1, 3'd2);

    /* 15: XOR CX,DX */
    memory[15] = INST(4'h6, 3'd2, 3'd3);

    /* 16: CMP AX,BX */
    memory[16] = INST(4'h7, 3'd0, 3'd1);

    /* 17: PUSH AX */
    memory[17] = INST(4'hB, 3'd0, 3'd0);

    /* 18: PUSH BX */
    memory[18] = INST(4'hB, 3'd1, 3'd1);

    /* 19: POP BX */
    memory[19] = INST(4'hC, 3'd1, 3'd1);

    /* 20: POP AX */
    memory[20] = INST(4'hC, 3'd0, 3'd0);

    /* 21: JMP 23 */
    memory[21] = JMP_INST(4'h8, 12'd23);

    /* 22: NOP -- should be skipped */
    memory[22] = 16'h0000;

    /* 23: NOP */
    memory[23] = 16'h0000;

    /* 24: HLT */
    memory[24] = 16'hF000;

    /*
     * Keep testbench reset active for 2 clock cycles.
     * This removes initial X values before normal operation.
     */
    #20;
    @(negedge clk);
    reset = 1'b0;

    /* Let CPU run */
    #300;

    $display("======================================");
    $display("SIMULATION COMPLETED");
    $display("AX = %h", uut.AX);
    $display("BX = %h", uut.BX);
    $display("CX = %h", uut.CX);
    $display("DX = %h", uut.DX);
    $display("SP = %h", uut.SP);
    $display("IP = %h", uut.IP);
    $display("ZF = %b", uut.ZF);
    $display("SF = %b", uut.SF);
    $display("STATE = %d", uut.state);
    $display("======================================");

    $finish;

end

initial begin

    $monitor(
        "TIME=%0t RESET=%b STATE=%0d IP=%04h IR=%04h AX=%04h BX=%04h CX=%04h DX=%04h SP=%04h BP=%04h SI=%04h DI=%04h ZF=%b SF=%b MEM_WE=%b ADDR=%04h WDATA=%04h",
        $time,
        reset,
        uut.state,
        uut.IP,
        uut.IR,
        uut.AX,
        uut.BX,
        uut.CX,
        uut.DX,
        uut.SP,
        uut.BP,
        uut.SI,
        uut.DI,
        uut.ZF,
        uut.SF,
        mem_we,
        mem_addr,
        mem_wdata
    );

end

endmodule
 
