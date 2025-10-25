// shiftrows.v
module shiftrows (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    // AES state in column-major: bytes 0..15 map to state[127:0] appropriately in this code's convention.
    // We'll treat state_in as 16 bytes [b0..b15] with b0 = MSB 127:120.
    wire [7:0] b [0:15];
    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin
            assign b[i] = state_in[127 - 8*i -: 8];
        end
    endgenerate

    // ShiftRows: row 0 stays, row1 left rotate by1, row2 by2, row3 by3.
    // AES standard mapping: state arranged as 4x4 columns; assume b[col*4 + row]
    wire [7:0] outb [0:15];
    genvar c,r;
    generate
        for (c=0; c<4; c=c+1) begin
            assign outb[c*4 + 0] = b[c*4 + 0];
            assign outb[c*4 + 1] = b[((c+1)%4)*4 + 1];
            assign outb[c*4 + 2] = b[((c+2)%4)*4 + 2];
            assign outb[c*4 + 3] = b[((c+3)%4)*4 + 3];
        end
    endgenerate

    generate
        for (i=0; i<16; i=i+1) begin
            assign state_out[127 - 8*i -: 8] = outb[i];
        end
    endgenerate
endmodule
