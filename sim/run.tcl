# ==============================================================================
# run.tcl - Script chạy mô phỏng dự án SPI trên Questa Sim / ModelSim
# ==============================================================================

# 1. Khởi tạo thư viện làm việc (work library)
if [file exists work] {
    vdel -all
}
vlib work
vmap work work

# 2. Biên dịch các tệp nguồn Verilog từ thư mục rtl và tb
echo "========================================="
echo "   BAT DAU BIEN DICH CAC FILE VERILOG    "
echo "========================================="
vlog -work work ../rtl/SPI_Master.v
vlog -work work ../rtl/SPI_Slave.v
vlog -work work ../tb/tb.v

# 3. Khởi chạy mô phỏng module testbench (spi_tb)
# Tùy chọn -voptargs="+acc" cho phép tối ưu hóa nhưng vẫn giữ khả năng xem dạng sóng
vsim -voptargs="+acc" work.spi_tb

# 4. Thêm các tín hiệu cần quan sát vào cửa sổ Waveform
echo "========================================="
echo "       CAU HINH DUONG SONG (WAVE)        "
echo "========================================="
add wave -divider "SYSTEM SIGNALS"
add wave -position insertpoint sim:/spi_tb/clk
add wave -position insertpoint sim:/spi_tb/rst_n

add wave -divider "SPI PHYSICAL BUS"
add wave -color "yellow" -position insertpoint sim:/spi_tb/cs_n
add wave -color "cyan"   -position insertpoint sim:/spi_tb/sck
add wave -color "green"  -position insertpoint sim:/spi_tb/mosi
add wave -color "orange" -position insertpoint sim:/spi_tb/miso

add wave -divider "MASTER CONTROL"
add wave -position insertpoint sim:/spi_tb/start
add wave -position insertpoint sim:/spi_tb/ready
add wave -hex -position insertpoint sim:/spi_tb/tx_data
add wave -hex -position insertpoint sim:/spi_tb/rx_data

add wave -divider "SLAVE CONTROL"
add wave -hex -position insertpoint sim:/spi_tb/slave_tx_data
add wave -hex -position insertpoint sim:/spi_tb/slave_rx_data
add wave -position insertpoint sim:/spi_tb/slave_rx_valid

add wave -divider "MASTER INTERNAL REGISTERS"
add wave -position insertpoint sim:/spi_tb/u_master/state
add wave -radix unsigned -position insertpoint sim:/spi_tb/u_master/clk_cnt
add wave -radix unsigned -position insertpoint sim:/spi_tb/u_master/bit_cnt
add wave -hex -position insertpoint sim:/spi_tb/u_master/tx_shifter
add wave -hex -position insertpoint sim:/spi_tb/u_master/rx_shifter

add wave -divider "SLAVE INTERNAL REGISTERS"
add wave -radix unsigned -position insertpoint sim:/spi_tb/u_slave/bit_cnt
add wave -hex -position insertpoint sim:/spi_tb/u_slave/tx_shifter
add wave -hex -position insertpoint sim:/spi_tb/u_slave/rx_shifter

# 5. Chạy mô phỏng toàn bộ kịch bản
echo "========================================="
echo "         BAT DAU CHAY MO PHONG           "
echo "========================================="
run -all

# Tự động zoom vừa màn hình dạng sóng để kỹ sư dễ quan sát
wave zoom full
