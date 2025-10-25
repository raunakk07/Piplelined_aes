// key_sched_seq.v
// Sequential AES-128 key scheduler: computes round keys sequentially.
module key_sched_seq (
    input  wire        clk,
    input  wire        rstn,
    input  wire        load_key,   // pulse to load a new key (rising edge)
    input  wire [127:0] key_in,
    output reg         busy,
    output reg         keys_ready, // 1 when all 11 roundkeys are computed and stored
    output reg [127:0] roundkey [0:10] // array of 11 roundkeys (indexed)
);
    // Use 32-bit words
    reg [31:0] w [0:43]; // for AES-128: 44 words (4*(Nr+1)) ; 11 roundkeys * 4 words
    reg [3:0] gen_round; // count words generated (0..43)
    reg generating;

    // Rcon table (only first 10 values needed)
    function [31:0] rcon_word;
        input [3:0] idx;
        reg [7:0] r;
        begin
            case (idx)
                4'd1: r = 8'h01; 4'd2: r = 8'h02; 4'd3: r = 8'h04; 4'd4: r = 8'h08;
                4'd5: r = 8'h10; 4'd6: r = 8'h20; 4'd7: r = 8'h40; 4'd8: r = 8'h80;
                4'd9: r = 8'h1b; 4'd10: r = 8'h36;
                default: r=8'h00;
            endcase
            rcon_word = {r,24'h0};
        end
    endfunction

    wire [31:0] temp;
    wire [31:0] temp_sub;
    reg [7:0] tb0, tb1, tb2, tb3;
    wire [31:0] rotword;
    // instantiate S-box for bytes used by key schedule
    wire [7:0] sb0, sb1, sb2, sb3;
    sbox s0(.i(tb0), .o(sb0));
    sbox s1(.i(tb1), .o(sb1));
    sbox s2(.i(tb2), .o(sb2));
    sbox s3(.i(tb3), .o(sb3));

    assign rotword = {tb1, tb2, tb3, tb0};
    assign temp = rotword;
    assign temp_sub = {sb0, sb1, sb2, sb3};

    integer i;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            busy <= 0;
            keys_ready <= 0;
            generating <= 0;
            gen_round <= 0;
            for (i=0;i<44;i=i+1) w[i] <= 32'h0;
            for (i=0;i<11;i=i+1) roundkey[i] <= 128'h0;
        end else begin
            if (load_key && !generating) begin
                // load the initial key into w[0..3]
                w[0] <= key_in[127:96];
                w[1] <= key_in[95:64];
                w[2] <= key_in[63:32];
                w[3] <= key_in[31:0];
                gen_round <= 4'd4;
                generating <= 1;
                busy <= 1;
                keys_ready <= 0;
            end else if (generating) begin
                // compute w[gen_round]..
                // compute temp bytes for sbox
                tb0 <= w[gen_round-1][31:24];
                tb1 <= w[gen_round-1][23:16];
                tb2 <= w[gen_round-1][15:8];
                tb3 <= w[gen_round-1][7:0];

                if ((gen_round % 4) == 0) begin
                    // w[i] = w[i-4] ^ SubWord(RotWord(w[i-1])) ^ Rcon[i/4]
                    w[gen_round] <= w[gen_round-4] ^ ( {sb0, sb1, sb2, sb3} ^ rcon_word(gen_round/4) );
                end else begin
                    w[gen_round] <= w[gen_round-4] ^ w[gen_round-1];
                end

                gen_round <= gen_round + 1;

                if (gen_round == 43) begin
                    // finished generation (w[0..43])
                    generating <= 0;
                    busy <= 0;
                    // pack into roundkey array (11 keys)
                    for (i=0;i<11;i=i+1) begin
                        roundkey[i] <= { w[4*i], w[4*i+1], w[4*i+2], w[4*i+3] };
                    end
                    keys_ready <= 1;
                end
            end else begin
                // idle
                busy <= 0;
            end
        end
    end
endmodule
