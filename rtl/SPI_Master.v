module spi_master (
    // Clock and Reset
    input wire clk,
    input wire rst_n,

    // Host Control Interface
    input wire start,
    input wire [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg ready,

    // Physical SPI Interface
    output reg sck, // Serial Clock
    output reg cs_n, // Chip Select (Active Low)
    output reg mosi, // Master Out Slave In
    input wire miso, // Master In Slave Out
    input wire [7:0] clk_div // Dynamic clock division ratio from APB register
);
    // Legacy static clock division parameter
    // parameter CLK_DIV = 4;
    // reg [$clog2(CLK_DIV)-1:0] clk_cnt;

    reg [7:0] clk_cnt;
    reg sck_en; // Enable signal for SCK generation

    wire sck_rise; // Rising edge strobe of SCK
    wire sck_fall; // Falling edge strobe of SCK

    // SCK generation synchronized with system clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 0;
            sck_en  <= 1'b0;
        end else begin
            if (sck_en) begin
                if (clk_cnt == (clk_div/2 - 1)) begin
                    clk_cnt <= 0;
                    sck     <= ~sck;
                end
                else begin
                    clk_cnt <= clk_cnt + 1'b1;
                end
            end
            else begin
                clk_cnt <= 0;
                sck     <= 1'b0; // Turn off SCK when idle (Mode 0)
            end
        end       
    end

    assign sck_rise = (sck_en && (clk_cnt == (clk_div/2 - 1)) && (sck == 1'b0));
    assign sck_fall = (sck_en && (clk_cnt == (clk_div/2 - 1)) && (sck == 1'b1));

    // FSM State Encoding
    localparam STATE_IDLE     = 1'b0;
    localparam STATE_TRANSFER = 1'b1;

    reg state;          // Current FSM state
    reg [2:0] bit_cnt;  // Bit counter (0 to 7)

    reg [7:0] tx_shifter; // Transmit shift register (MOSI)
    reg [7:0] rx_shifter; // Receive shift register (MISO)

    // FSM Control Logic (Synchronous to clk)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= STATE_IDLE;
            bit_cnt     <= 3'd0;
            tx_shifter  <= 8'd0;
            rx_shifter  <= 8'd0;
            rx_data     <= 8'd0;
            ready       <= 1'b1;
            cs_n        <= 1'b1;
            sck_en      <= 1'b0;
            mosi        <= 1'b0;
        end
        else begin
            case (state)
                STATE_IDLE: begin
                    ready   <= 1'b1;
                    cs_n    <= 1'b1;
                    sck_en  <= 1'b0;
                    mosi    <= 1'b0;
                    bit_cnt <= 3'd0;

                    // Trigger start pulse from CPU/Host
                    if (start) begin
                        tx_shifter <= tx_data;  // Load transmit data into shift register
                        cs_n       <= 1'b0;     // Assert Chip Select (Active Low)
                        sck_en     <= 1'b1;     // Enable SCK generator
                        ready      <= 1'b0;     // Assert Busy status
                        state      <= STATE_TRANSFER;
                    end
                end

                STATE_TRANSFER: begin
                    ready  <= 1'b0;
                    cs_n   <= 1'b0;
                    sck_en <= 1'b1;

                    // Update MOSI with MSB of transmit shift register
                    mosi <= tx_shifter[7];

                    // 1. SCK Rising Edge (Sample): Master samples MISO line
                    if (sck_rise) begin
                        rx_shifter <= {rx_shifter[6:0], miso}; // Shift received MISO bit into LSB
                    end

                    // 2. SCK Falling Edge (Shift): Master shifts next bit to MOSI
                    if (sck_fall) begin
                        tx_shifter <= {tx_shifter[6:0], 1'b0}; // Shift next bit to MSB for transmission

                        if (bit_cnt == 3'd7) begin
                            // 8-bit transfer complete
                            cs_n    <= 1'b1;       // Deassert Chip Select
                            sck_en  <= 1'b0;       // Disable SCK generator
                            ready   <= 1'b1;       // Set status to Ready
                            rx_data <= rx_shifter; // Write received shift data to rx_data output
                            state   <= STATE_IDLE;
                        end
                        else begin
                            bit_cnt <= bit_cnt + 1'b1; // Increment bit counter
                        end
                    end
                end
                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule