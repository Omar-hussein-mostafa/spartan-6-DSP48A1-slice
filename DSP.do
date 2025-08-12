vlib work
vlog DSP_op.v DSP_tb.v seq_comb_op.v
vsim -voptargs=+acc work.DSP_tb
add wave *
run -all
#quit -sim