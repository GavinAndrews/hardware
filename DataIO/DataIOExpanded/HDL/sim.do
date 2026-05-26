# Questa simulation script — DataIOExpandedHDL
# Run from the project directory:  do sim.do

# ---------------------------------------------------------------
# Library
# ---------------------------------------------------------------
if {[file isdirectory work]} { vdel -lib work -all }
vlib work
vmap work work

# ---------------------------------------------------------------
# Compile (dependency order)
# ---------------------------------------------------------------
vlog -work work -stats=none ram.v
vlog -work work -stats=none verilog.v
vlog -work work -stats=none verilog_tb.v

# ---------------------------------------------------------------
# Simulate
# -onfinish stop keeps the GUI open after $finish so you can
# inspect waveforms without losing the simulation state.
# -voptargs="+acc" passes +acc into vsim's internal vopt pass
# so all signals remain visible in the wave window.
# ---------------------------------------------------------------
vsim -t 1ps -onfinish stop -voptargs="+acc" work.dataio_29b_memory_tb

# ---------------------------------------------------------------
# Waves
# ---------------------------------------------------------------
add wave -divider "Clock / Control"
add wave -radix binary      sim:/dataio_29b_memory_tb/nVO2
add wave -radix binary      sim:/dataio_29b_memory_tb/nEN
add wave -radix binary      sim:/dataio_29b_memory_tb/nWR

add wave -divider "CPU Address"
add wave -radix hexadecimal -group "CPU_ADDR" \
    sim:/dataio_29b_memory_tb/A15 \
    sim:/dataio_29b_memory_tb/A14 \
    sim:/dataio_29b_memory_tb/A13 \
    sim:/dataio_29b_memory_tb/A12 \
    sim:/dataio_29b_memory_tb/A11 \
    sim:/dataio_29b_memory_tb/A10 \
    sim:/dataio_29b_memory_tb/A9  \
    sim:/dataio_29b_memory_tb/A8  \
    sim:/dataio_29b_memory_tb/A7  \
    sim:/dataio_29b_memory_tb/A6  \
    sim:/dataio_29b_memory_tb/A5  \
    sim:/dataio_29b_memory_tb/A4  \
    sim:/dataio_29b_memory_tb/A3  \
    sim:/dataio_29b_memory_tb/A2  \
    sim:/dataio_29b_memory_tb/A1  \
    sim:/dataio_29b_memory_tb/A0

add wave -divider "CPU Data"
add wave -radix hexadecimal sim:/dataio_29b_memory_tb/cpu_data_out
add wave -radix hexadecimal sim:/dataio_29b_memory_tb/cpu_data_in
add wave -radix hexadecimal sim:/dataio_29b_memory_tb/read_data

add wave -divider "CPLD Outputs"
add wave -radix binary      sim:/dataio_29b_memory_tb/nRAM_A
add wave -radix binary      sim:/dataio_29b_memory_tb/nRAM_B
add wave -radix binary      sim:/dataio_29b_memory_tb/nRAM_WE
add wave -radix binary      -group "BANK" \
    sim:/dataio_29b_memory_tb/RB4 \
    sim:/dataio_29b_memory_tb/RB3 \
    sim:/dataio_29b_memory_tb/RB2 \
    sim:/dataio_29b_memory_tb/RB1 \
    sim:/dataio_29b_memory_tb/RB0

add wave -divider "Config / Status"
add wave -radix binary      sim:/dataio_29b_memory_tb/SEL0
add wave -radix binary      sim:/dataio_29b_memory_tb/SEL1
add wave -radix binary      sim:/dataio_29b_memory_tb/test_passed

configure wave -timelineunits us
wave zoom full

# ---------------------------------------------------------------
# Run to $finish
# ---------------------------------------------------------------
run -all
