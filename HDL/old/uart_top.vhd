-------------------------------------------------------------------------------
-- Top level for uart controller with registers
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_top is
    generic (
        baud                : positive := 1_000_000;
        clock_frequency     : positive := 50_000_000;
		  num_leds				 : natural  := 100
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
end uart_top;

architecture rtl of uart_top is
	 ----------------------------------------------------------------------------
	 -- Uart Signals
	 ----------------------------------------------------------------------------
	signal uart_data_in : std_logic_vector(7 downto 0);
	signal uart_data_out: std_logic_vector(7 downto 0);
	signal uart_data_in_stb: std_logic:= '0';
	signal uart_data_in_ack : std_logic := '0';
	signal uart_data_out_stb : std_logic := '0';
	
	 -- Transmit buffer signals
    constant buffer_depth : integer   := 128;
    signal fifo_data_out : std_logic_vector(7 downto 0);
    signal fifo_data_in  : std_logic_vector(7 downto 0);
    signal fifo_data_in_stb : std_logic;
    signal fifo_data_out_stb : std_logic;
    signal fifo_full : std_logic;
    signal fifO_empty : std_logic;
	 
	 --top level signals for debouncing
	signal tx, rx, rx_sync, reset, reset_sync : std_logic;	
	
	  component uart is
        generic (
            baud                : positive;
            clock_frequency     : positive
        );
        port (
            clock               :   in      std_logic;
            reset               :   in      std_logic;    
            data_stream_in      :   in      std_logic_vector(7 downto 0);
            data_stream_in_stb  :   in      std_logic;
            data_stream_in_ack  :   out     std_logic;
            data_stream_out     :   out     std_logic_vector(7 downto 0);
            data_stream_out_stb :   out     std_logic;
            tx                  :   out     std_logic;
            rx                  :   in      std_logic
        );
    end component;

	 --Uart reciver controller
	 --takes in bytes from the uart component and 
	 --decies on where to place them
	 
	 component  uart_rx_controller is
		Generic(num_commands : natural := 3;
				  num_leds : natural := 30
				  );
		
		Port( clk : in std_logic;
				data_in : in std_logic_vector(7 downto 0);
				data_valid : in std_logic;
				--register output values
				power_reg : out std_logic;
				led_map_regs : out std_Logic_vector(NUM_LEDS * 16 - 1 downto 0);
				led_value_regs : out std_logic_vector(NUM_LEDS * 24 - 1 downto 0);
				led_value_change : out std_logic
				);
	end component;
	
	--Fifo to store the incomming commands so they can be echoed back
	
	 component generic_fifo is
        generic (
            fifo_width : positive := 32;
            fifo_depth : positive := 1024
        );
        port (
            clock       : in std_logic;
            reset       : in std_logic;
            write_data  : in std_logic_vector(FIFO_WIDTH-1 downto 0);
            read_data   : out std_logic_vector(FIFO_WIDTH-1 downto 0);
            write_en    : in std_logic;
            read_en     : in std_logic;
            full        : out std_logic;
            empty       : out std_logic;
            level       : out std_logic_vector(
                integer(ceil(log2(real(fifo_depth))))-1 downto 0
            )
        );
    end component;
	 
	 signal data_valid_clocked : std_logic; 
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
				data_valid_clocked <= uart_data_out_stb;
        end if;
    end process;
	 
	 --Uart interface
	 
	 uart_inst : uart
    generic map (
		baud                => baud,
		clock_frequency     => clock_frequency
    )
    port map    (  
		-- general
		clock               => clock,
		reset               => reset,
		data_stream_in      => uart_data_in,
		data_stream_in_stb  => uart_data_in_stb,
		data_stream_in_ack  => uart_data_in_ack,
		data_stream_out     => uart_data_out,
		data_stream_out_stb => uart_data_out_stb,
		tx                  => tx,
		rx                  => rx
    );
	 
	-- rx memory controller
	
	rx_controller : uart_rx_controller	
		generic map(
		num_leds		=> num_leds
	)
	port map(
		clk	=> clock,
		data_in 		=> uart_data_out,
		data_valid 	=>	data_valid_clocked,
		--register output values
		power_reg		=> power_reg, 
		led_map_regs	=> led_map_regs,
		led_value_regs => led_value_regs,
		led_value_change => led_value_change
	);
	 
	  receive_buffer : generic_fifo
    generic map(
        fifo_width  => 8,
        fifo_depth  => buffer_depth
    )
    port map(
        clock        => clock,
        reset        => reset,
        write_data   => fifo_data_in,
        read_data    => fifo_data_out,
        write_en     => fifo_data_in_stb,
        read_en      => fifo_data_out_stb,
        full         => fifo_full,
        empty        => fifo_empty,
        level        => open
    );
	 
	 
	 uart_loopback : process (clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                uart_data_in_stb        <= '0';
                uart_data_in            <= (others => '0');
                fifo_data_out_stb       <= '0';
                fifo_data_in_stb        <= '0';
            else
                -- Acknowledge data receive strobes and set up a transmission
                -- request
                fifo_data_in_stb    <= '0';
                if uart_data_out_stb = '1' and fifo_full = '0' then
                    fifo_data_in_stb    <= '1';
                    fifo_data_in        <= uart_data_out;
                end if;
                -- Clear transmission request strobe upon acknowledge.
                if uart_data_in_ack = '1' then
                    uart_data_in_stb    <= '0';
                end if;
                -- Transmit any data in the buffer
                fifo_data_out_stb <= '0';
                if fifo_empty = '0' then
                    if uart_data_in_stb = '0' then
                        uart_data_in_stb <= '1';
                        fifo_data_out_stb <= '1';
                        uart_data_in <= fifo_data_out;
                    end if;
                end if;
            end if;
        end if;
    end process;    
	 
	 
	 
	 
	 
end rtl;