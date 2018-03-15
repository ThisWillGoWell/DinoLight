----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:38:23 07/06/2015 
-- Design Name: 
-- Module Name:    NeoPixelDriver - Behavioral 
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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity NeoPixelDriver is
	Generic(NUM_LEDS : natural :=30
			 );
    Port ( data_in : in std_logic_vector(NUM_LEDS*24-1 downto 0);
           clk50 : in  STD_LOGIC;
			  data_out: out std_logic;
           reset : in STD_LOGIC;
			  run: in  STD_LOGIC);
			  
end NeoPixelDriver;

architecture Behavioral of NeoPixelDriver is
	signal counter : std_logic_vector(15 downto 0) := (others=>'0');
	signal curPos : integer range 0 to NUM_LEDS*24-1;
	signal data_reg: std_logic_vector(NUM_LEDS*24-1 downto 0) := (others=>'0');
	
	type stateType is ( t0H, t0L, t1H, t1L, res, reset1, reset0, incCount, display, writeState, resetState, idle, loadReg);
	
	signal state, nextState : stateType := idle;
	constant t0h_time : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(20,16));
	constant t0l_time : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(42,16));
	constant t1h_time : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(40,16));
	constant t1l_time : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(22,16));
	constant tholdtime: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(2500,16));
	
begin

	nextStateTrans: process(clk50) is begin
		if rising_edge(clk50) then
			state <= nextState;
		end if;
	end process;
	
	
	outputProcess: process(clk50) is begin
		if rising_edge(clk50) then
			case nextState is
				when t0H | t1H => 
					data_out<='1';
				when t0L | t1L | res | reset1 | reset0 =>
					data_out<='0';
				when others =>
					data_out <= '0';
			end case;
		end if;
	end process;
	
	loadProcess: process(clk50) is begin
		if rising_edge(clk50) then
			if nextState =display then
				data_reg <= data_in;
			end if;
		end if;
	end process;


	nextStateDecode: process(clk50, data_reg, state, reset, run, counter, curPos) begin
			if reset= '1' then
				nextState <= resetState;
			else
				case state is 
					when resetState=>
						nextState <= idle;
					when idle=>
						if(run = '1') then
							nextState <= writeState;
						else
							nextState <= state;
						end if;
					when t0H =>
						if(counter >= t0H_time) then
							nextState<= reset0;
						else
							nextState <= state;
						end if;
				
					when t0L=>
						if(counter >= t0L_time) then
							nextState<=incCount;
						else
							nextState<=state;
						end if;
					
					when 	t1H=>
						if (counter >= t1H_time) then
							nextState<=reset1;
						else
							nextState<=state;
						end if;
					
					when 	t1L=>
						if (counter >= t1L_time) then
							nextState<= incCount;
						else 
							nextState<= state;
						end if;
						
					when 	reset0=>
						nextState<=t0L;
						
					
					when 	reset1=>
						nextState<=t1L;
					
					when 	incCount =>
						nextState <= writeState;
					
					when 	display=>
						if (counter = tHoldTime ) then
							nextState<=idle;
						else
							nextState <=state;
						end if;
					
					when 	writeState=>
						if (curPos = (NUM_LEDS*24-1)) then
							nextState <= display;
						elsif(data_reg(curPos) = '1') then
							nextState <= t1H;
						elsif(data_reg(curPos) = '0') then
							nextState <= t0H;
						else
							nextState <= display;
						end if;
					when others => nextState <= idle;
				end case;	
			end if;
	end process;
	
	
	
	counterPro: process(clk50) is begin
		if rising_edge(clk50) then
			if (nextState = t1L or nextState = t1H or nextState = t0L or nextState = t0H or nextState = display) then
				counter <= counter + '1';
			else
				counter <= (others => '0');
			end if;
		end if;
		
	end process;
	
	
	posPorcess: process(clk50) is begin
		if rising_edge(clk50) then
			if( nextState = incCount ) then
				curPos <= curPos + 1;
			elsif nextState = display or nextState = resetState or nextState = idle then
				curPos <= 0;
			else
				curPos <= curPos;
			end if;
		end if;
	end process;
	
	


end Behavioral;

