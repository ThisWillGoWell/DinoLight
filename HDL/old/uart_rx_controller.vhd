----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:38:43 02/14/2017 
-- Design Name: 
-- Module Name:    uart_rx_controller - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_rx_controller is
	Generic(NUM_COMMANDS : natural := 3;
			NUM_LEDS : natural := 30);
	
	Port( clk : in std_logic;
			data_in : in std_logic_vector(7 downto 0);
			data_valid : in std_logic;
			--register output values
			power_reg : out std_logic;
			led_map_regs : out std_Logic_vector(NUM_LEDS * 16 - 1 downto 0);
			
			led_value_regs : out std_logic_vector(NUM_LEDS * 24 - 1 downto 0);
			led_value_change : out std_logic
			);
			
end uart_rx_controller;

architecture Behavioral of uart_rx_controller is
	type state_type is (idle, command, payloadWrite, payloadWait, finish);
	signal state, nextState : state_type := idle;
	signal currentCommand : integer range 0 to NUM_COMMANDS-1 := 0;
	signal currentIndex : integer range 0 to (3 * NUM_LEDS) - 1 := 0;
	
	signal led_value_buffer : std_logic_vector(NUM_LEDS * 24 - 1 downto 0);
	
	type payload_list_type is array(0 to NUM_COMMANDS-1) of natural range 0 to 3 * NUM_LEDS;
	-- Power, led_mapping, led_values
	
	constant payloadSizes : payload_list_type :=(1, 2* NUM_LEDS, 3 * NUM_LEDS);
	
begin

	
	nextStateProcess: process(clk) is
	begin
		if rising_edge(clk) then
			state <= nextState;
		end if;
	end process;
	
	writeRegisters: process(clk) is 
	begin 
		if rising_edge(clk) then				
			if nextState = payloadWrite then
				if currentCommand = 0 then
					power_reg <= data_in(0);
				elsif currentCommand = 1 then
					led_map_regs((currentIndex+1) * 8 -1 downto (currentIndex * 8)) <= data_in;
				elsif currentCommand = 2 then
					led_value_buffer((currentIndex+1) * 8 -1 downto (currentIndex * 8)) <= data_in;
				end if;
			elsif nextState = idle then
				if currentCommand = 2 then
					led_value_regs <= led_value_buffer;
				end if;
			end if;
		end if;
	end process;
	
	processChange: process(clk) is begin
		if rising_edge(clk) then
			led_value_change <= '0';
			if nextState = finish then
				if currentCommand = 2 then
					led_value_change <= '1';
				end if;
			end if;
		end if;
	end process;
	
	nextStateDecode: process(state, data_valid, clk, currentCommand, currentIndex) is 
	begin
		if state = idle then
			if data_valid = '1' then
				nextState <= command;
			else 
				nextState <= state;
			end if;
		elsif state = command then
				nextState <= payloadWait;
		elsif state = payloadWait then
			if data_valid = '1' then
				nextState <= payloadWrite;
			else
				nextState <= state;
			end if;
		elsif state = payloadWrite then
			if payloadSizes(currentCommand) = currentIndex then
				nextState <= finish;
			else
				nextState <= payloadWait;
			end if;
		elsif state = finish then
			nextState <= idle;
		else
			nextState <= idle;
		end if;
		
	end process;
	
	
	setCommand: process(clk) is
	begin
		if rising_edge(clk) then
			if nextState = command then
				currentCommand<= to_integer(unsigned(data_in));
			end if;
		end if;
	end process;

	
	indexCounter: process(clk) is begin
		if rising_edge(clk) then
			if nextState = idle then
				currentIndex <= 0;
			elsif nextState = payloadWrite then
				currentIndex <= currentIndex + 1;
			end if;
		end if;
	end process;
	
end Behavioral;

