LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- D Flip-Flop component
ENTITY my_dff IS
    PORT(clk, rst, d: IN std_logic;
         q: OUT std_logic);
END my_dff;

ARCHITECTURE beh OF my_dff IS
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '0' THEN
            q <= '0';
        ELSIF rising_edge(clk) THEN
            q <= d;
        END IF;
    END PROCESS;
END beh;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY audioProcessor IS
    PORT(clk, rst, volumeUpButton, volumeDownButton, muteButton : IN std_logic;
			bassStageSwitch, trebleStageSwitch : IN std_logic_vector(1 DOWNTO 0);
			vol_up_out, vol_down_out : OUT std_logic;		-- NEW PORTS
         greenLEDs : OUT std_logic_vector(7 DOWNTO 0);
			redLEDs : OUT std_logic_vector(17 DOWNTO 0);
			is_muted : OUT std_logic);
END audioProcessor;

ARCHITECTURE struct OF audioProcessor IS  
   -- Button synchronization and edge detection
   SIGNAL vol_up_btn_sync1, vol_up_btn_sync2, vol_up_btn_prev, vol_up_btn_edge, data_in : std_logic;
	SIGNAL vol_down_btn_sync1, vol_down_btn_sync2, vol_down_btn_prev, vol_down_btn_edge : std_logic;
   SIGNAL mute_btn_sync1, mute_btn_sync2, mute_btn_prev, mute_btn_edge : std_logic;
	SIGNAL rst_sync1, rst_sync2 : std_logic;
   -- Shift register internal signals
   SIGNAL led_registers : std_logic_vector(25 DOWNTO 0) := "000000000000000000" & "01101101";
   SIGNAL shift_up_clk : std_logic;
	SIGNAL shift_down_clk : std_logic;
	SIGNAL mute_state : std_logic;
	
	SIGNAL vol_up_stretch_count : integer range 0 to 5000 := 0;
	SIGNAL vol_down_stretch_count : integer range 0 to 5000 := 0;
   
BEGIN 
	PROCESS(clk)
   BEGIN		
      IF rising_edge(clk) THEN
         rst_sync1 <= rst;
			rst_sync2 <= rst_sync1;
      END IF;
   END PROCESS;
	
   -- 1. VOLUME UP BUTTON DEBOUNCE/SYNCHRONIZATION (synchronize to system clock)
   PROCESS(clk, rst_sync2)
   BEGIN
      IF rst_sync2 = '0' THEN
         vol_up_btn_sync1 <= '1';
         vol_up_btn_sync2 <= '1';
         vol_up_btn_prev <= '1';
      ELSIF rising_edge(clk) THEN
         vol_up_btn_sync1 <= volumeUpButton;       -- First sync stage
         vol_up_btn_sync2 <= vol_up_btn_sync1;    -- Second sync stage
         vol_up_btn_prev <= vol_up_btn_sync2;     -- Previous value for edge detect
      END IF;
   END PROCESS;
	
	-- 2. VOLUME DOWN BUTTON DEBOUNCE/SYNCHRONIZATION (synchronize to system clock)
   PROCESS(clk, rst_sync2)
   BEGIN
      IF rst_sync2 = '0' THEN
         vol_down_btn_sync1 <= '1';
         vol_down_btn_sync2 <= '1';
         vol_down_btn_prev <= '1';
      ELSIF rising_edge(clk) THEN
         vol_down_btn_sync1 <= volumeDownButton;       -- First sync stage
         voL_down_btn_sync2 <= vol_down_btn_sync1;    -- Second sync stage
         vol_down_btn_prev <= vol_down_btn_sync2;     -- Previous value for edge detect
      END IF;
   END PROCESS;
	
	-- 3. MUTE BUTTON DEBOUNCE/SYNCHRONIZATION (synchronize to system clock)
   PROCESS(clk, rst_sync2)
   BEGIN
      IF rst_sync2 = '0' THEN
         mute_btn_sync1 <= '1';
         mute_btn_sync2 <= '1';
         mute_btn_prev <= '1';
      ELSIF rising_edge(clk) THEN
         mute_btn_sync1 <= muteButton;       -- First sync stage
         mute_btn_sync2 <= mute_btn_sync1;    -- Second sync stage
         mute_btn_prev <= mute_btn_sync2;     -- Previous value for edge detect
      END IF;
   END PROCESS;
   
   -- 4. VOLUME UP BUTTON EDGE DETECTION (falling edge = volume up button press)
   vol_up_btn_edge <= vol_up_btn_prev AND NOT vol_up_btn_sync2;  -- Pulse on falling edge
	
	-- 5. VOLUME DOWN BUTTON EDGE DETECTION (falling edge = volume down button press)
	vol_down_btn_edge <= vol_down_btn_prev AND NOT vol_down_btn_sync2;  -- Pulse on falling edge
	
	-- 6. MUTE BUTTON EDGE DETECTION (falling edge = mute button press)
	mute_btn_edge <= mute_btn_prev AND NOT mute_btn_sync2;  -- Pulse on falling edge
   
   -- 7. USE VOLUME UP BUTTON EDGE AS SHIFT UP CLOCK
   -- Option A: Direct button edge (single pulse per press)
   --shift_up_clk <= vol_up_btn_edge;
	
	-- 8. USE VOLUME DOWN BUTTON AS SHIFT DOWN CLOCK
	-- Option A: Direct button edge (single pulse per press)
	--shift_down_clk <= vol_down_btn_edge;
	
	PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF rst_sync2 = '0' THEN
				shift_up_clk <= clk;
			ELSE
				data_in <= '1';
				shift_up_clk <= vol_up_btn_edge;
			END IF;
		END IF;
	END PROCESS;
	
	-- BIDIRECTIONAL SHIFT REGISTER
	PROCESS(clk, rst_sync2)
	BEGIN
		IF rst_sync2 = '0' THEN
			-- On reset, turn all 26 LEDs off
--			led_registers <= (OTHERS => '0');
			led_registers <= "00000000000000000011111111";
			mute_state <= '0';
		ELSIF rising_edge(clk) THEN
			-- Check mute button
			IF mute_btn_edge = '1' THEN
				mute_state <= NOT mute_state;
			-- SHIFT UP (Turn on iteratively)
			ELSIF vol_up_btn_edge = '1' THEN
				-- Volume up button can also unmute
				mute_state <= '0';
				-- Shift everything left by 1, and insert a '1' at the beginning
				led_registers <= led_registers(24 DOWNTO 0) & '1';
			-- SHIFT DOWN (Turn off iteratively)
			ELSIF vol_down_btn_edge = '1' THEN
				-- Volume down button can also unmute
				mute_state <= '0';
				-- Shift everything right by 1, and insert '0' at the end
				led_registers <= '0' & led_registers(25 DOWNTO 1);
			END IF;
		END IF;
	END PROCESS;
	
	PROCESS(clk, rst)
	BEGIN
		if rst = '0' then
			vol_up_stretch_count <= 0;
			vol_up_out <= '0';
		elsif rising_edge(clk) then
			-- Detect the 1-cycle edge and start the timer
			-- UP Stretcher
			if vol_up_btn_edge = '1' then
				vol_up_stretch_count <= 5000;	-- ~100 microseconds
			elsif vol_up_stretch_count > 0 then
				vol_up_stretch_count <= vol_up_stretch_count - 1;
				vol_up_out <= '1';	-- Stay high while counting down
			else
				vol_up_out <= '0';
			end if;
			--DOWN Stretcher
			if vol_down_btn_edge = '1' then 
				vol_down_stretch_count <= 5000;
			elsif vol_down_stretch_count > 0 then
				vol_down_stretch_count <= vol_down_stretch_count - 1;
				vol_down_out <= '1';
			else
				vol_down_out <= '0';
			end if;
		end if;
	end process;
	
	-- 5. Volume Control
--	vol_up_out <= vol_up_btn_edge;
--	vol_down_out <= vol_down_btn_edge;
   
   -- 6. OUTPUT to LEDs
   greenLEDs <= (OTHERS => '0') WHEN mute_state = '1' ELSE led_registers(7 DOWNTO 0);
	redLEDs <= (OTHERS => '0') WHEN mute_state = '1' ELSE led_registers(25 DOWNTO 8);
	is_muted <= mute_state;			-- Pass internal toggle to the controller
   
END struct;