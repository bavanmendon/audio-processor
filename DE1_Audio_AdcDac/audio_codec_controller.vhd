-- DE1 audio codec controller
-- This module is for controlling the codec via i2c
-- This module is executed by the top-level only once
-- References:  
-- 1.  DE1 User's manual
-- 2.  DE1 Reference design(s) (specifically, DE1_Default on DE1 CD)
-- 2.  Audio codec datasheet  
-- Bharathwaj Muthuswamy
-- EECS 3921 Fall 2010
-- muthuswamy@msoe.edu

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_codec_controller is port(
	reset : in std_logic;
	clock : in std_logic;
	vol_up : in std_logic;					-- From volumeControl
	vol_down : in std_logic;				-- From volumeControl
	scl : out std_logic;
	sda : inout std_logic;
	stateOut : out integer range 0 to 7;
	vol_out : out std_logic_vector(6 DOWNTO 0);
	is_muted : in std_logic);
end audio_codec_controller;

architecture behavioral of audio_codec_controller is
--	component i2c_controller is port
--	(
--		clock : in std_logic;
--		i2c_scl : out std_logic;
--		i2c_sda : inout std_logic;
--		-- the input data to the i2c bus is given by the bus below
--		-- we will shift out data from the bus (BIG-ENDIAN, MSb first)
--		i2c_data : in std_logic_vector(23 downto 0); 
--		reset : in std_logic; -- active low reset
--		start : in std_logic;
--		done : out std_logic;
--		readWriteEnable : in std_logic;
--		acknowledge : out std_logic);
--	end component;

	component I2C_Controller is port
    (
        CLOCK      : in std_logic;
        I2C_SCLK   : out std_logic;
        I2C_SDAT   : inout std_logic;
        -- The input data to the i2c bus (BIG-ENDIAN, MSb first)
        I2C_DATA   : in std_logic_vector(23 downto 0); 
        RESET      : in std_logic; -- active low reset
        GO         : in std_logic;
        I2C_END    : out std_logic;
        W_R        : in std_logic;
        ACK_O      : out std_logic
    );
    end component;

	signal i2cClock20KHz : std_logic := '0';
	signal i2cClockCounter : integer range 0 to 4095 := 0;
	
	signal i2cControllerData : std_logic_vector(23 downto 0);
	signal i2cRun,done,ack_O : std_logic;	
	
	signal muxSelect : integer range 0 to 15;
	signal incrementMuxSelect : std_logic := '0';
		
	signal i2cData : std_logic_vector(15 downto 0) := X"0000";
	type states is (resetState,transmit,checkAcknowledge,turnOffi2cControl,incrementMuxSelectBits,stop);
	signal currentState,nextState : states;
	
	signal vol_level : unsigned(6 DOWNTO 0) := "1101101"; 	-- Default 0dB (0x6D) 30%
	signal vol_up_reg_fast, vol_down_reg_fast : std_logic := '0';
	signal vol_up_reg_slow, vol_down_reg_slow : std_logic := '0';
	signal effective_vol : std_logic_vector(6 DOWNTO 0);
	signal is_muted_reg : std_logic := '0';
		
begin
		-- 20 KHz i2c clock (Mike: you are correct, i2c clock can go down to 10 KHz :D).
		process(clock,reset)
		begin
			if reset = '0' then
				i2cClockCounter <= 0;
				i2cClock20KHz <= '0';
			else
				if clock'event and clock = '1' then
						if i2cClockCounter <= 1249 then
							i2cClock20KHz <= '0';
							i2cClockCounter <= i2cClockCounter + 1;
						elsif i2cClockCounter >= 1250 and i2cClockCounter < 2499 then
							i2cClock20KHz <= '1';
							i2cClockCounter <= i2cClockCounter + 1;
						else
							i2cClockCounter <= 0;
							i2cClock20KHz <= '0';
						end if;
				end if;
			end if;
		end process;
		
--		-- mini FSM to send out right data to audio codec via i2c
--		process(i2cClock20KHz)
--		begin
--			if i2cClock20KHz'event and i2cClock20Khz = '1' then
--				currentState <= nextState;
--			end if;
--		end process;

		-- mini FSM to send out right data to audio codec via i2c
		process(i2cClock20KHz, reset)
		begin
			 if reset = '0' then
				  currentState <= resetState;
				  vol_up_reg_slow <= '0';
				  vol_down_reg_slow <= '0';
				  is_muted_reg <= '0';
			 elsif rising_edge(i2cClock20KHz) then
				  currentState <= nextState;
				  -- UPDATE SLOW CLOCK REGISTERS HERE
				  vol_up_reg_slow <= vol_up;
				  vol_down_reg_slow <= vol_down;
				  is_muted_reg <= is_muted;	-- Capture the current mute status
			 end if;
		end process;
				
		process(currentState,reset,muxSelect,done,ack_O, vol_up, vol_down, vol_up_reg_slow, vol_down_reg_slow)
		begin
			case currentState is
				when resetState =>										
					if reset = '0' then
						nextState <= resetState;
--						muxSelect <= 0;		-- Reset counter on hard reset
--					elsif vol_up = '1' or vol_down = '1' then
--						muxSelect <= 3; 		-- Start loop-back at Volume Left register
--						nextState <= transmit;
					else
						nextState <= transmit;
					end if;
					incrementMuxSelect <= '0';
					i2cRun <= '0';
					 
				when transmit =>
					if muxSelect > 10 then					
						i2cRun <= '0';
						nextState <= stop;	
					else
						i2cRun <= '1';
						nextState <= checkAcknowledge;
					end if;		
					incrementMuxSelect <= '0';
					 
				when checkAcknowledge =>					
					if done = '1' then
						if ack_O = '0' then -- all the ACKs from codec better be low
							i2cRun <= '0';
							nextState <= turnOffi2cControl;
						else
							i2cRun <= '0';
							nextState <= transmit;
						end if;
					else					
						nextState <= checkAcknowledge;
					end if;					
					i2cRun <= '1';
					incrementMuxSelect <= '0';
					
				when turnOffi2cControl =>
					incrementMuxSelect <= '0';
					nextState <= incrementMuxSelectBits; 
					i2cRun <= '0';
 
				when incrementMuxSelectBits =>
					incrementMuxSelect <= '1';
					nextState <= transmit; 
					i2cRun <= '0';
 
				when stop =>
					if (vol_up = '1' and vol_up_reg_slow = '0') or (vol_down = '1' and vol_down_reg_slow = '0') or (is_muted /= is_muted_reg) then
						nextState <= resetState;		-- Use resetState as a jumping point
					else
						nextState <= stop; -- don't need an others clause since all states have been accounted for
					end if;
					i2cRun <= '0';
					incrementMuxSelect <= '0';					
 
			end case;
		end process;
		
		process(clock,reset)
		begin
			if reset = '0' then
				vol_level <= "1101101"; 	-- Default 0x6D (0dB)
				vol_up_reg_fast <= '0';
				vol_down_reg_fast <= '0';
			elsif rising_edge(clock) then
				-- Store current values to detect edges in the next cycle
				vol_up_reg_fast <= vol_up;
				vol_down_reg_fast <= vol_down;
				
				-- Only increment on the rising edge (when it goes from 0 to 1)
				if vol_up = '1' and vol_up_reg_fast = '0' then
					if vol_level < "1111111" then 	-- Max 0x7F (+6dB)
						vol_level <= vol_level + 1;
					end if;
				elsif vol_down = '1' and vol_down_reg_fast = '0' then
					if vol_level > "1100101" then 	-- Min 0x30 "0110000" (-73dB)			now 0x65 "1100101"	
						vol_level <= vol_level - 1;
					end if;
				end if;
			end if;
		end process;
		
--		process(incrementMuxSelect,reset)
--		begin
--			if reset = '0' then
--				muxSelect <= 0;
--			else
--				if incrementMuxSelect'event and incrementMuxSelect='1' then
--					muxSelect <= muxSelect + 1;
--				end if;				
--			end if;
--		end process;
		
		process(i2cClock20KHz, reset)
		begin
			if reset = '0' then
				muxSelect <= 0;
			elsif rising_edge(i2cClock20KHz) then
				-- Handle jumping to specific registers during button press
				if currentState = resetState then
					if vol_up = '1' or vol_down = '1' then
						muxSelect <= 3;	-- Jump to volume registers
					else
						muxSelect <= 0; 	-- Initial start
					end if;
				-- Handle standard incrementing during transmission
				elsif currentState = incrementMuxSelectBits then
					muxSelect <= muxSelect + 1;
				end if;
			end if;
		end process;
		
		effective_vol <= "0110000" when (is_muted = '1' or vol_level <= "1100101") else std_logic_vector(vol_level);
		
		-- 0x34 is the base address of your device
		-- Refer to page 43 of the audio codec datasheet and the schematic
		-- on p. 38 of DE1 User's manual.  CSB is tied to ground so the 8-bit base address is
		-- b00110100 = 0x34.  		
		i2cControllerData <= X"34"&i2cData; 		
		-- data to be sent to audio code obtained via a MUX
		-- the select bits for the MUX are obtained by the mini FSM above
		-- the 16-bit value for each setting can be found
		-- in table 29 and 30 on pp. 46-50 of the audio codec datasheet (on the DE1 system CD)
		with muxSelect select
			i2cData <= X"0000" when 0, -- dummy data
						  X"001F" when 1, -- Left input volume is maximum
						  X"021F" when 2, -- Right input volume is maximum
						  "0000010" & '1' & '0' & effective_vol when 3, -- Left output volume is high			-- #change 0479	max 047F		X"0479" when 3
						  "0000011" & '1' & '0' & effective_vol when 4, -- Right output volume is high		-- #change 0679	max 067F		X"0679" when 4
						  X"0810" when 5, -- No sidetone, DAC: on, disable mic, line input to ADC: on
						  X"0A06" when 6, -- deemphasis to 48 KHz, enable high pass filter on ADC
						  X"0C00" when 7, -- no power down mode
						  X"0E01" when 8, -- MSB first, left-justified, slave mode		-- #change 0E01 - left justified	0E02 - I2S format, left-1 justified
						  X"1002" when 9, -- 384 fs oversampling
						  X"1201" when 10, -- activate
						  X"ABCD" when others; -- should never occur
		
						
		
		-- instantiate i2c controller
--		i2cController : i2c_controller port map (i2cClock20KHz,scl,sda,i2cControllerData,reset,i2cRun,done,'0',ack_O);

		-- instantiate i2c controller using named association
		i2cController : I2C_Controller port map (
			CLOCK    => i2cClock20KHz,
			I2C_SCLK => scl,
			I2C_SDAT => sda,
			I2C_DATA => i2cControllerData,
			RESET    => reset,
			GO       => i2cRun,
			I2C_END  => done,
			W_R      => '0',   -- Set to 0 for write mode
			ACK_O    => ack_O
		);
		
		-- User I/O
		with currentState select
			stateOut <= 0 when resetState,
						   1 when transmit,
							2 when checkAcknowledge,
							3 when turnOffi2cControl,
							4 when incrementMuxSelectBits,
							5 when stop;	
	
		vol_out <= std_logic_vector(vol_level);
		
end behavioral;