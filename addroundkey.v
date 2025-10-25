// addroundkey.v
module addroundkey (
    input  wire [127:0] state_in,
    input  wire [127:0] roundkey,
    output wire [127:0] state_out
);
    assign state_out = state_in ^ roundkey;
endmodule
