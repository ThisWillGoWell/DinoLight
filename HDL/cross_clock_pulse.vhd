----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:20:20 04/18/2017 
-- Design Name: 
-- Module Name:    cross_clock_pulse - Behavioral 
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

entity cross_clock_pulse is
Port(
	clk_in : in std_logic;
	pulse_in : in std_logic;
	clk_out : in std_logic;
	pulse_out : out std_logic
	);
end cross_clock_pulse;

architecture Behavioral of cross_clock_pulse is
	signal in_reg : std_logic;
	signal out_reg : std_logic_vector(0 to 2);

begin

	pulse_out <= out_reg(2) xor out_reg(1);
	
	inProcess: process(clk_in) is
	begin
		if rising_edge(clk_in) then
			if pulse_in = '1' then
				in_reg <= not in_reg;
			else
				in_reg <= in_reg;
			end if;
		end if;
	end process;
	
	outProcess: process(clk_out)
	begin
		if rising_edge(clk_out) then
			out_reg <= in_reg & out_reg(0 to 1);
		end if;
	end process;

end Behavioral;

