	component audioProcessor is
		port (
			bass_stage_switch_export   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			clk_clk                    : in  std_logic                     := 'X';             -- clk
			green_leds_export          : out std_logic_vector(7 downto 0);                     -- export
			mute_button_export         : in  std_logic                     := 'X';             -- export
			red_leds_export            : out std_logic_vector(17 downto 0);                    -- export
			treble_stage_switch_export : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			volume_down_button_export  : in  std_logic                     := 'X';             -- export
			volume_up_button_export    : in  std_logic                     := 'X';             -- export
			i2c_master_serial_sda_in   : in  std_logic                     := 'X';             -- sda_in
			i2c_master_serial_scl_in   : in  std_logic                     := 'X';             -- scl_in
			i2c_master_serial_sda_oe   : out std_logic;                                        -- sda_oe
			i2c_master_serial_scl_oe   : out std_logic                                         -- scl_oe
		);
	end component audioProcessor;

	u0 : component audioProcessor
		port map (
			bass_stage_switch_export   => CONNECTED_TO_bass_stage_switch_export,   --   bass_stage_switch.export
			clk_clk                    => CONNECTED_TO_clk_clk,                    --                 clk.clk
			green_leds_export          => CONNECTED_TO_green_leds_export,          --          green_leds.export
			mute_button_export         => CONNECTED_TO_mute_button_export,         --         mute_button.export
			red_leds_export            => CONNECTED_TO_red_leds_export,            --            red_leds.export
			treble_stage_switch_export => CONNECTED_TO_treble_stage_switch_export, -- treble_stage_switch.export
			volume_down_button_export  => CONNECTED_TO_volume_down_button_export,  --  volume_down_button.export
			volume_up_button_export    => CONNECTED_TO_volume_up_button_export,    --    volume_up_button.export
			i2c_master_serial_sda_in   => CONNECTED_TO_i2c_master_serial_sda_in,   --   i2c_master_serial.sda_in
			i2c_master_serial_scl_in   => CONNECTED_TO_i2c_master_serial_scl_in,   --                    .scl_in
			i2c_master_serial_sda_oe   => CONNECTED_TO_i2c_master_serial_sda_oe,   --                    .sda_oe
			i2c_master_serial_scl_oe   => CONNECTED_TO_i2c_master_serial_scl_oe    --                    .scl_oe
		);

