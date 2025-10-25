// tb_aes.v
`timescale 1ns/1ps
module tb_aes;
    reg clk;
    reg rstn;
    reg start;
    reg [127:0] key;
    reg [127:0] pt;
    wire [127:0] ct;
    wire valid;

    aes_top dut (
        .clk(clk), .rstn(rstn), .start(start), .key_in(key), .plaintext_in(pt),
        .ciphertext_out(ct), .valid_out(valid)
    );

    initial begin
        clk = 0; forever #5 clk = ~clk; // 100MHz sim clock
    end

    initial begin
        rstn = 0; start = 0;
        #20; rstn = 1;
        // Test vector:
        key = 128'h000102030405060708090A0B0C0D0E0F;
        pt  = 128'h00112233445566778899AABBCCDDEEFF;
        #10;
        start = 1;
        #10;
        start = 0;

        // Wait for valid; measure cycles
        wait (valid == 1);
        $display("Ciphertext = %032x", ct);
        if (ct == 128'h69C4E0D86A7B0430D8CDB78070B4C55A)
            $display("AES-128 Test Passed!");
        else
            $display("AES-128 Test FAILED!");
        #20;
        $finish;
    end
endmodule
