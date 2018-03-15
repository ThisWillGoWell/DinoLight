----------------------------------------------------------------------------------
-- Top Level of file that can accpect a uart connection and then translate that to
-- a Neopixel

-- Write 0x02 (command out of rxController) and then accepct numPixels*24 bits
-- command 1 should control led0
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

entity neopixel_uart is
	Generic( baud	: positive 	:= 460800;
				NUM_LEDS: natural := 90
				);
	port( clk 	: in std_logic;
			rx		: in std_logic;
			tx		: out std_logic;
			powerLED : out std_logic;
			neopixel_data_out : out std_logic
			);
		
		
end neopixel_uart;

architecture Behavioral of neopixel_uart is

--Uart component
-- has a uart reciver and register controller

component uart_top is
    generic (
        baud                : positive := 115200;
        clock_frequency     : positive := 50_000_000;
		  NUM_LEDS				 : natural  := 30
		  );
    port (  
		clock                	  :   in      std_logic;
		user_reset              :   in      std_logic;    
		usb_rs232_rxd           :   in      std_logic;
		usb_rs232_txd           :   out     std_logic;		  
	  -- registers
		power_reg 				: out std_logic;
		led_map_regs 			: out std_Logic_vector(NUM_LEDS * 16 - 1 downto 0);
		led_value_regs 		: out std_logic_vector(NUM_LEDS * 24 - 1 downto 0);
		led_value_change		: out std_logic
    );
end component;

--Neopixel Driver 
component NeoPixelDriver is
	Generic(NUM_LEDS : integer range 0 to 255:=30
			 );
    Port ( data_in : in std_logic_vector(NUM_LEDS*24-1 downto 0);
           clk50 : in  STD_LOGIC;
			  data_out: out std_logic;
           reset : in STD_LOGIC;
			  run: in  STD_LOGIC);
end component;
		
--Signals to map the uart controller with the neopixelDriver		
signal led_value_regs : std_logic_vector(NUM_LEDS *24 -1 downto 0);
signal power_reg, led_value_change : std_logic;
signal led_map_reg : std_logic_vector(NUM_LEDS *16 -1 downto 0);
begin

powerLED <= power_reg;

neopixel: NeoPixelDriver 
	Generic map(NUM_LEDS => NUM_LEDS ) 
	Port map(data_in => led_value_regs,
				clk50 => clk,
				data_out =>neopixel_data_out,
				reset => '0',
				run => led_value_change);

uart: uart_top 
	Generic map(baud => baud,
					NUM_LEDS => NUM_LEDS) 
	Port map(clock => clk,
				user_reset => '0',
				usb_rs232_rxd => rx,
				usb_rs232_txd => tx,
				power_reg => power_reg,
				led_map_regs => led_map_reg,
				led_value_regs => led_value_regs,
				led_value_change => led_value_change
				);
				
				
end Behavioral;

