--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	  port (
            i_clk      : in  std_logic;
            i_reset    : in  std_logic;
            i_left     : in  std_logic;
            i_right    : in  std_logic;
            o_lights_L : out std_logic_vector(2 downto 0);
            o_lights_R : out std_logic_vector(2 downto 0)
           );
	end component thunderbird_fsm;

	-- test I/O signals
	signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal left        : std_logic := '0';
    signal right       : std_logic := '0';
    signal lights_L    : std_logic_vector(2 downto 0);
    signal lights_R    : std_logic_vector(2 downto 0);
	-- constants
	constant clk_period : time := 10 ns;
	
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm
    port map (
        i_clk      => clk,
        i_reset    => reset,
        i_left     => left,
        i_right    => right,
        o_lights_L => lights_L,
        o_lights_R => lights_R
    );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	testing_process : process
    begin
        report "Starting simulation..." severity note;

        -- Apply reset
        reset <= '1';
        wait for 2 * clk_period;
        reset <= '0';
        wait for clk_period;

        -- LEFT signal test
        report "Testing LEFT turn signal" severity note;
        left <= '1';
        wait for 4 * clk_period;
        left <= '0';

        wait for 10 * clk_period;

        -- RIGHT signal test
        report "Testing RIGHT turn signal" severity note;
        right <= '1';
        wait for 4 * clk_period;
        right <= '0';

        wait for 10 * clk_period;

        -- Hazard lights test (both left and right)
        report "Testing HAZARD lights" severity note;
        left <= '1';
        right <= '1';
        wait for clk_period;
        left <= '0';
        right <= '0';

        wait for 10 * clk_period;

        -- Reset in middle of sequence
        report "Testing reset in middle of blinking sequence" severity note;
        left <= '1';
        wait for 2 * clk_period;
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        left <= '0';

        wait for 10 * clk_period;

        report "Testbench completed." severity note;
        wait;
    end process;
	-----------------------------------------------------	
	
end test_bench;
