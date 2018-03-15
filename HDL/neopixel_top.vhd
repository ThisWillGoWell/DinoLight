----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:15:42 04/22/2017 
-- Design Name: 
-- Module Name:    neopixel_top - Behavioral 
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
entity neopixel_top is
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
		
end neopixel_top;

architecture Behavioral of neopixel_top is
	component NeoPixelDriver is
    Port ( clk 			: in  STD_LOGIC;
			  data_out		: out std_logic;
			  run				: in  STD_LOGIC;
			  valid_pixel	: in std_logic;
			  last_pixel	: in std_Logic;
			  ack_pixel		: out std_logic;
			  data_in 	: in 	std_logic_vector(0 to 23)
			  );
		
			  
end component;

	component blockToPixel is
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
	end component;

	signal current_pixel : std_Logic_vector(0 to 23);
	signal last_pixel : std_logic;
	signal pixel_ack : std_logic;
	signal valid_pixel : std_logic;

begin

	pixelGenerator: blockToPixel
	generic map(
		num_blocks => num_blocks
		)
	port map(
		clk => clk,
		run => run,
		pixelBlocks => blocks,
		pixelBlockCount => block_counts,
		advance_pixel => pixel_ack,
		last_pixel => last_pixel,
		valid_pixel => valid_pixel,
		current_pixel => current_pixel		
	);
	
	neopixel_drive: neopixelDriver
	port map(
	run => run,
	clk => clk,
	data_out => neopixel_data,
	valid_pixel => valid_pixel,
	data_in => current_pixel,
	ack_pixel => pixel_ack,
	last_pixel => last_pixel
	);
end Behavioral;

