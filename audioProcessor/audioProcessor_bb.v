
module audioProcessor (
	bass_stage_switch_export,
	clk_clk,
	green_leds_export,
	mute_button_export,
	red_leds_export,
	treble_stage_switch_export,
	volume_down_button_export,
	volume_up_button_export,
	i2c_master_serial_sda_in,
	i2c_master_serial_scl_in,
	i2c_master_serial_sda_oe,
	i2c_master_serial_scl_oe);	

	input	[1:0]	bass_stage_switch_export;
	input		clk_clk;
	output	[7:0]	green_leds_export;
	input		mute_button_export;
	output	[17:0]	red_leds_export;
	input	[1:0]	treble_stage_switch_export;
	input		volume_down_button_export;
	input		volume_up_button_export;
	input		i2c_master_serial_sda_in;
	input		i2c_master_serial_scl_in;
	output		i2c_master_serial_sda_oe;
	output		i2c_master_serial_scl_oe;
endmodule
