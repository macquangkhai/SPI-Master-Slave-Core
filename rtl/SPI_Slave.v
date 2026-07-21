module spi_slave (
    input wire sck,
    input wire cs_n,
    input wire mosi,
    output wire miso,

    // Slave Local Interface
    input wire [7:0] slave_tx_data,   // Transmit data ready to send to Master
    output reg [7:0] slave_rx_data,   // Received data latch output
    output reg slave_rx_valid         // Valid flag for received data
);
    reg [2:0] bit_cnt;    // Bit counter (0 to 7)
    reg [7:0] rx_shifter; // Receive shift register for MOSI data

    // Receive shift register logic (Synchronous to posedge SCK)
    // cs_n acts as asynchronous reset/enable for this block
    always @(posedge sck or posedge cs_n) begin
        if (cs_n) begin
            rx_shifter <= 8'd0;
            bit_cnt    <= 3'd0;
        end
        else begin
            rx_shifter <= {rx_shifter[6:0], mosi}; // Shift MOSI bit into LSB
            bit_cnt    <= bit_cnt + 1'b1;         // Increment bit counter
        end
    end

    reg [7:0] tx_shifter; // Transmit shift register for MISO data

    // Transmit shift register logic (Synchronous to negedge SCK)
    always @(negedge sck or posedge cs_n) begin
        if (cs_n) begin
            tx_shifter <= 8'd0; // Reset shift register when deselected (cs_n = 1)
        end
        else begin
            // On first falling edge (after bit_cnt incremented to 1 on previous rising edge)
            if (bit_cnt == 3'd1) begin
                tx_shifter <= {slave_tx_data[6:0], 1'b0}; // Dynamically load remaining 7 bits
            end
            else begin
                tx_shifter <= {tx_shifter[6:0], 1'b0};    // Shift next bits
            end
        end
    end

    // Combinational MISO output multiplexing:
    // - Idle (cs_n = 1): High impedance (High-Z) for bus sharing
    // - Start (cs_n = 0, bit_cnt = 0): Immediately output MSB (bit 7) of slave_tx_data
    // - Active Transfer (bit_cnt > 0): Output MSB of tx_shifter
    assign miso = (cs_n) ? 1'bz :
                  (bit_cnt == 3'd0) ? slave_tx_data[7] : tx_shifter[7];

    // Latch received data on transaction completion (cs_n rising edge)
    always @(posedge cs_n) begin
        // Check if full 8 bits were received (bit_cnt rolled over to 0)
        if (bit_cnt == 3'd0) begin
            slave_rx_data  <= rx_shifter;
            slave_rx_valid <= 1'b1;
        end
        else begin
            slave_rx_valid <= 1'b0;
        end
    end

endmodule