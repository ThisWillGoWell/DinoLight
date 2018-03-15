----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:38:23 07/06/2015 
-- Design Name: 
-- Module Name:    NeoPixelDriver - Behavioral 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity NeoPixelDriver is
    Port ( clk 			: in  STD_LOGIC;
			  data_out		: out std_logic;
			  run				: in  STD_LOGIC;
			  valid_pixel	: in std_logic;
			  last_pixel	: in std_Logic;
			  ack_pixel		: out std_logic;
			  data_in 	: in 	std_logic_vector(0 to 23)
			  );
			  
end NeoPixelDriver;

architecture Behavioral of NeoPixelDriver is
	signal counter 		: std_logic_vector(11 downto 0) := (others=>'0');
	signal curPos 			: natural range 0 to 24;
	signal data_reg		: std_logic_vector(0 to 23) := (others=>'0');
	
	type stateType is (ack, waitForValid, t0H, t1H, finishCycle, res, reset1, reset0, incCount, display, writeState, idle, loadReg);
	
	signal state, nextState : stateType := idle;
	
	-- Cycles for each part of the protocal
	constant t0h_time : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(20,12));
	constant t1h_time : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(40,12));
	constant cycleTime : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(62,12));
	constant tholdtime: std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(2500	,12));
	
	type gamma_lut_type is array ( 0 to 255) of std_logic_vector(7 downto 0);
	constant gamma_lut : gamma_lut_type := (
		X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
		X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
		X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"04",
		X"04", X"04", X"04", X"04", X"05", X"05", X"05", X"05", X"05", X"06", X"06", X"06", X"06", X"06",
		X"07", X"07", X"07", X"08", X"08", X"08", X"08", X"09", X"09", X"09", X"0A", X"0A", X"0A", X"0B",
		X"0B", X"0B", X"0C", X"0C", X"0D", X"0D", X"0D", X"0E", X"0E", X"0F", X"0F", X"0F", X"10", X"10",
		X"11", X"11", X"12", X"12", X"13", X"13", X"14", X"14", X"15", X"15", X"16", X"17", X"17", X"18",
		X"18", X"19", X"19", X"1A", X"1B", X"1B", X"1C", X"1D", X"1D", X"1E", X"1F", X"1F", X"20", X"21",
		X"21", X"22", X"23", X"24", X"24", X"25", X"26", X"27", X"28", X"28", X"29", X"2A", X"2B", X"2C",
		X"2D", X"2D", X"2E", X"2F", X"30", X"31", X"32", X"33", X"34", X"35", X"36", X"37", X"38", X"39",
		X"3A", X"3B", X"3C", X"3D", X"3E", X"3F", X"40", X"41", X"42", X"43", X"44", X"46", X"47", X"48",
		X"49", X"4A", X"4B", X"4D", X"4E", X"4F", X"50", X"51", X"53", X"54", X"55", X"57", X"58", X"59",
		X"5A", X"5C", X"5D", X"5F", X"60", X"61", X"63", X"64", X"66", X"67", X"68", X"6A", X"6B", X"6D",
		X"6E", X"70", X"71", X"73", X"74", X"76", X"78", X"79", X"7B", X"7C", X"7E", X"80", X"81", X"83",
		X"85", X"86", X"88", X"8A", X"8B", X"8D", X"8F", X"91", X"92", X"94", X"96", X"98", X"9A", X"9B",
		X"9D", X"9F", X"A1", X"A3", X"A5", X"A7", X"A9", X"AB", X"AD", X"AF", X"B1", X"B3", X"B5", X"B7",
		X"B9", X"BB", X"BD", X"BF", X"C1", X"C3", X"C5", X"C7", X"CA", X"CC", X"CE", X"D0", X"D2", X"D5",
		X"D7", X"D9", X"DB", X"DE", X"E0", X"E2", X"E4", X"E7", X"E9", X"EC", X"EE", X"F0", X"F3", X"F5",
		X"F8", X"FA", X"FD", X"FF");	
		
	
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
	-- Transistion to the next state
	nextStateTrans: process(clk) is begin
		if rising_edge(clk) then
			state <= nextState;
		end if;
	end process;
	
	--Control the data out poriton 
	outputProcess: process(clk) is begin
		if rising_edge(clk) then
			data_out <= '0';
			if nextState = t0H or nextState = t1H then
				data_out<='1';
			end if;
		end if;
	end process;
	
	-- Processs to load the register before a write and shfit it during writes
	loadShiftProcess: process(clk) is begin
		if rising_edge(clk) then
			if nextState = ack then
				data_reg <= gamma_lut(to_integer(unsigned(data_in(0 to 7)))) & gamma_lut(to_integer(unsigned(data_in(8 to 15)))) & gamma_lut(to_integer(unsigned(data_in(16 to 23))));
			elsif nextState = incCount then
				for i in 0 to 22 loop
					data_reg(i) <= data_reg(i+1);	
				end loop;
			end if;
		end if;
	end process;
	


	-- Next State Decode
	nextStateDecode: process(clk, valid_pixel, last_pixel, data_reg, state, run, counter, curPos) begin
			case state is 
				when idle=>
					if(run = '1') then
						nextState <= waitForValid;
					else
						nextState <= state;
					end if;
				when waitForValid=>
					if valid_pixel = '1' then
						nextState <= ack;						
					else
						nextState <= waitForValid;
					end if;
				when ack =>
					if last_pixel = '1' then
						nextState <= display;
					else
						nextState <= writeState;
					end if;					
				when t0H =>
					if(counter >= t0H_time) then
						nextState<= finishCycle;
					else
						nextState <= state;
					end if;
				
				when 	t1H=>
					if (counter >= t1H_time) then
						nextState<=finishCycle;
					else
						nextState<=state;
					end if;
					
				when 	finishCycle=>
					if (counter >= cycleTime) then
						nextState<= incCount;
					else 
						nextState<= state;
					end if;
					
				when 	incCount =>
					nextState <= writeState;
				
				when 	display=>
					if (counter >= tHoldTime ) then
						nextState<=idle;
					else
						nextState <=state;
					end if;
				
				when 	writeState=>
					if (curPos >= 24) then
						nextState <= waitForValid;
					else
						if(data_reg(0) = '1') then
							nextState <= t1H;
						else
							nextState <= t0H;
						end if;
					end if;
				when others => nextState <= idle;
			end case;	
	end process;
	
	
	-- Process to count the cycles of the current bit
	counterPro: process(clk) is begin
		if rising_edge(clk) then
			if (nextState = finishCycle or nextState = t1H or nextState = t0H or nextState = display) then
				counter <= counter + '1';
			else
				counter <= (others => '0');
			end if;
		end if;
		
	end process;
	
	-- Keep track of the current position that is being written to
	posPorcess: process(clk) is begin
		if rising_edge(clk) then
			if( nextState = incCount ) then
				curPos <= curPos + 1;
			elsif nextState = display or nextState = ack then
				curPos <= 0;
			else
				curPos <= curPos;
			end if;
		end if;
	end process;
	
	ack_output: process(clk) is begin
		if rising_edge(clk) then
			ack_pixel <= '0';
			if nextState = ack then
				ack_pixel	<= '1';
			end if;
		end if;
	end process;
end Behavioral;

