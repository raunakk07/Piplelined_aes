// mixcolumns.v
module mixcolumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
function [7:0] xtime;
    input [7:0] a;
    begin
        xtime = {a[6:0],1'b0} ^ (8'h1b & {8{a[7]}});
    end
endfunction

function [7:0] mul_by_2;
    input [7:0] a; begin mul_by_2 = xtime(a); end
endfunction

function [7:0] mul_by_3;
    input [7:0] a; begin mul_by_3 = xtime(a) ^ a; end
endfunction

genvar c;
generate
    for (c = 0; c < 4; c = c + 1) begin : col
        wire [7:0] s0 = state_in[127 - (32*c) -: 8];
        wire [7:0] s1 = state_in[119 - (32*c) -: 8];
        wire [7:0] s2 = state_in[111 - (32*c) -: 8];
        wire [7:0] s3 = state_in[103 - (32*c) -: 8];

        // MixColumns on column [s0 s1 s2 s3]^T
        wire [7:0] r0 = mul_by_2(s0) ^ mul_by_3(s1) ^ s2 ^ s3;
        wire [7:0] r1 = s0 ^ mul_by_2(s1) ^ mul_by_3(s2) ^ s3;
        wire [7:0] r2 = s0 ^ s1 ^ mul_by_2(s2) ^ mul_by_3(s3);
        wire [7:0] r3 = mul_by_3(s0) ^ s1 ^ s2 ^ mul_by_2(s3);

        assign state_out[127 - (32*c) -: 8] = r0;
        assign state_out[119 - (32*c) -: 8] = r1;
        assign state_out[111 - (32*c) -: 8] = r2;
        assign state_out[103 - (32*c) -: 8] = r3;
    end
endgenerate
endmodule
