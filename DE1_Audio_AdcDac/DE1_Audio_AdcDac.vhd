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
		PORT(clk, rst, volumeUpButton, volumeDownButton, muteButton : IN std_logic;
				bassStageSwitch, trebleStageSwitch : IN std_logic_vector(1 DOWNTO 0);
				vol_up_out, vol_down_out : OUT std_logic;	-- NEW PORTS
				greenLEDs : OUT std_logic_vector(7 DOWNTO 0);
				redLEDs : OUT std_logic_vector(17 DOWNTO 0);
				is_muted : OUT std_logic);
	end component;
	
	component audio_codec_controller is port(
		reset : in std_logic;
		clock : in std_logic;
		vol_up : in std_logic;					-- From audioProcessor
		vol_down : in std_logic;				-- From audioProcessor
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
		dacData : out std_logic) ;
	end component;
	
	signal i2cClock,audioClock,clock50MHz : std_logic := '0';
	signal stateOut : integer range 0 to 7;
	signal resetAdcDac : std_logic := '0';
	
	signal adcLRC,bitClock,adcdat,dacLRC,dacDat : std_logic := '0';
	
	signal heartbeatCounter : unsigned(23 DOWNTO 0) := (OTHERS => '0');
	
	signal current_vol : std_logic_vector(6 downto 0);
	
	signal vol_up_edge, vol_down_edge : std_logic;
	
	signal is_muted_sig : std_logic;
	
begin
	-- clock buffer to avoid clock skews
	clockBuffer50MHz : clockBuffer port map(not SW(0),CLOCK_50,clock50MHz);
	
	audioCodecController : audio_codec_controller port map (SW(0),clock50MHz,vol_up_edge,vol_down_edge,i2cClock,I2C_SDAT,stateOut, current_vol, is_muted_sig);
	-- we only start the audio controller below long (40 ms) after we reset the system
	-- the reason is that transmitting all the i2c data takes at least 19 ms (20 KHz clock)
	adcDacControllerStartDelay : delayCounter port map (SW(0),clock50MHz,resetAdcDac);
	
	
	-- we will use a PLL to generate the necessary 18.432 MHz Audio Control clock
	audioPllClockGen : audioPLL port map (not resetAdcDac,CLOCK_50,audioClock);		-- #change CLOCK_27(0)
	
	adcDacController : adc_dac_controller port map (resetAdcDac,SW(8),SW(9),audioClock,bitClock,adcLRC,AUD_DACLRCK,adcDat,dacDat);
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
				  
	buttonLogic: audioProcessor port map (
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

