--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:17:41 04/24/2017
-- Design Name:   
-- Module Name:   C:/Users/Willi/OneDrive/DinoLight/testProject/newNeoPixelTest/uart_rx_tb.vhd
-- Project Name:  newNeoPixelTest
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: uart_rx_controller
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
 
ENTITY uart_rx_tb IS
END uart_rx_tb;
 
ARCHITECTURE behavior OF uart_rx_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT uart_rx_controller
    PORT(
         clk : IN  std_logic;
         reset_in : IN  std_logic;
         data_in : IN  std_logic_vector(7 downto 0);
         data_valid : IN  std_logic;
         mode : OUT  std_logic_vector(1 downto 0);
         mode_value_change : OUT  std_logic;
         custom_block_values : OUT  std_logic_vector(0 to 719);
         block_counts : OUT  std_logic_vector(0 to 239);
         custom_block_change : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset_in : std_logic := '0';
   signal data_in : std_logic_vector(7 downto 0) := (others => '0');
   signal data_valid : std_logic := '0';

 	--Outputs
   signal mode : std_logic_vector(1 downto 0);
   signal mode_value_change : std_logic;
   signal custom_block_values : std_logic_vector(0 to 719);
   signal block_counts : std_logic_vector(0 to 239);
   signal custom_block_change : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: uart_rx_controller PORT MAP (
          clk => clk,
          reset_in => reset_in,
          data_in => data_in,
          data_valid => data_valid,
          mode => mode,
          mode_value_change => mode_value_change,
          custom_block_values => custom_block_values,
          block_counts => block_counts,
          custom_block_change => custom_block_change
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
      wait for 100 ns;	
		data_valid <= '1';
		data_in <= x"02";
		
		wait until rising_edge(clk);

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
