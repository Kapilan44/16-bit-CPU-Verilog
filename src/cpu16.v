`timescale 1ns/1ps

module x86_cpu(
    input clk,
    input reset,
    output reg [15:0] mem_addr,
    output reg [15:0] mem_wdata,
    output reg mem_we,
    input [15:0] mem_rdata
);

reg [15:0] AX,BX,CX,DX,SP,BP,SI,DI;
reg [15:0] IP,IR;
reg ZF,CF,SF,OF;
reg [2:0] state;

reg [15:0] src_data;
reg [15:0] result;

localparam FETCH  = 3'd0;
localparam DECODE = 3'd1;
localparam EXEC   = 3'd2;
localparam MEM_RD = 3'd3;
localparam MEM_WR = 3'd4;

localparam NOP  = 4'h0;
localparam MOV  = 4'h1;
localparam ADD  = 4'h2;
localparam SUB  = 4'h3;
localparam AND_ = 4'h4;
localparam OR_  = 4'h5;
localparam XOR_ = 4'h6;
localparam CMP  = 4'h7;
localparam JMP  = 4'h8;
localparam JZ   = 4'h9;
localparam JNZ  = 4'hA;
localparam PUSH = 4'hB;
localparam POP  = 4'hC;
localparam HLT  = 4'hF;

always @(*) begin
    case(IR[2:0])
        3'd0: src_data = AX;
        3'd1: src_data = BX;
        3'd2: src_data = CX;
        3'd3: src_data = DX;
        3'd4: src_data = SP;
        3'd5: src_data = BP;
        3'd6: src_data = SI;
        3'd7: src_data = DI;
        default: src_data = 16'h0000;
    endcase
end

always @(posedge clk) begin
    if(reset) begin
        AX <= 0;
        BX <= 0;
        CX <= 0;
        DX <= 0;
        SP <= 16'hFFFE;
        BP <= 0;
        SI <= 0;
        DI <= 0;
        IP <= 0;
        IR <= 0;
        ZF <= 0;
        CF <= 0;
        SF <= 0;
        OF <= 0;
        mem_addr <= 0;
        mem_wdata <= 0;
        mem_we <= 0;
        state <= FETCH;
    end
    else begin
        case(state)

            FETCH: begin
                mem_we <= 0;
                mem_addr <= IP;
                state <= DECODE;
            end

            DECODE: begin
                IR <= mem_rdata;
                state <= EXEC;
            end

            EXEC: begin
                case(IR[15:12])

                    NOP: begin
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                    MOV: begin
                        case(IR[11:9])
                            3'd0: AX <= src_data;
                            3'd1: BX <= src_data;
                            3'd2: CX <= src_data;
                            3'd3: DX <= src_data;
                            3'd4: SP <= src_data;
                            3'd5: BP <= src_data;
                            3'd6: SI <= src_data;
                            3'd7: DI <= src_data;
                        endcase
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                    ADD: begin
                        case(IR[11:9])
                            3'd0: begin
                                result = AX + src_data;
                                AX <= result;
                            end
                            3'd1: begin
                                result = BX + src_data;
                                BX <= result;
                            end
                            3'd2: begin
                                result = CX + src_data;
                                CX <= result;
                            end
                            3'd3: begin
                                result = DX + src_data;
                                DX <= result;
                            end
                            default: result = 0;
                        endcase
                        ZF <= (result == 0);
                        SF <= result[15];
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                    SUB: begin
                        case(IR[11:9])
                            3'd0: begin
                                result = AX - src_data;
                                AX <= result;
                            end
                            3'd1: begin
                                result = BX - src_data;
                                BX <= result;
                            end
                            3'd2: begin
                                result = CX - src_data;
                                CX <= result;
                            end
                            3'd3: begin
                                result = DX - src_data;
                                DX <= result;
                            end
                            default: result = 0;
                        endcase
                        ZF <= (result == 0);
                        SF <= result[15];
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                    AND_: begin
                        case(IR[11:9])
                            3'd0: AX <= AX & src_data;
                            3'd1: BX <= BX & src_data;
                            3'd2: CX <= CX & src_data;
                            3'd3: DX <= DX & src_data;
                        endcase
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                    OR_: begin
                        case(IR[11:9])
                            3'd0: AX <= AX | src_data;
                            3'd1: BX <= BX | src_data;
                            3'd2: CX <= CX | src_data;
                            3'd3: DX <= DX | src_data;
                        endcase
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                    XOR_: begin
                        case(IR[11:9])
                            3'd0: AX <= AX ^ src_data;
                            3'd1: BX <= BX ^ src_data;
                            3'd2: CX <= CX ^ src_data;
                            3'd3: DX <= DX ^ src_data;
                        endcase
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                    CMP: begin
                        case(IR[11:9])
                            3'd0: result = AX - src_data;
                            3'd1: result = BX - src_data;
                            3'd2: result = CX - src_data;
                            3'd3: result = DX - src_data;
                            default: result = 0;
                        endcase
                        ZF <= (result == 0);
                        SF <= result[15];
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                    JMP: begin
                        IP <= {4'b0000,IR[11:0]};
                        state <= FETCH;
                    end

                    JZ: begin
                        if(ZF)
                            IP <= {4'b0000,IR[11:0]};
                        else
                            IP <= IP + 1;
                        state <= FETCH;
                    end

                    JNZ: begin
                        if(!ZF)
                            IP <= {4'b0000,IR[11:0]};
                        else
                            IP <= IP + 1;
                        state <= FETCH;
                    end

                    PUSH: begin
                        SP <= SP - 1;
                        mem_addr <= SP - 1;
                        mem_wdata <= src_data;
                        mem_we <= 1;
                        IP <= IP + 1;
                        state <= MEM_WR;
                    end

                    POP: begin
                        mem_addr <= SP;
                        mem_we <= 0;
                        state <= MEM_RD;
                    end

                    HLT: begin
                        state <= EXEC;
                    end

                    default: begin
                        IP <= IP + 1;
                        state <= FETCH;
                    end

                endcase
            end

            MEM_WR: begin
                mem_we <= 0;
                state <= FETCH;
            end

            MEM_RD: begin
                case(IR[11:9])
                    3'd0: AX <= mem_rdata;
                    3'd1: BX <= mem_rdata;
                    3'd2: CX <= mem_rdata;
                    3'd3: DX <= mem_rdata;
                    3'd4: SP <= mem_rdata;
                    3'd5: BP <= mem_rdata;
                    3'd6: SI <= mem_rdata;
                    3'd7: DI <= mem_rdata;
                endcase
                SP <= SP + 1;
                IP <= IP + 1;
                state <= FETCH;
            end

            default: state <= FETCH;

        endcase
    end
end

endmodule
