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
    use ieee.math_real.all;

entity uart_rx_controller is
	Generic(num_commands : natural := 3;
			num_blocks : natural := 30
			);
	
	Port( clk 					: in std_logic;
			reset_in 			: in std_logic;
			data_in 				: in std_logic_vector(7 downto 0);
			data_valid 			: in std_logic;
			
			mode				 	: out std_logic_vector(1 downto 0);
			mode_value_change 		: out std_logic;
			
			custom_block_values	: out std_logic_vector(0 to  num_blocks * 24 -1);
			block_counts				: out std_Logic_vector(0 to num_blocks * 8 -1);
			custom_block_change 	: out std_logic
			);
			
end uart_rx_controller;

architecture Behavioral of uart_rx_controller is
	type payload_list_type is array(0 to num_commands-1) of natural range 0 to 3 * num_blocks;
	type state_type is (idle, command, payloadWrite, payloadWait, finish, timeout, reset);
	
	signal state, nextState : state_type := idle;
	
	-- Power, led_mapping, led_value
	constant payloadSizes : payload_list_type :=(1, num_blocks, 3 * num_blocks);
	
	-- registers to hold other state values
	signal currentCommand 	: natural range 0 to num_commands-1 := 0;
	signal currentIndex 		: natural range 0 to (3 * num_blocks) := 0;
	
	--write buffer to write values to.
	signal write_value_shift_in 		: std_logic_vector(num_blocks * 24 - 1 downto 0);	
	signal write_mode					: std_logic_vector(1 downto 0);
	
	function reverse_any_vector (a: in std_logic_vector)
		return std_logic_vector is
		  variable result: std_logic_vector(a'RANGE);
		  alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
		begin
		  for i in aa'RANGE loop
			 result(i) := aa(i);
		  end loop;
		  return result;
		end;

begin
	
	-- State Transistion
	nextStateProcess: process(clk) is
	begin
		if rising_edge(clk) then
			state <= nextState;
			
		end if;
	end process;
	
	--Write buffer
	writeBuffer: process(clk) is 
	begin 
		if rising_edge(clk) then				
			if nextState = reset or nextState = timeout then
					write_value_shift_in <= (others=> '0');
			elsif nextState = payloadWrite then
					write_value_shift_in <= write_value_shift_in( num_blocks * 24 -9 downto 0) & data_in;
			end if;
		end if;
	end process;
	
	-- Buffer to output registers
	bufferToRegister: process(clk) is begin
		if rising_edge(clk) then
			-- defualt values
			custom_block_change <= '0';
			mode_value_change <= '0';
			--if rest clear all registers
			if nextState = reset then
				mode_value_change <= '0';
				custom_block_values <= (others => '0');
				
			elsif nextState = finish then
				case currentCommand is
					when 0=> -- mode 
						mode_value_change <= '1';
						mode		 <= write_value_shift_in(1 downto 0);
					
					when 1=> -- block_count
						block_counts <= write_value_shift_in(num_blocks * 8 -1 downto 0);
					when 2=> -- custom_block_values Value Reg
						custom_block_change <= '1';
						custom_block_values <= write_value_shift_in;	
					when others=>
					
				end case;
			end if;
		end if;
	end process;
	
	-- Next State Decode
	nextStateDecode: process(reset_in, state, data_valid, clk, currentCommand, currentIndex) is 
	begin 
			if reset_in='1' then
				nextState <= reset;
			else				
				case state is	
					when idle =>
						if data_valid = '1' then
							nextState <= command;
						else 
							nextState <= state;
						end if;
						
					when command =>  
							nextState <= payloadWait;
							
					when payloadWait =>  
						if data_valid = '1' then
							nextState <= payloadWrite;
						else
							nextState <= state;
						end if;
						
					when payloadWrite =>
						if payloadSizes(currentCommand) = currentIndex then
							nextState <= finish;
						else
							nextState <= payloadWait;
						end if;
						
					when finish =>  
						nextState <= idle;
						
					when timeout =>
						nextState <= idle;
						
					when others=>
						nextState <= idle;
					
				end case;
			end if;
		end process;
	
	-- set the current Command value
	setCommand: process(clk) is
	begin
		if rising_edge(clk) then
			if nextState = reset then
				currentCommand <= 0;
			elsif nextState = command then
				currentCommand<= to_integer(unsigned(data_in));
			end if;
		end if;
	end process;

	-- Keep track of write location for buffer 
	indexCounter: process(clk) is begin
		if rising_edge(clk) then
			if nextState = idle or nextState = reset then
				currentIndex <= 0;
			elsif nextState = payloadWrite then
				currentIndex <= currentIndex + 1; 
			end if;
		end if;
	end process;
	
	
	
end Behavioral;

