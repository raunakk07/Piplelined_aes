// aes_top.v
`timescale 1ns/1ps
module aes_top (
    input  wire         clk,
    input  wire         rstn,
    input  wire         start,        // pulse to start encrypting plaintext_in with key_in
    input  wire [127:0] key_in,
    input  wire [127:0] plaintext_in,
    output reg  [127:0] ciphertext_out,
    output reg          valid_out
);
    // Key scheduler
    reg ks_load;
    wire ks_busy, ks_ready;
    wire [127:0] rk [0:10];
    key_sched_seq keysched (
        .clk(clk), .rstn(rstn), .load_key(ks_load), .key_in(key_in),
        .busy(ks_busy), .keys_ready(ks_ready),
        .roundkey(rk)
    );

    // Control: on start pulse, load key and start pipeline when keys_ready.
    reg start_pending;
    reg [3:0] stage_valid; // counts pipeline depth and indicates data movement
    reg [127:0] stage_reg [0:10];

    integer s;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ks_load <= 0;
            start_pending <= 0;
            valid_out <= 0;
            for (s=0; s<11; s=s+1) begin stage_reg[s] <= 128'h0; end
            stage_valid <= 0;
            ciphertext_out <= 128'h0;
        end else begin
            // On start, request key schedule
            if (start) begin
                ks_load <= 1'b1;
                start_pending <= 1'b1;
                valid_out <= 1'b0;
            end else begin
                ks_load <= 1'b0;
            end

            // When keys ready and there is a pending start, push plaintext into round 0
            if (ks_ready && start_pending) begin
                stage_reg[0] <= plaintext_in ^ rk[0]; // initial AddRoundKey
                stage_valid[0] <= 1'b1;
                start_pending <= 1'b0;
            end

            // Pipeline shift: for rounds 1..9 do normal rounds (with MixColumns), round 10 is final
            // We use aes_round instances as combinational modules already registering outputs on en
            for (s=1; s<=10; s=s+1) begin
                // if previous stage valid, compute next stage result (we call modules later)
                // but here we just move stage_valid flags; actual computation handled in instances
                // We'll use stage_reg as registers filled by submodules via separate wires.
            end

            // valid_out driven by last pipeline stage
            // (populated by round instances assigned to stage_reg[10])
            if (stage_valid[10]) begin
                ciphertext_out <= stage_reg[10];
                valid_out <= 1'b1;
                // shift pipeline valid flags down
                stage_valid <= {1'b0, stage_valid[9:1]}; // rotate right - but we actually will let modules update regs
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

    // Instantiate rounds (combinational SBoxes + registers inside)
    wire [127:0] round_in [0:10];
    wire [127:0] round_out [0:10];
    // hook up inputs
    assign round_in[0] = stage_reg[0];
    genvar r;
    generate
        for (r=1; r<=9; r=r+1) begin : ROUNDS
            // Each round is enabled when previous stage had valid (we detect using a small register)
            // For simplicity we pass en = 1 when data present at round_in
            aes_round ar (
                .clk(clk), .rstn(rstn),
                .en(1'b1),
                .state_in(round_in[r-1]),
                .roundkey(rk[r]),
                .do_mix(1'b1),
                .state_out(round_out[r])
            );
            // register output to stage_reg for next cycle
            always @(posedge clk or negedge rstn) begin
                if (!rstn) stage_reg[r] <= 128'h0;
                else stage_reg[r] <= round_out[r];
            end
            assign round_in[r] = stage_reg[r];
        end
        // final round 10 no-mix
        aes_round ar_last (
            .clk(clk), .rstn(rstn),
            .en(1'b1),
            .state_in(round_in[9]),
            .roundkey(rk[10]),
            .do_mix(1'b0),
            .state_out(round_out[10])
        );
        always @(posedge clk or negedge rstn) begin
            if (!rstn) stage_reg[10] <= 128'h0;
            else stage_reg[10] <= round_out[10];
        end
    endgenerate

endmodule
