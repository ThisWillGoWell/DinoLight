----------------------------------------------------------------------------------
-- Engineer: drxzclx@gmail.com
-- 
-- Create Date:    22:35:50 01/09/2015 
-- Design Name: 	HDMI block averager
-- Module Name:     - Behavioral 
-- Project Name: 	Neppielight
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity averager is
	generic(
		num_cols : natural := 96;
		num_rows : natural := 64
	);
    Port ( 
      clk_pixel : IN std_logic;
      --
		i_red     : IN std_logic_vector(7 downto 0);
		i_green   : IN std_logic_vector(7 downto 0);
		i_blue    : IN std_logic_vector(7 downto 0);
		i_blank   : IN std_logic;
		i_hsync   : IN std_logic;
		i_vsync   : IN std_logic;          
      --
		framebuffer : OUT std_logic_vector(0 to 32*24-1);
		leftAverage : out std_logic_vector(0 to 23);
		rightAverage : out std_logic_vector(0 to 23)
		);  
end averager;

architecture Behavioral of averager is

   -------------------------
   -- Part of the pipeline
   -------------------------
	signal a_red     : std_logic_vector(7 downto 0);
	signal a_green   : std_logic_vector(7 downto 0);
	signal a_blue    : std_logic_vector(7 downto 0);
	signal a_blank   : std_logic;
	signal a_hsync   : std_logic;
	signal a_vsync   : std_logic;  

   -------------------------------
   -- Counters for screen position   
   -------------------------------
   signal x : STD_LOGIC_VECTOR (10 downto 0);
   signal y : STD_LOGIC_VECTOR (10 downto 0);

	constant nblocks : integer := 32;	

   -- signal pixel : std_logic_vector(23 downto 0) := (others => '0'); 
   type accumulator_type is array (0 to nblocks-1,0 to 3) of std_logic_vector(21 downto 0);
	signal accumulator : accumulator_type;
	signal frame_buffer : std_logic_vector(0 to num_rows * num_cols * 24);
	
	--signal blocknr : integer range 0 to 10;
	
	type blockcoords_type is array (0 to nblocks-1) of integer;
	-- Due to the details of the construction, we start in the lower left corner
	-- and work our way clockwise.
	-- Laterally, we've got more leds than pixels, so we'll have partially verlapping boxes.
	constant startx : blockcoords_type := (0, 115, 230, 346, 461, 576, 691, 806, 922, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1037, 922, 806, 691, 576, 461, 346, 230, 0, 0, 0, 0, 0, 0, 0);
	constant starty : blockcoords_type := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 99, 197, 296, 395, 592, 592, 592, 592, 592, 592, 592, 592, 592, 592, 592, 592, 493, 395, 296, 197, 0);
begin

process(clk_pixel)
	variable blockedge : std_logic := '0';
   begin
      if rising_edge(clk_pixel) then
			for bn in 0 to nblocks-1 loop
				if unsigned(x) >= startx(bn) and unsigned(x) < startx(bn)+128 and
						unsigned(y) >= starty(bn) and unsigned(y) < starty(bn)+128 then
					-- We are a part of block bn. Accumulate the color info.
					accumulator(bn,0) <= std_logic_vector(unsigned(accumulator(bn,0)) + unsigned(a_red));
					accumulator(bn,1) <= std_logic_vector(unsigned(accumulator(bn,1)) + unsigned(a_green));
					accumulator(bn,2) <= std_logic_vector(unsigned(accumulator(bn,2)) + unsigned(a_blue));
				end if;
			end loop;
		
         a_red     <= i_red;
         a_green   <= i_green;
         a_blue    <= i_blue;
         a_blank   <= i_blank;
         a_hsync   <= i_hsync;
         a_vsync   <= i_vsync;
				
         -- Working out where we are in the screen..
         if i_vsync /= a_vsync then
            y <= (others => '0');
				
				if i_vsync = '1' then
					for i in 0 to nblocks-1 loop
						for c in 0 to 2 loop
							framebuffer(c * 8 + i * 24 to i * 24 + c * 8 + 7) <= accumulator(i,c)(21 downto 14);
							accumulator(i,c) <= (others => '0');
						end loop;
					end loop;
	
					
				end if;						
         end if;

         if i_blank = '0' then
            x <= std_logic_vector(unsigned(x) + 1);
         end if;

         -- Start of the blanking interval?
         if a_blank = '0' and i_blank = '1' then
            y <= std_logic_vector(unsigned(y) + 1);
            x <= (others => '0');
         end if;

      end if;
   end process;
end Behavioral;

