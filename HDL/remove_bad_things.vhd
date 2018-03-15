----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:15:55 04/16/2017 
-- Design Name: 
-- Module Name:    removeBadThings - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity remove_bad_things is
	Generic( clean_width : natural := 64);
	 Port ( clk_in       : in  STD_LOGIC;
			  signal_in  	: in std_logic;
			  signal_out 	: out std_logic
			  );

end remove_bad_things;

architecture Behavioral of remove_bad_things is
	Signal removeBuffer : std_Logic_vector( 0 to clean_width-1);
	
	function xor_reduct(slv : in std_logic_vector) return std_logic is
		variable res_v : std_logic := '0'; 
		begin
		for i in slv'range loop
			if((slv(i) xor slv(0)) = '1') then
				res_v := '1';
			end if;
		end loop;
		return res_v;
	end function;
	
begin


shiftBuffer: process(clk_in)
	begin
		if rising_edge(clk_in) then
			removeBuffer <= signal_in & removeBuffer(0 to clean_width -2);
		end if;
	end process;



remvoeBadThingsProcess: process(clk_in)
	begin
		if rising_edge(clk_in) then
			if xor_reduct(removeBuffer) = '0' then
				signal_out <= removeBuffer(0);		
			end if;
		end if;
	end process;


end Behavioral;

