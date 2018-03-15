----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:11:26 04/16/2017 
-- Design Name: 
-- Module Name:    blockToPixel - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity blockToPixel is
	generic(
		num_blocks : natural := 25
		);
	port(
		clk			: in std_logic;
		run			: in std_logic;
		pixelBlocks : in std_logic_vector(0 to num_blocks * 24 -1);
		pixelBlockCount : in std_logic_vector(0 to num_blocks * 8 - 1);
		
		advance_pixel		: in std_logic;
		
		last_pixel			: out std_logic;
		valid_pixel			: out std_logic;
		current_pixel      : out std_logic_vector(0 to 23)
	
		);
		
		
end blockToPixel;

architecture Behavioral of blockToPixel is
	--current Block
	signal blockCounter : integer range 0 to num_blocks;
	--current number of leds that the current block has been shifted
	signal currentBlockCount	: integer range 0 to 255;
	signal pixelWriteCounter	: integer range 0 to 255;
	
	--used for shifting
	signal pixelBlockRegister	: std_logic_vector(0 to num_blocks * 24 -1);
	signal blockCountRegister  : std_logic_vector(num_blocks * 8 -1 downto 0);
	
	type stateType is (idle, writeOutPixel, waitForAck, waitForLastAck, start, getCurrentInfo, blockCountDecide, ledCountDecide, shiftInPixel, incLEDCount, incBlockCount, shiftBlockRegister, finish);
	signal state, nextState : stateType := idle;
begin
	
	nextStateTrans: process(clk) begin
		if rising_edge(clk) then
				state <= nextState;
		end if;
	end process;
	
	nextStateDecode: process(currentBlockCount,clk, run, state, blockCounter, pixelWriteCounter, blockCounter, advance_pixel)
	begin
		case state is
			when idle=>
				if run = '1' then
					nextState <= start;
				else
					nextState <= state;
				end if;
			when start=>
				nextState <= getCurrentInfo;
			
			when getCurrentInfo =>
				nextState <= ledCountDecide;
				
			when blockCountDecide =>
				if blockCounter = num_blocks then
					nextState <= finish;
				else
					nextState <= getCurrentInfo;
				end if;
			
			when ledCountDecide =>
				if pixelWriteCounter = currentBlockCount then
					nextState <= incBlockCount;
				else
					nextState <= writeOutPixel;
				end if;
				
			when writeOutPixel =>
				nextState <= waitForAck;
			when waitForAck =>
				if advance_pixel = '1' then
					nextState <= incLedCount;
				else
					nextState <= waitForAck;
				end if;
			when incLEDCount =>
				nextState <= ledCountDecide;
			when incBlockCount =>
				nextState <= shiftBlockRegister;
			when shiftBlockRegister =>
				nextState <= blockCountDecide;
			when finish =>
				nextState <=waitForLastAck;
			when waitForLastAck=>
				if advance_pixel = '1' then
					nextState <= idle;
				else
					nextState <= waitForLastAck;
				end if;
			when others=>
				nextState <= state;
			end case;	
			
		
	end process;	
	
	ledCountManager: process(clk) begin
		if rising_edge(clk) then
			if nextState = incLEDCount then
				pixelWriteCounter <= pixelWriteCounter + 1;
			elsif nextState = blockCountDecide then
				pixelWriteCounter <= 0;
			end if;
		end if;
	end process;
	
	
	blockCounterManager: process(clk) begin
		if rising_edge(clk) then
			if nextState = idle then
				blockCounter <= 0;
			elsif nextState = incBlockCount then
				blockCounter <= blockCounter + 1;
			end if;
		end if;
	end process;
	
	mangageBlockRegister: process(clk) begin
		if rising_edge(clk) then
			if nextState = start then
				pixelBlockRegister <= pixelBlocks;
				
			elsif nextState = shiftBlockRegister then
				for i in 0 to  (num_Blocks-1) * 24 -1 loop
					pixelBlockRegister(i) <= pixelBlockRegister(i + 24);
				end loop;
			end if;
		end if;
	
	end process;
	
	
	currentInfo: process(clk) begin
		if rising_edge(clk) then
			if nextState = start then
				blockCountRegister <= pixelBlockCount;
			
			elsif nextState = getCurrentInfo then
				currentBlockCount <= to_integer(unsigned(blockCountRegister(num_blocks * 8 -1  downto num_blocks * 8 -8 )));	
				--current_pixel <= pixelBlockRegister((num_blocks-1) * 24 to num_blocks * 24 -1);
				current_pixel <= pixelBlockRegister(0 to 23);
			elsif nextState = shiftBlockRegister then
				for i in num_blocks * 8 - 9 downto 0 loop
					blockCountRegister(i+8) <= blockCountRegister(i);
				end loop;
			end if;
		end if;
	end process;

	pixelRead: process(clk) begin
		if rising_edge(clk) then
			valid_pixel	<= '0';
			if nextState = writeOutPixel or nextState = finish or nextState = waitForAck or nextState = waitForLastAck then
				valid_pixel <= '1';
			end if;
		end if;
	end process;
	
	
	outputProcess: process(clk) begin
		if rising_edge(clk) then
			last_pixel <= '0';
			if nextState = finish or nextState = waitForLastAck then
				last_pixel <= '1';
			end if;
		end if;
	end process;
	
end Behavioral;

