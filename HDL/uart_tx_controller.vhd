----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:43:52 02/18/2017 
-- Design Name: 
-- Module Name:    uart_tx_controller - Behavioral 
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

entity uart_tx_controller is
	Generic( clock_cycles_send_period : natural := 10_000_000);
	Port(
			clk						: in std_logic;
			periodic_send_data	: in std_logic_vector(47 downto 0) ;
	
			data_to_uart			: out std_logic_vector(7 downto 0);
			uart_data_ack			: in std_logic;
			uart_data_stb			: out std_logic
			);
			
end uart_tx_controller;

architecture Behavioral of uart_tx_controller is
type state_type is (count_up, send, send_wait, send_next);

signal counter 				: natural range 0 to clock_cycles_send_period;
signal state, next_state 	: state_type;
signal current_send_index 	: natural range 0 to 8;
signal periodic_send_data_reg : std_Logic_vector(47 downto 0);
begin

nextStateTranslate: process(clk) is
begin
	if rising_edge(clk) then
		state <= next_state;
	end if;
end process;


counterProcess: process(clk) is
begin
	if rising_edge(clk) then
		if next_state = count_up then
			counter <= counter + 1;
		else
			counter <= 0;
		end if;
	end if;
end process;


nextStateDecode: process(state, current_send_index, counter, uart_data_ack) is 
begin
	case state is
		when count_up =>
			if counter = clock_cycles_send_period then
				next_state <= send;
			else
				next_state <= count_up;
			end if;
			
		when send =>
			next_state <= send_wait;
			
		when send_wait=>
			if uart_data_ack = '1' then
				next_state <= send_next;
			else
				next_state <= state;
			end if;
			
		when send_next=>
			if current_send_index = 6 then
				next_state <= count_up;
			else
				next_state <= send;
			end if;		
	end case;
end process;



sendProcess: process(clk) is
begin
	if rising_edge(clk) then
		uart_data_stb <= '0';
		if next_state = send then
			data_to_uart <= periodic_send_data_reg(7 downto 0);
			uart_data_stb <= '1';
		end if;
	end if;
end process;

incSendIndex: process(clk) is begin
	if rising_edge(clk) then
		if next_state = send then
			current_send_index <= current_send_index + 1;
			periodic_send_data_reg <= periodic_send_data_reg(7 downto 0) & periodic_send_data_reg(47 downto 8);
		elsif next_state = count_up then
			current_send_index <= 0;
			periodic_send_data_reg <= periodic_send_data;
		end if;
	end if;
end process;
end Behavioral;

