
module audioProcessor (
	bass_stage_switch_export,
	clk_clk,
	green_leds_export,
	mute_button_export,
	nios_data_ready_external_connection_export,
	nios_in_left_external_connection_export,
	nios_in_right_external_connection_export,
	nios_out_left_external_connection_export,
	nios_out_right_external_connection_export,
	red_leds_export,
	reset_reset_n,
	treble_stage_switch_export,
	volume_down_button_export,
	volume_up_button_export);	

	input	[1:0]	bass_stage_switch_export;
	input		clk_clk;
	output	[7:0]	green_leds_export;
	input		mute_button_export;
	input		nios_data_ready_external_connection_export;
	input	[15:0]	nios_in_left_external_connection_export;
	input	[15:0]	nios_in_right_external_connection_export;
	output	[15:0]	nios_out_left_external_connection_export;
	output	[15:0]	nios_out_right_external_connection_export;
	output	[17:0]	red_leds_export;
	input		reset_reset_n;
	input	[1:0]	treble_stage_switch_export;
	input		volume_down_button_export;
	input		volume_up_button_export;
endmodule
