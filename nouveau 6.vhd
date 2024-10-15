library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spacewire_rx_controller is
end entity tb_spacewire_rx_controller;

architecture testbench of tb_spacewire_rx_controller is

    -- Component declaration for the DUT (Device Under Test)
    component spacewire_rx_controller
        port (
            clk               : in  std_logic;
            reset_n           : in  std_logic;
            fifo_rx_data      : in  std_logic_vector(9 downto 0);
            fifo_rx_empty     : in  std_logic;
            fifo_rx_read      : out std_logic;
            rx_data_out       : out std_logic_vector(7 downto 0);
            rx_data_valid     : out std_logic;
            rx_eop            : out std_logic;
            rx_eep            : out std_logic;
            irq_rx            : out std_logic;
            error_flag        : out std_logic
        );
    end component;

    -- Signals for simulation
    signal clk           : std_logic := '0';
    signal reset_n       : std_logic := '1';
    signal fifo_rx_data  : std_logic_vector(9 downto 0) := (others => '0');
    signal fifo_rx_empty : std_logic := '1';
    signal fifo_rx_read  : std_logic;
    signal rx_data_out   : std_logic_vector(7 downto 0);
    signal rx_data_valid : std_logic;
    signal rx_eop        : std_logic;
    signal rx_eep        : std_logic;
    signal irq_rx        : std_logic;
    signal error_flag    : std_logic;

    -- Clock generation process
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- DUT instantiation
    uut: spacewire_rx_controller
        port map (
            clk           => clk,
            reset_n       => reset_n,
            fifo_rx_data  => fifo_rx_data,
            fifo_rx_empty => fifo_rx_empty,
            fifo_rx_read  => fifo_rx_read,
            rx_data_out   => rx_data_out,
            rx_data_valid => rx_data_valid,
            rx_eop        => rx_eop,
            rx_eep        => rx_eep,
            irq_rx        => irq_rx,
            error_flag    => error_flag
        );

    -- Stimulus process
    stimulus_process : process
    begin
        -- Initialize reset
        reset_n <= '0';
        wait for 20 ns;
        reset_n <= '1';
        wait for 20 ns;
        
        -- Simulate FIFO containing 2048 words, sending valid data and errors
        fifo_rx_empty <= '0'; -- FIFO has data
        
        -- Simulate a series of valid data
        for i in 0 to 10 loop
            fifo_rx_data <= std_logic_vector(to_unsigned(i, 10));
            wait for 10 ns;
        end loop;

        -- Simulate End of Packet (EOP)
        fifo_rx_data <= "0000000101"; -- Set EOP bit
        wait for 10 ns;

        -- Simulate error (EEP)
        fifo_rx_data <= "0000001001"; -- Set EEP bit
        wait for 10 ns;

        -- Mark FIFO as empty
        fifo_rx_empty <= '1';
        wait for 100 ns;

        -- End simulation
        wait;
    end process;

end architecture testbench;
