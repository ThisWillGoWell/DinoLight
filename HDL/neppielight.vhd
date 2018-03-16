library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity video_averager is
	 generic (num_blocks : natural := 32);
    Port (
			  hdmi_in_p     : in  STD_LOGIC_VECTOR(3 downto 0);
           hdmi_in_n     : in  STD_LOGIC_VECTOR(3 downto 0);
           hdmi_in_sclk  : inout  STD_LOGIC;
           hdmi_in_sdat  : inout  STD_LOGIC;                    
			  vsync 			: out std_logic;
			  framebuffer	: out std_logic_vector(0 to num_blocks * 24 - 1);
			  clk_pixel		: out std_logic	
			 );
end video_Averager;

architecture Behavioral of video_Averager is

	COMPONENT averager
	PORT(
		clk_pixel : IN std_logic;
      --
		i_red     : IN std_logic_vector(7 downto 0);
		i_green   : IN std_logic_vector(7 downto 0);
		i_blue    : IN std_logic_vector(7 downto 0);
		i_blank   : IN std_logic;
		i_hsync   : IN std_logic;
		i_vsync   : IN std_logic;          
      --
		framebuffer: out std_logic_vector(0 to 24*num_blocks-1 );
		leftAverage : out std_logic_vector(0 to 23);
		rightAverage : out std_logic_vector(0 to 23)
	
		);
	END COMPONENT;


	COMPONENT dvid_in
	PORT(
      clk_pixel  : out std_logic;
      leds       : out std_logic_vector(7 downto 0) := (others => '0');
		red_p      : out std_logic_vector(7 downto 0);
		green_p    : out std_logic_vector(7 downto 0);
		blue_p     : out std_logic_vector(7 downto 0);
		blank      : out std_logic;
		hsync      : out std_logic;
		vsync      : out std_logic;          
		tmds_in_p  : in  std_logic_vector(3 downto 0);
		tmds_in_n  : in  std_logic_vector(3 downto 0);
		synced	  : out std_Logic;
		pll_locked_o :out std_logic
		);
	END COMPONENT;
	
	
	component remove_bad_things
	Generic( clean_width : natural := 64);
	Port ( clk_in       : in  STD_LOGIC;
			 signal_in  	: in std_logic;
			 signal_out 	: out std_logic
			 );
	 end component;
	 
	component remove_bad_things_byte 
	Generic( clean_width : natural := 64);
	Port ( clk_in       : in  STD_LOGIC;
		  signal_in	: in std_logic_vector(7 downto 0)  ;
		  signal_out 	: out std_logic_vector(7 downto 0)
		  );
	end component;	

	signal clk_pixel_internal : std_logic;

	-- output of the div
   signal dvid_red     : std_logic_vector(7 downto 0);
   signal dvid_green   : std_logic_vector(7 downto 0);
   signal dvid_blue    : std_logic_vector(7 downto 0);
	signal dvid_blank   : std_logic;
	signal dvid_hsync   : std_logic;
	signal dvid_vsync   : std_logic;              
	
	--cleaned signals comming from the dvi
	signal red_cleaned 	: std_Logic_vector(7 downto 0);
	signal blue_cleaned  : std_logic_vector(7 downto 0);
	signal green_cleaned : std_logic_vector(7 downto 0);
	
	signal vsync_cleaned: std_logic;
	signal hsync_cleaned: std_logic;
	signal blank_cleaned: std_logic;
	
	signal last_vsync_value : std_Logic;
	
begin
	clk_pixel <= clk_pixel_internal;
	
   hdmi_in_sclk  <= 'Z';
   hdmi_in_sdat  <= 'Z';
	
	Inst_dvid_in: dvid_in PORT MAP(
		tmds_in_p => hdmi_in_p,
		tmds_in_n => hdmi_in_n,
		
		clk_pixel => clk_pixel_internal,
		red_p     => dvid_red,
		green_p   => dvid_green,
		blue_p    => dvid_blue,
		blank     => dvid_blank,
		hsync     => dvid_hsync,
		vsync     => dvid_vsync
		
	);
	
	-- due to noise on the wire from the DVID I put in place a digital smitt trigger of storts
	-- will only swich if gets 64 of the same vaule
	
	clean_vsync	: remove_bad_things port map(clk_pixel_internal, dvid_vsync, vsync_cleaned);
	clean_hsync	: remove_bad_things port map(	clk_pixel_internal, dvid_hsync, hsync_cleaned);
	clean_blank	: remove_bad_things port map(clk_pixel_internal, dvid_blank, blank_cleaned);
	
	clean_red	: remove_bad_things_byte port map(clk_pixel_internal, dvid_red, red_cleaned);
	clean_green	: remove_bad_things_byte port map(clk_pixel_internal, dvid_green, green_cleaned);
	clean_blue	: remove_bad_things_byte port map(clk_pixel_internal, dvid_blue, blue_cleaned);

	Inst_averager: averager PORT MAP(
		clk_pixel => clk_pixel_internal,
		i_red     => red_cleaned,
      i_green   => green_cleaned,
      i_blue    => blue_cleaned,
		i_blank   => blank_cleaned,
		i_hsync   => hsync_cleaned,
		i_vsync   => vsync_cleaned,
		framebuffer => framebuffer(0 to num_blocks * 24 -1)
	);
	
   -- convert the vsync clock into a single pulse
	vsync1Clock: process(clk_pixel_internal)
	begin
		if rising_edge(clk_pixel_internal) then
			last_vsync_value <= vsync_cleaned;
			vsync <= '0';
			if(last_vsync_value /= vsync_cleaned) then
				vsync <= '1';
			end if;
		end if;
	end process;
	

	
end Behavioral;

