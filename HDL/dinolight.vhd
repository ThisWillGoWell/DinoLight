----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:57:51 04/18/2017 
-- Design Name: 
-- Module Name:    dinolight - Behavioral 
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

entity dinolight is
	 generic (	num_blocks 	: natural 	:= 32
					);
    Port (
			  clk_50			 : in std_logic;
			  hdmi_in_p     : in  STD_LOGIC_VECTOR(3 downto 0);
           hdmi_in_n     : in  STD_LOGIC_VECTOR(3 downto 0);
           hdmi_in_sclk  : inout  STD_LOGIC;
           hdmi_in_sdat  : inout  STD_LOGIC;                    
			  
			  leds			:	out	std_logic_vector( 7 downto 0);
			  
			  portC10			: 	in std_logic;
			  portC6			: 	out std_logic;
			  portC8			:	out std_logic
			  
			 );
			 
end dinolight;

architecture Behavioral of dinolight is

	component video_averager is
		generic (num_blocks : natural := 25);
		Port (
			hdmi_in_p     : in  STD_LOGIC_VECTOR(3 downto 0);
			hdmi_in_n     : in  STD_LOGIC_VECTOR(3 downto 0);
			hdmi_in_sclk  : inout  STD_LOGIC;
			hdmi_in_sdat  : inout  STD_LOGIC;                    
			vsync 			: out std_logic;
			framebuffer		: out std_logic_vector(0 to num_blocks * 24 - 1);
			clk_pixel		: out std_logic
		);
	end component;

	component neopixel_top is
		Generic(
				num_blocks: natural :=30
				 );
		 Port ( 
				  clk : in  STD_LOGIC;
				  blocks : in std_logic_vector(0 to num_blocks * 24 -1);
				  block_counts : in std_logic_vector(0 to num_blocks * 8 -1);
				  neopixel_data: out std_logic;
				  run: in  STD_LOGIC
				  );
				  
	end component;

	
	component cross_clock_pulse is
		Port(
			clk_in 	: in std_logic;
			pulse_in : in std_logic;
			clk_out 	: in std_logic;
			pulse_out: out std_logic
			);
	end component;
	
	component cross_clock_register is
	Generic( register_size : natural := 8);
    Port ( 
			  clk_out 		: in  STD_LOGIC;
			  signal_in 	: in  STD_LOGIC_VECTOR(0 to register_size -1 );
           signal_out 	: out  STD_LOGIC_VECTOR(0 to register_size - 1)
         );		  
	end component;
	
	
	component uart_top is
	generic (
		clocks_per_bit      : positive := 435;
		clock_frequency     : positive := 50_000_000;
		num_blocks			  : natural  := 100
	);
	 
    port (  
		-- external 
		clock                	:   in      std_logic;
		user_reset              :   in      std_logic;    
		usb_rs232_rxd           :   in      std_logic;
		usb_rs232_txd           :   out     std_logic;
		-- data in
		periodic_send_data	: in std_logic_vector(47 downto 0); 
		-- data out registers
		mode						: out std_logic_vector(1 downto 0);
		block_counts			: out std_logic_vector(0 to num_blocks * 8 -1);
		custom_block_colors 	: out std_logic_vector(0 to num_blocks * 24 -1);
		custom_block_change 	: out std_logic;
		debug_leds				: out std_logic_vector(7 downto 0)
    );
	 end component;
	 
		
	
	signal vsync_50				: std_logic;
	signal vsync_pixel			: std_logic;
	signal framebuffer_pixel 	: std_logic_vector(0 to num_blocks * 24 -	1);
	signal framebuffer_50		: std_logic_vector(0 to num_blocks * 24 - 1);	
	
	signal clk_pixel				: std_logic;
	signal mode						: std_logic_vector(1 downto 0);
	
	signal neopixel_select		: std_logic_vector(0 to num_blocks * 24 -1);
	signal run_neopixel			: std_logic;
	signal custom_colors			: std_logic_vector(0 to num_blocks * 24 -1 );
	signal custom_color_change	:	std_logic;
	signal pixelBlockCount 		:	std_logic_Vector(0 to num_blocks * 8 -1);
	signal done_mapping			: std_logic;
	
	signal periodic_send_data_pixel : std_logic_vector(47 downto 0);
	signal periodic_send_data_50 : std_logic_vector(47 downto 0);

begin

cross_clock_vsync: cross_clock_pulse port map(clk_pixel, vsync_pixel, clk_50, vsync_50);
cross_clock_framebuffer: cross_clock_register generic map(24 * num_blocks) port map(clk_50, framebuffer_pixel, framebuffer_50);
corss_clock_screenAverage: cross_clock_register generic map(24 * 2) port map(clk_50, periodic_send_data_pixel, periodic_send_data_50);

leds(1 downto 0) <= mode; 
leds(7 downto 2) <= (others => '0');


neoPixel: neopixel_top 
	generic map( num_blocks => num_blocks)
	Port map(
		clk => clk_50,
		run => run_neopixel,
		blocks => neopixel_select,
		block_counts => pixelBlockCount,
		neopixel_data =>  portC6
		);
		
hdmi_averager: video_averager
		generic map(num_blocks => num_blocks)
		Port map(
			  hdmi_in_p     => hdmi_in_p,
           hdmi_in_n     => hdmi_in_n,
           hdmi_in_sclk  => hdmi_in_sclk,
           hdmi_in_sdat  => hdmi_in_sdat,                   
			  vsync 			 => vsync_pixel,
			  framebuffer	 => framebuffer_pixel,
			  clk_pixel	 	 => clk_pixel
			 );

uart: uart_top 
	generic map(num_blocks => num_blocks)
	port map(
	clock => clk_50,
		user_reset => '0',
		usb_rs232_rxd => portC10,
		usb_rs232_txd => portC8,
		
		-- data in
		periodic_send_data	=> (others => '0'),
		-- data out registers
		mode => mode,
		
		custom_block_colors => custom_colors, 		
		custom_block_change => custom_color_change,
		block_counts => pixelBlockCount
		);
	

			 
ledSwitch: process(clk_50) is
begin
	if rising_edge(clk_50) then
		if mode = "00" then
			run_neopixel <= '0';
		elsif mode = "01" then
			run_neopixel <= vsync_50;
			neopixel_select <= framebuffer_50;
		elsif mode = "10" then 
			run_neopixel	<= custom_color_change;
			neopixel_select <= custom_colors;
		end if;
	end if;
	
end process;
end Behavioral;

