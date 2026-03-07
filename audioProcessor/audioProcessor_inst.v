	audioProcessor u0 (
		.bass_stage_switch_export   (<connected-to-bass_stage_switch_export>),   //   bass_stage_switch.export
		.clk_clk                    (<connected-to-clk_clk>),                    //                 clk.clk
		.green_leds_export          (<connected-to-green_leds_export>),          //          green_leds.export
		.mute_button_export         (<connected-to-mute_button_export>),         //         mute_button.export
		.red_leds_export            (<connected-to-red_leds_export>),            //            red_leds.export
		.treble_stage_switch_export (<connected-to-treble_stage_switch_export>), // treble_stage_switch.export
		.volume_down_button_export  (<connected-to-volume_down_button_export>),  //  volume_down_button.export
		.volume_up_button_export    (<connected-to-volume_up_button_export>),    //    volume_up_button.export
		.i2c_master_serial_sda_in   (<connected-to-i2c_master_serial_sda_in>),   //   i2c_master_serial.sda_in
		.i2c_master_serial_scl_in   (<connected-to-i2c_master_serial_scl_in>),   //                    .scl_in
		.i2c_master_serial_sda_oe   (<connected-to-i2c_master_serial_sda_oe>),   //                    .sda_oe
		.i2c_master_serial_scl_oe   (<connected-to-i2c_master_serial_scl_oe>)    //                    .scl_oe
	);

