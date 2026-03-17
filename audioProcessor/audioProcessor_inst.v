	audioProcessor u0 (
		.bass_stage_switch_export                   (<connected-to-bass_stage_switch_export>),                   //                   bass_stage_switch.export
		.clk_clk                                    (<connected-to-clk_clk>),                                    //                                 clk.clk
		.green_leds_export                          (<connected-to-green_leds_export>),                          //                          green_leds.export
		.mute_button_export                         (<connected-to-mute_button_export>),                         //                         mute_button.export
		.nios_data_ready_external_connection_export (<connected-to-nios_data_ready_external_connection_export>), // nios_data_ready_external_connection.export
		.nios_in_left_external_connection_export    (<connected-to-nios_in_left_external_connection_export>),    //    nios_in_left_external_connection.export
		.nios_in_right_external_connection_export   (<connected-to-nios_in_right_external_connection_export>),   //   nios_in_right_external_connection.export
		.nios_out_left_external_connection_export   (<connected-to-nios_out_left_external_connection_export>),   //   nios_out_left_external_connection.export
		.nios_out_right_external_connection_export  (<connected-to-nios_out_right_external_connection_export>),  //  nios_out_right_external_connection.export
		.red_leds_export                            (<connected-to-red_leds_export>),                            //                            red_leds.export
		.reset_reset_n                              (<connected-to-reset_reset_n>),                              //                               reset.reset_n
		.treble_stage_switch_export                 (<connected-to-treble_stage_switch_export>),                 //                 treble_stage_switch.export
		.volume_down_button_export                  (<connected-to-volume_down_button_export>),                  //                  volume_down_button.export
		.volume_up_button_export                    (<connected-to-volume_up_button_export>)                     //                    volume_up_button.export
	);

