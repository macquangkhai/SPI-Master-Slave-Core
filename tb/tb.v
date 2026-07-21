`timescale 1ns/1ns

module spi_tb;

    // System Clock & Reset
    reg clk;
    reg rst_n;

    // Master Control Signals
    reg start;
    reg [7:0] tx_data;
    wire [7:0] rx_data;
    wire ready;

    // Physical SPI Bus (Interconnecting Master & Slave)
    wire sck;
    wire cs_n;
    wire mosi;
    wire miso;

    // Slave Interface Signals
    reg [7:0] slave_tx_data;
    wire [7:0] slave_rx_data;
    wire slave_rx_valid;

    // 1. Instantiate SPI Master Core
    spi_master u_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ready(ready),
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .clk_div(8'd4)
    );

    // 2. Instantiate SPI Slave Core
    spi_slave u_slave (
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .slave_tx_data(slave_tx_data),
        .slave_rx_data(slave_rx_data),
        .slave_rx_valid(slave_rx_valid)
    );

    // Generate 50MHz System Clock (20ns Period)
    initial clk = 0;
    always #10 clk = ~clk;

    // Main Simulation Environment
    initial begin
        // Initial signal values
        rst_n = 1'b0;
        start = 1'b0;
        tx_data = 8'h00;
        slave_tx_data = 8'h00;

        // Assert Reset for 100ns
        #100;
        rst_n = 1'b1;
        #50;

        // --- TRANSACTION 1: Master sends 8'hA5, Slave sends 8'h5A ---
        $display("[TB] Starting Transaction 1...");
        tx_data = 8'hA5;       // Master transmit data
        slave_tx_data = 8'h5A; // Slave transmit data

        @(posedge clk);
        start = 1'b1;          // Trigger transfer
        @(posedge clk);
        start = 1'b0;

        // Wait until Master is ready (ready = 1)
        @(posedge ready);
        #50;
        $display("[TB] Transaction 1 complete!");
        $display("[TB] Master received: 8'h%h (Expected: 8'h5A)", rx_data);
        $display("[TB] Slave received: 8'h%h (Expected: 8'hA5)", slave_rx_data);

        // --- TRANSACTION 2: Master sends 8'h3C, Slave sends 8'hC3 ---
        #100;
        $display("[TB] Starting Transaction 2...");
        tx_data = 8'h3C;
        slave_tx_data = 8'hC3;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        @(posedge ready);
        #50;
        $display("[TB] Transaction 2 complete!");
        $display("[TB] Master received: 8'h%h (Expected: 8'hC3)", rx_data);
        $display("[TB] Slave received: 8'h%h (Expected: 8'h3C)", slave_rx_data);

        #100;
        $display("[TB] Simulation completed successfully!");
        $finish;
    end

    // Dump VCD waveform file
    initial begin
        $dumpfile("spi_tb.vcd");
        $dumpvars(0, spi_tb);
    end

endmodule