// aes_round.v
`include "sbox.v"
`include "shiftrows.v"
`include "mixcolumns.v"
`include "addroundkey.v"

module aes_round (
    input  wire         clk,
    input  wire         rstn,
    input  wire         en,           // when asserted, stage processes input (used for handshake)
    input  wire [127:0] state_in,
    input  wire [127:0] roundkey,
    input  wire         do_mix,       // 1 for normal rounds, 0 for final round
    output reg  [127:0] state_out
);
    // SubBytes
    wire [7:0] sb_in [0:15];
    wire [7:0] sb_out [0:15];
    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : SB
            assign sb_in[i] = state_in[127 - 8*i -: 8];
            sbox sbox_inst (.i(sb_in[i]), .o(sb_out[i]));
        end
    endgenerate

    // Combine SubBytes
    wire [127:0] after_sub;
    generate
        for (i=0; i<16; i=i+1) begin : PACKSUB
            assign after_sub[127 - 8*i -: 8] = sb_out[i];
        end
    endgenerate

    // ShiftRows
    wire [127:0] after_shift;
    shiftrows sr (.state_in(after_sub), .state_out(after_shift));

    // MixColumns (optional)
    wire [127:0] after_mix;
    mixcolumns mc (.state_in(after_shift), .state_out(after_mix));

    // AddRoundKey
    wire [127:0] after_add = (do_mix ? after_mix : after_shift) ^ roundkey;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) state_out <= 128'h0;
        else if (en) state_out <= after_add;
        else state_out <= state_out;
    end
endmodule
