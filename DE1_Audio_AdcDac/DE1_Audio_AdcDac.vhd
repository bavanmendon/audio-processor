-- DE1 ADC DAC interface
-- top-level module
-- References:  
-- 1.  DE1 User's manual
-- 2.  DE1 Reference Designs (specifically, DE1_Default)
-- 3.  Digital Differential Analyzer: http://courses.cit.cornell.edu/ece576/DDA/index.htm
-- Bharathwaj Muthuswamy
-- EECS 3921 Fall 2010
-- muthuswamy@msoe.edu

-- This design is a VHDL interface to the audio codec on the DE1 board
-- Placing SW(0) in the UP position runs the design
-- SW(9) is down means a sine wave (if SW(8) is down) of 1 KHz is output on line out 
-- SW(9) is down but SW(8) is up means a square wave of 1 KHz is output on line out
-- (sine wave and square wave ROM are inside adc_dac_controller module below)
-- SW(9) in up position is ADC to DAC loopback
-- The codec is configured for 16-bit 48 KHz sampling frequency.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE1_Audio_AdcDac is port
	(
		CLOCK_50 : in std_logic;
		CLOCK_27 : in std_logic_vector(1 downto 0);
		KEY : in std_logic_vector(3 downto 0);
		SW : in std_logic_vector(9 downto 0);
		AUD_ADCLRCK : out std_logic;
		AUD_ADCDAT : in std_logic;
		AUD_DACLRCK : out std_logic;
		AUD_DACDAT : out std_logic;
		AUD_XCK : out std_logic;
		AUD_BCLK : out std_logic;
		I2C_SCLK : out std_logic; -- master (our module) drives i2c clock
		I2C_SDAT : inout std_logic;
		GPIO_1 : inout std_logic_vector(35 downto 0);
		HEX0,HEX1,HEX2,HEX3 : out std_logic_vector(6 downto 0);
		LEDR : out std_logic_vector(17 DOWNTO 0);
		LEDG : out std_logic_vector(7 DOWNTO 0));
end DE1_Audio_AdcDac;
	
architecture topLevel of DE1_Audio_AdcDac is

	component audioProcessor is
		port (
--			audio_config_external_SDAT  : inout std_logic                     := 'X';             
--			audio_config_external_SCLK  : out   std_logic;                                        
--			audio_core_external_ADCDAT  : in    std_logic                     := 'X';             
--			audio_core_external_ADCLRCK : in    std_logic                     := 'X';             
--			audio_core_external_BCLK    : in    std_logic                     := 'X';             
--			audio_core_external_DACDAT  : out   std_logic;                                        
--			audio_core_external_DACLRCK : in    std_logic                     := 'X';             
			bass_stage_switch_export    : in    std_logic_vector(1 downto 0)  := (others => 'X'); 
			clk_clk                     : in    std_logic                     := 'X';             
			green_leds_export           : out   std_logic_vector(7 downto 0);                     
--			i2c_master_serial_sda_in    : in    std_logic                     := 'X';             
--			i2c_master_serial_scl_in    : in    std_logic                     := 'X';             
--			i2c_master_serial_sda_oe    : out   std_logic;                                        
--			i2c_master_serial_scl_oe    : out   std_logic;                                        
			mute_button_export          : in    std_logic                     := 'X';             
			red_leds_export             : out   std_logic_vector(17 downto 0);                    
			reset_reset_n               : in    std_logic                     := 'X'; -- YOUR NEW RESET 
			treble_stage_switch_export  : in    std_logic_vector(1 downto 0)  := (others => 'X'); 
			volume_down_button_export   : in    std_logic                     := 'X';             
			volume_up_button_export     : in    std_logic                     := 'X';
			nios_data_ready_external_connection_export : in    std_logic                     := 'X';             -- export
			nios_in_left_external_connection_export   : in    std_logic_vector(15 downto 0) := (others => 'X'); -- export
			nios_in_right_external_connection_export  : in    std_logic_vector(15 downto 0) := (others => 'X'); -- export
			nios_out_left_external_connection_export  : out   std_logic_vector(15 downto 0);                    -- export
			nios_out_right_external_connection_export : out   std_logic_vector(15 downto 0)                     -- export
		);
	end component audioProcessor;

	component volumeControl is
		PORT(clk, rst, volumeUpButton, volumeDownButton, muteButton : IN std_logic;    -- clk, rst #changed
				bassStageSwitch, trebleStageSwitch : IN std_logic_vector(1 DOWNTO 0);
				vol_up_out, vol_down_out : OUT std_logic;	-- NEW PORTS
				greenLEDs : OUT std_logic_vector(7 DOWNTO 0);
				redLEDs : OUT std_logic_vector(17 DOWNTO 0);
				is_muted : OUT std_logic);
	end component;
	
	component audio_codec_controller is port(
		reset : in std_logic;
		clock : in std_logic;
		vol_up : in std_logic;					-- From volumeControl
		vol_down : in std_logic;				-- From volumeControl
		scl : out std_logic;
		sda : inout std_logic;
		stateOut : out integer range 0 to 7;
		vol_out : out std_logic_vector(6 DOWNTO 0);
		is_muted : in std_logic);
	end component;
	
	component delayCounter is port (
		reset : in std_logic;
		clock : in std_logic;
		resetAdc : out std_logic);
	end component;
	
	component clockBuffer IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC );
	END component;
	
	component audioPLL IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC);
	END component;

	component adc_dac_controller is port (
		reset : in std_logic;
		waveSelect : in std_logic; -- connected to SW(8), default (down) means sine, else square
		dataSelect : in std_logic; -- connected to SW(9), default (down) means sine on lineout.  up is ADC-DAC loopback
		audioClock : in std_logic; -- 18.432 MHz sample clock
		bitClock : out std_logic;
		adcLRSelect : out std_logic;
		dacLRSelect : out std_logic;
		adcData : in std_logic;
		dacData : out std_logic;
		
		-- NIOS Bridge Ports
		audio_to_nios_left : out std_logic_vector(15 downto 0);
		audio_to_nios_right : out std_logic_vector(15 downto 0);
		audio_from_nios_left : in std_logic_vector(15 downto 0);
		audio_from_nios_right : in std_logic_vector(15 downto 0);
		data_ready_flag : out std_logic
		);
	end component;
	
	signal i2cClock,audioClock,clock50MHz : std_logic := '0';
	signal stateOut : integer range 0 to 7;
	signal resetAdcDac : std_logic := '0';
	
	signal adcLRC,bitClock,adcdat,dacLRC,dacDat : std_logic := '0';
	
	signal heartbeatCounter : unsigned(23 DOWNTO 0) := (OTHERS => '0');
	
	signal current_vol : std_logic_vector(6 downto 0);
	signal vol_up_edge, vol_down_edge : std_logic;	
	signal is_muted_sig : std_logic;
	
	signal nios_audio_in_left : std_logic_vector(15 downto 0);
	signal nios_audio_in_right : std_logic_vector(15 downto 0);
	signal nios_audio_out_left : std_logic_vector(15 downto 0);
	signal nios_audio_out_right : std_logic_vector(15 downto 0);
	signal nios_data_ready : std_logic;
	
begin
	-- clock buffer to avoid clock skews
	clockBuffer50MHz : clockBuffer port map(not SW(0),CLOCK_50,clock50MHz);		-- #change not sw(0)	'0'
	
	audioCodecController : audio_codec_controller port map (SW(0),clock50MHz,vol_up_edge,vol_down_edge,i2cClock,I2C_SDAT,stateOut, current_vol, is_muted_sig);	-- #change sw(0)
	-- we only start the audio controller below long (40 ms) after we reset the system
	-- the reason is that transmitting all the i2c data takes at least 19 ms (20 KHz clock)
	adcDacControllerStartDelay : delayCounter port map (SW(0),clock50MHz,resetAdcDac);			-- #change sw(0)	'1'
	
	
	-- we will use a PLL to generate the necessary 18.432 MHz Audio Control clock
	audioPllClockGen : audioPLL port map (not resetAdcDac,CLOCK_50,audioClock);		-- #change CLOCK_27(0)	'1'
	
	adcDacController : adc_dac_controller port map (resetAdcDac,SW(8),SW(9),audioClock,bitClock,adcLRC,AUD_DACLRCK,adcDat,dacDat,nios_audio_in_left,nios_audio_in_right,nios_audio_out_left,nios_audio_out_right,nios_data_ready);
	-- send out the clocks
	I2C_SCLK <= i2cClock;
	AUD_BCLK <= bitClock;
	AUD_XCK <= audioClock;
	
	-- input from adc
	adcDat <= AUD_ADCDAT;
	
	-- output assignments
	AUD_ADCLRCK <= adcLRC;
	AUD_DACDAT <= dacDat;
	 
	-- debug connections to GPIO 1.
	-- You **should** use an external logic analyzer (or SignalTap)
	-- to understand timing in this design.  I use an external
	-- logic analyzer because it is so much quicker and I have only
	-- 7 signals to look at.
	GPIO_1(0) <= i2cClock;
	GPIO_1(1) <= I2C_SDAT;
	GPIO_1(3) <= audioClock; 
	GPIO_1(5) <= adcLRC; 
	GPIO_1(7) <= bitClock; 
	GPIO_1(9) <= dacDat; 
	GPIO_1(11) <= adcDat; 
	
	HEX3 <= "1111111";
--	HEX2 <= "1111111";
--	HEX1 <= "1111111";
	with stateOut select
		HEX0 <= "1000000" when 0, -- resetState
				  "1111100" when 1, -- transmit
				  "0100100" when 2, -- checkAcknowledge
				  "0110000" when 3, -- turnOffi2cControl
				  "0011001" when 4, -- incrementMuxSelectBits
				  "0010010" when 5, -- stop
				  "1111111" when others; -- should not occur
				  
	nios_brain: audioProcessor port map (
		clk_clk                     => CLOCK_50,
		reset_reset_n               => SW(0), -- Wakes up the CPU!
		
		-- UI Connections
		volume_up_button_export     => KEY(3),
		volume_down_button_export   => KEY(2),
		mute_button_export          => KEY(1),
		bass_stage_switch_export    => SW(2 DOWNTO 1),
		treble_stage_switch_export  => SW(4 DOWNTO 3),
		green_leds_export           => open,
		red_leds_export             => open, -- Let your VHDL volumeControl handle Red LEDs
		
		-- Safely tying off the Qsys Audio/I2C so it doesn't fight your VHDL
--		audio_config_external_SDAT  => open,
--		audio_config_external_SCLK  => open,
--		audio_core_external_ADCDAT  => AUD_ADCDAT,
--		audio_core_external_ADCLRCK => AUD_ADCLRCK,
--		audio_core_external_BCLK    => AUD_BCLK,
--		audio_core_external_DACDAT  => AUD_DACDAT,
--		audio_core_external_DACLRCK => AUD_DACLRCK,
		
		nios_data_ready_external_connection_export => nios_data_ready,
		nios_in_left_external_connection_export => nios_audio_in_left,
		nios_in_right_external_connection_export => nios_audio_in_right,
		nios_out_left_external_connection_export => nios_audio_out_left,
		nios_out_right_external_connection_export => nios_audio_out_right
--		i2c_master_serial_sda_in    => '0',
--		i2c_master_serial_scl_in    => '0',
--		i2c_master_serial_sda_oe    => open,
--		i2c_master_serial_scl_oe    => open
	);
				  
	buttonLogic: volumeControl port map (
				clk => clock50MHz,
				rst => SW(0),
				volumeUpButton => KEY(3),
				volumeDownButton => KEY(2),
				muteButton => KEY(1),
				bassStageSwitch => SW(2 DOWNTO 1),
				trebleStageSwitch => SW(4 DOWNTO 3),
				vol_up_out => vol_up_edge,					-- Connect to internal signal
				vol_down_out => vol_down_edge,			-- Connect to internal signal
				greenLEDs => LEDG,
				redLEDs => LEDR,
				is_muted => is_muted_sig
	);
	
--	process(audioClock)
--	begin
--		if rising_edge(audioClock) then
--			heartbeatCounter <= heartbeatCounter + 1;
--		end if;
--	end process;
--	
--	LEDG(0) <= heartbeatCounter(22);

	-- HEX1: Displays the lower 4 bits of the volume (Hex Digit 0)
	process(current_vol) -- Sensitive to volume changes
	begin
		if is_muted_sig = '1' or current_vol <= "1100101" then -- If at Min (0x65)
			HEX1 <= "1000000"; -- Display '0'
		else
			case current_vol(3 downto 0) is
				when "0000" => HEX1 <= "1000000"; -- 0
				when "0001" => HEX1 <= "1111001"; -- 1
				when "0010" => HEX1 <= "0100100"; -- 2
				when "0011" => HEX1 <= "0110000"; -- 3
				when "0100" => HEX1 <= "0011001"; -- 4
				when "0101" => HEX1 <= "0010010"; -- 5
				when "0110" => HEX1 <= "0000010"; -- 6
				when "0111" => HEX1 <= "1111000"; -- 7
				when "1000" => HEX1 <= "0000000"; -- 8
				when "1001" => HEX1 <= "0011000"; -- 9
				when "1010" => HEX1 <= "0001000"; -- A
				when "1011" => HEX1 <= "0000011"; -- b
				when "1100" => HEX1 <= "1000110"; -- C
				when "1101" => HEX1 <= "0100001"; -- d
				when "1110" => HEX1 <= "0000110"; -- E
				when "1111" => HEX1 <= "0000111"; -- F
				when others => HEX1 <= "1111111";
			end case;
		end if;
	end process;

	-- HEX2: Displays the upper 3 bits of the volume (Hex Digit 1)
	process(current_vol)
	begin
		if is_muted_sig = '1' or current_vol <= "1100101" then -- If at Min (0x65)
			HEX2 <= "1000000"; -- Display '0'
		else
			-- Pad the 3 bits to 4 bits for the case statement
			case "0" & current_vol(6 downto 4) is
				when "0000" => HEX2 <= "1000000"; -- 0
				when "0001" => HEX2 <= "1111001"; -- 1
				when "0010" => HEX2 <= "0100100"; -- 2
				when "0011" => HEX2 <= "0110000"; -- 3
				when "0100" => HEX2 <= "0011001"; -- 4
				when "0101" => HEX2 <= "0010010"; -- 5
				when "0110" => HEX2 <= "0000010"; -- 6
				when "0111" => HEX2 <= "1111000"; -- 7
				when others => HEX2 <= "1111111";
			end case;
		end if;
	end process;
end topLevel;

