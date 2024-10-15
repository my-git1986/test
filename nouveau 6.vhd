library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spacewire_rx_controller is
    port (
        clk               : in  std_logic;             -- Horloge du système
        reset_n           : in  std_logic;             -- Reset actif bas
        fifo_rx_data      : in  std_logic_vector(9 downto 0);  -- Données reçues (8 bits + EOP + EEP)
        fifo_rx_empty     : in  std_logic;             -- Signal indiquant si le FIFO RX est vide
        fifo_rx_read      : out std_logic;             -- Commande pour lire le FIFO RX
        rx_data_out       : out std_logic_vector(7 downto 0);  -- Données utilisateur extraites
        rx_data_valid     : out std_logic;             -- Indique que les données sont valides
        rx_eop            : out std_logic;             -- Indique la fin du paquet
        rx_eep            : out std_logic;             -- Indique une erreur à la fin du paquet
        irq_rx            : out std_logic;             -- Interruption de réception
        error_flag        : out std_logic              -- Indicateur d'erreur de réception
    );
end entity spacewire_rx_controller;

architecture Behavioral of spacewire_rx_controller is
    type fsm_state is (IDLE, READ_FIFO, PROCESS_DATA, ERROR);
    signal state         : fsm_state := IDLE;
    signal next_state    : fsm_state;
    signal error_detected : std_logic := '0';
    
    -- Timeout signal (optional for more advanced flow control)
    signal timeout_counter : unsigned(15 downto 0) := (others => '0');
    constant TIMEOUT_MAX : unsigned(15 downto 0) := x"FFFF";

    -- Signals for status register monitoring
    signal link_status   : std_logic := '0';           -- To monitor link RUN status
    signal fct_received  : std_logic := '0';           -- Flow Control Token received
    signal null_received : std_logic := '0';           -- Null character received

begin

    -- Processus principal de la FSM pour gérer la réception des données SpaceWire
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
            fifo_rx_read <= '0';
            rx_data_out <= (others => '0');
            rx_data_valid <= '0';
            rx_eop <= '0';
            rx_eep <= '0';
            error_detected <= '0';
            error_flag <= '0';
            irq_rx <= '0';
        elsif rising_edge(clk) then
            -- Gestion de l'état suivant
            state <= next_state;

            case state is
                when IDLE =>
                    -- Attendre des données dans le FIFO RX ou gérer les interruptions
                    fifo_rx_read <= '0';
                    rx_data_valid <= '0';
                    rx_eop <= '0';
                    rx_eep <= '0';
                    irq_rx <= '0';

                    if fifo_rx_empty = '0' then
                        next_state <= READ_FIFO;
                    else
                        next_state <= IDLE;
                    end if;

                when READ_FIFO =>
                    -- Lire les données depuis le FIFO RX et vérifier le statut
                    fifo_rx_read <= '1';
                    next_state <= PROCESS_DATA;

                when PROCESS_DATA =>
                    -- Traiter les données et vérifier les bits de contrôle EOP/EEP
                    fifo_rx_read <= '0';
                    rx_data_out <= fifo_rx_data(7 downto 0);  -- Extraction des 8 bits de données
                    rx_data_valid <= '1';  -- Données valides

                    -- Vérification des bits de contrôle (EOP, EEP)
                    if fifo_rx_data(8) = '1' then
                        rx_eop <= '1';  -- Fin du paquet
                    else
                        rx_eop <= '0';
                    end if;

                    if fifo_rx_data(9) = '1' then
                        rx_eep <= '1';  -- Erreur à la fin du paquet
                        error_detected <= '1';
                        next_state <= ERROR;  -- Gestion de l'erreur
                    else
                        rx_eep <= '0';
                        next_state <= IDLE;
                    end if;

                when ERROR =>
                    -- Gestion des erreurs : marquer le flag d'erreur et déclencher une interruption
                    error_flag <= '1';
                    irq_rx <= '1';  -- Déclenche une interruption de réception en cas d'erreur
                    next_state <= IDLE;  -- Revenir à l'état IDLE après l'erreur

            end case;
        end if;
    end process;

    -- Gestion d'un timeout pour détecter des problèmes sur le lien SpaceWire
    process(clk)
    begin
        if rising_edge(clk) then
            if state = IDLE or state = READ_FIFO then
                if timeout_counter < TIMEOUT_MAX then
                    timeout_counter <= timeout_counter + 1;
                else
                    error_flag <= '1';  -- Timeout atteint, lever un flag d'erreur
                end if;
            else
                timeout_counter <= (others => '0');  -- Réinitialisation du compteur
            end if;
        end if;
    end process;

end architecture Behavioral;
