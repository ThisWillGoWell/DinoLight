-------------------------------------------------------------------------------
-- Top level for uart controller with registers
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_top is
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
		periodic_send_data	: in std_logic_vector(47 downto 0); 
		-- data out registers
		mode				: out std_logic_vector(1 downto 0);
		block_counts		: out std_logic_vector(0 to num_blocks * 8 -1);
		custom_block_colors : out std_logic_vector(0 to num_blocks * 24 -1);
		custom_block_change : out std_logic;
		debug_leds			: out std_logic_vector(7 downto 0)
    );
end uart_top;

architecture rtl of uart_top is
	 ----------------------------------------------------------------------------
	 -- Uart Signals
	 ----------------------------------------------------------------------------
	signal uart_data_in 		: std_logic_vector(7 downto 0);
	signal uart_data_out		: std_logic_vector(7 downto 0);
	signal uart_data_in_stb	: std_logic:= '0';
	signal uart_tx_active : std_logic := '0';
	signal uart_tx_done : std_logic;
	signal uart_data_out_stb: std_logic := '0';
	
	 --top level signals for debouncing
	signal tx, rx, rx_sync, reset, reset_sync : std_logic;	
	component  UART_RX is
  generic (
    g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end component;

component  UART_TX is
  generic (
    g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_TX_DV     : in  std_logic;
    i_TX_Byte   : in  std_logic_vector(7 downto 0);
    o_TX_Active : out std_logic;
    o_TX_Serial : out std_logic;
    o_TX_Done   : out std_logic
    );
end component;


	 --Uart reciver controller
	 --takes in bytes from the uart component and 
	 --decies on where to place them
	 
	component uart_rx_controller is
		Generic(num_commands : natural := 3;
				num_blocks : natural := 30
				);
		
		Port( clk 					: in std_logic;
				reset_in 			: in std_logic;
				data_in 				: in std_logic_vector(7 downto 0);
				data_valid 			: in std_logic;
				
				mode				 	: out std_logic_vector(1 downto 0);
				mode_value_change 		: out std_logic;
				
				custom_block_values	: out std_logic_vector(0 to  num_blocks * 24 -1);
				block_counts				: out std_Logic_vector(0 to num_blocks * 8 -1);
				custom_block_change 	: out std_logic
				);
	end component;
	
	-- Uart tx controller
	-- periordically sends out the data in the register byte by byte
	component uart_tx_controller is
	Generic( clock_cycles_send_period : natural := 10_000_000);
	Port(
			clk						: in std_logic;
			periodic_send_data	: in std_logic_vector(47  downto 0) ;
			data_to_uart			: out std_logic_vector(7 downto 0);
			uart_data_ack			: in std_logic;
			uart_data_stb			: out std_logic
			);
	end component;

begin
    ----------------------------------------------------------------------------
    -- Deglitch inputs
    ----------------------------------------------------------------------------
    deglitch : process (clock)
    begin
        if rising_edge(clock) then
            rx_sync         <= usb_rs232_rxd;
            rx              <= rx_sync;
            reset_sync      <= user_reset;
            reset           <= reset_sync;
            usb_rs232_txd   <= tx;
        end if;
    end process;
	 debug_leds <= uart_data_out;
	 
	 -- Actual RX UART interface 
	 uart_serial_rx: uart_rx
	 generic map(    g_CLKS_PER_BIT => clocks_per_bit)
	 port map(
		i_Clk       => clock,
		i_RX_Serial => rx,
		o_RX_DV     => uart_data_out_stb,
		o_RX_Byte   =>uart_data_out
		);
		
	-- TX uart Interface
	uart_serial_tx: uart_tx
	generic map(    g_CLKS_PER_BIT => clocks_per_bit)
	port map(
		i_Clk => clock,
		i_tx_dv => uart_data_in_stb,
		i_tx_byte => uart_data_in,
		o_tx_serial => tx,
		o_tx_active => uart_tx_active,
		o_tx_done => uart_tx_done
		);
	 
	 
	-- rx memory controller
	rx_controller : uart_rx_controller	
		generic map(
		num_blocks		=> num_blocks
	)
	port map(
		clk					=> clock,
		reset_in				=> '0',
		data_in 				=> uart_data_out,
		data_valid 			=>	uart_data_out_stb,
		mode					=> mode, 
		custom_block_values 	=> custom_block_colors,
		custom_block_change 	=> custom_block_change,
		block_counts			=> block_counts
	);
	 
	-- tx periordic send controller
	tx_controller : uart_tx_controller
	port map(
			clk						=> clock,
			periodic_send_data	=> periodic_send_data,
			data_to_uart			=> uart_data_in,
			uart_data_ack			=> uart_tx_done,
			uart_data_stb			=> uart_data_in_stb
		);
			
end rtl;