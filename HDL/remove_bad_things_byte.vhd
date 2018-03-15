----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:33:10 04/16/2017 
-- Design Name: 
-- Module Name:    remove_bad_things_byte - Behavioral 
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

entity remove_bad_things_byte is
Generic( clean_width : natural := 64);
	 Port ( clk_in       : in  STD_LOGIC;
			  signal_in	: in std_logic_vector(7 downto 0)  ;
			  signal_out 	: out std_logic_vector(7 downto 0)
			  );
end remove_bad_things_byte;

architecture Behavioral of remove_bad_things_byte is
component remove_bad_things
	Generic( clean_width : natural := 64);
	Port ( clk_in       : in  STD_LOGIC;
			 signal_in  	: in std_logic;
			 signal_out 	: out std_logic
			 );
	 end component;
	
begin
cleanSignal_generate:
	for i in 0 to 7 generate
		cleanSignal: remove_bad_things port map( clk_in, signal_in(i), signal_out(i));
	end generate cleanSignal_generate;


end Behavioral;

