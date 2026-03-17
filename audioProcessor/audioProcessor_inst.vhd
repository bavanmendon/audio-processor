	component audioProcessor is
		port (
			bass_stage_switch_export                   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			clk_clk                                    : in  std_logic                     := 'X';             -- clk
			green_leds_export                          : out std_logic_vector(7 downto 0);                     -- export
			mute_button_export                         : in  std_logic                     := 'X';             -- export
			nios_data_ready_external_connection_export : in  std_logic                     := 'X';             -- export
			nios_in_left_external_connection_export    : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
			nios_in_right_external_connection_export   : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
			nios_out_left_external_connection_export   : out std_logic_vector(15 downto 0);                    -- export
			nios_out_right_external_connection_export  : out std_logic_vector(15 downto 0);                    -- export
			red_leds_export                            : out std_logic_vector(17 downto 0);                    -- export
			reset_reset_n                              : in  std_logic                     := 'X';             -- reset_n
			treble_stage_switch_export                 : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			volume_down_button_export                  : in  std_logic                     := 'X';             -- export
			volume_up_button_export                    : in  std_logic                     := 'X'              -- export
		);
	end component audioProcessor;

	u0 : component audioProcessor
		port map (
			bass_stage_switch_export                   => CONNECTED_TO_bass_stage_switch_export,                   --                   bass_stage_switch.export
			clk_clk                                    => CONNECTED_TO_clk_clk,                                    --                                 clk.clk
			green_leds_export                          => CONNECTED_TO_green_leds_export,                          --                          green_leds.export
			mute_button_export                         => CONNECTED_TO_mute_button_export,                         --                         mute_button.export
			nios_data_ready_external_connection_export => CONNECTED_TO_nios_data_ready_external_connection_export, -- nios_data_ready_external_connection.export
			nios_in_left_external_connection_export    => CONNECTED_TO_nios_in_left_external_connection_export,    --    nios_in_left_external_connection.export
			nios_in_right_external_connection_export   => CONNECTED_TO_nios_in_right_external_connection_export,   --   nios_in_right_external_connection.export
			nios_out_left_external_connection_export   => CONNECTED_TO_nios_out_left_external_connection_export,   --   nios_out_left_external_connection.export
			nios_out_right_external_connection_export  => CONNECTED_TO_nios_out_right_external_connection_export,  --  nios_out_right_external_connection.export
			red_leds_export                            => CONNECTED_TO_red_leds_export,                            --                            red_leds.export
			reset_reset_n                              => CONNECTED_TO_reset_reset_n,                              --                               reset.reset_n
			treble_stage_switch_export                 => CONNECTED_TO_treble_stage_switch_export,                 --                 treble_stage_switch.export
			volume_down_button_export                  => CONNECTED_TO_volume_down_button_export,                  --                  volume_down_button.export
			volume_up_button_export                    => CONNECTED_TO_volume_up_button_export                     --                    volume_up_button.export
		);

