----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:15:02 04/18/2017 
-- Design Name: 
-- Module Name:    cross_clock_register - Behavioral 
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

entity cross_clock_register is
	Generic ( register_size : natural := 8);
    Port ( 
			  clk_out : in  STD_LOGIC;
			  signal_in : in  STD_LOGIC_VECTOR(0 to register_size -1);
           signal_out : out  STD_LOGIC_VECTOR(0 to register_size -1)
			  );
         
end cross_clock_register;


architecture Behavioral of cross_clock_register is

	signal register0 : STD_LOGIC_VECTOR(0 to register_size - 1);
	signal register1 : STD_LOGIC_VECTOR(0 to register_size - 1);
	
begin

	process(clk_out)
	begin
		if rising_edge(clk_out) then
			register0 <= signal_in;
			register1 <= register0;
			signal_out <= register1;
		end if;
	end process;

end Behavioral;

