----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:13:48 04/24/2017 
-- Design Name: 
-- Module Name:    neopixel_top_wrapper - Behavioral 
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

entity neopixel_top_wrapper is
	generic (clocks_per_bit 			: positive := 435);
    Port ( clk 					: in  STD_LOGIC;
           portA0 				: out  STD_LOGIC;
			  portA2					: out std_logic;
			  portA6					: in std_logic;
			  portA8 				: out std_logic;
			  leds					: out std_logic_vector(7 downto 0)
			  );
end neopixel_top_wrapper;

architecture Behavioral of neopixel_top_wrapper is
component neopixel_top is
	generic(
		num_blocks : natural := 25
	);
	port(
		clk		: in std_logic;
		blocks	: in std_logic_vector(0 to num_blocks * 24 - 1);
		block_counts : in std_logic_vector(0 to num_blocks * 8 - 1);
		run			: in std_logic;
		neopixel_data	: out std_logic
		);
		
end component;

component uart_top is
    generic (
        clocks_per_bit                : positive := 435;
        clock_frequency     : positive := 50_000_000;
		  num_blocks				 : natural  := 100
    );
	 
    port (  
		-- external 
		clock                	:   in      std_logic;
		user_reset              :   in      std_logic;    
		usb_rs232_rxd           :   in      std_logic;
		usb_rs232_txd           :   out     std_logic;
		-- data in
		periodic_send_data	: in std_logic_vector(23 downto 0); 
		-- data out registers
		mode				: out std_logic_vector(1 downto 0);
		block_counts		: out std_logic_vector(0 to num_blocks * 8 -1);
		custom_block_colors : out std_logic_vector(0 to num_blocks * 24 -1);
		custom_block_change : out std_logic;
		debug_leds			: out std_logic_vector(7 downto 0)
    );
end component;

constant num_blocks : natural := 12;
signal counter : integer range 0 to 1000000;
Signal counts : std_logic_vector( num_blocks * 8 -1 downto 0);
signal values : std_logic_vector(0 to num_blocks * 24 -1);
signal run		: std_logic;
signal hold_run : std_logic;
begin
portA8 <= hold_run;

--counts <= x"02_02_02_02_02_02_02_02_02_02_02_02";
--values <= x"010101_011000_FF0000_00FFFF_0F0F0F_000000_FFFFFF_010000_008000_0000FF_000000_0F0F0F";

neopixel: neopixel_top 
	generic map(
		num_blocks => num_blocks
	) 
	port map(
		clk=> clk,
		blocks=>values, 
		block_counts=> counts, 
		run=> run, 
		neopixel_data => portA0
);

uart: uart_top 
generic map(
	num_blocks => num_blocks, 
	clocks_per_bit=> clocks_per_bit
) 
port map(
	clock => clk, 
	user_reset => '0', 
	usb_rs232_rxd => portA6,
	usb_rs232_txd => portA2, 
	periodic_send_data=> x"000000", 
	custom_block_colors=> values, 
	custom_block_change => run,
	block_counts => counts,
	debug_leds => leds
);


runProcess: process(clk)
	begin
	if rising_edge(clk) then
		hold_run <= '0';
		if run = '1' then
			counter <= 100000;
		elsif counter /= 0 then
			counter <= counter - 1;
			hold_run <= '1';		
		end if;
	end if;
end process;

end Behavioral;

