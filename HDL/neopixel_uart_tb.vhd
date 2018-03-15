--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:24:28 04/24/2017
-- Design Name:   
-- Module Name:   C:/Users/Willi/OneDrive/DinoLight/testProject/newNeoPixelTest/neopixel_uart_tb.vhd
-- Project Name:  newNeoPixelTest
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: neopixel_top_wrapper
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY neopixel_uart_tb IS
END neopixel_uart_tb;
 
ARCHITECTURE behavior OF neopixel_uart_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT neopixel_top_wrapper
	 generic( clocks_per_bit : positive := 435);
    PORT(
         clk : IN  std_logic;
         portA0 : OUT  std_logic;
         portA2 : OUT  std_logic;
         portA6 : IN  std_logic;
         portA8 : OUT  std_logic;
         leds : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    
	 component UART_RX is
  generic (
    g_CLKS_PER_BIT : integer := 87 -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end component;
 

   --Inputs
   signal clk : std_logic := '0';
   signal portA6 : std_logic := '1';

 	--Outputs
   signal portA0 : std_logic;
   signal portA2 : std_logic;
   signal portA8 : std_logic;
   signal leds : std_logic_vector(7 downto 0);

   -- Clock period definitions
	-- set Baud  115200
   constant clk_period : time := 20 ns;
	constant num_blocks : natural := 12;
	
constant c_CLKS_PER_BIT : integer := 434;
constant c_BIT_PERIOD : time := 8680 ns;
  
	-- Low-level byte-write
  procedure UART_WRITE_BYTE (
    i_data_in       : in  std_logic_vector(7 downto 0);
    signal o_serial : out std_logic) is
  begin
 
    -- Send Start Bit
    o_serial <= '0';
    wait for c_BIT_PERIOD;
 
    -- Send Data Byte
    for ii in 0 to 7 loop
      o_serial <= i_data_in(ii);
      wait for c_BIT_PERIOD;
    end loop;  -- ii
 
    -- Send Stop Bit
    o_serial <= '1';
    wait for c_BIT_PERIOD;
  end UART_WRITE_BYTE;
  
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: neopixel_top_wrapper 
		generic map(clocks_per_bit =>   c_CLKS_PER_BIT)
		PORT MAP (
          clk => clk,
          portA0 => portA0,
          portA2 => portA2,
          portA6 => portA6,
          portA8 => portA8,
          leds => leds
        );
		  
	uut2: uart_rx
		generic map(    g_CLKS_PER_BIT => c_CLKS_PER_BIT)
		port map(
		i_Clk       => clk,
		i_RX_Serial => portA6
	);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		portA6 <= '1';
      wait for clk_period*10;
		uart_write_byte(x"01", portA6);
		wait until rising_edge(clk);
		for i in 0 to num_blocks - 1 loop
			uart_write_byte(x"03", portA6);
			wait until rising_edge(clk);
		end loop;
		uart_write_byte(x"02", portA6);
		wait until rising_edge(clk);
		for i in 0 to num_blocks * 3 -1 loop
			uart_write_byte(x"FF", portA6);
			wait until rising_edge(clk);
		end loop;
      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
