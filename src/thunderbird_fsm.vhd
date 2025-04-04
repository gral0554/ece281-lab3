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
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 One-Hot State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 1 0 0 0 0 0 0 0
--|                  ON    | 0 1 0 0 0 0 0 0
--|                  R1    | 0 0 1 0 0 0 0 0
--|                  R2    | 0 0 0 1 0 0 0 0
--|                  R3    | 0 0 0 0 1 0 0 0
--|                  L1    | 0 0 0 0 0 1 0 0
--|                  L2    | 0 0 0 0 0 0 1 0
--|                  L3    | 0 0 0 0 0 0 0 1
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
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
 
entity thunderbird_fsm is
    port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
    );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 

-- CONSTANTS ------------------------------------------------------------------
    type state_label is (OFF, L1, L2, L3, R1, R2, R3, HAZARD);
    signal current_state, next_state : state_label;
begin

	-- CONCURRENT STATEMENTS --------------------------------------------------------	
	    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                current_state <= OFF;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
        -- Next State Logic
    process(current_state, i_left, i_right)
    begin
        case current_state is
            when OFF =>
                if i_left = '1' and i_right = '1' then
                    next_state <= HAZARD;
                elsif i_left = '1' then
                    next_state <= L1;
                elsif i_right = '1' then
                    next_state <= R1;
                else
                    next_state <= OFF;
                end if;

            when L1 =>
                next_state <= L2;
            when L2 =>
                next_state <= L3;
            when L3 =>
                if i_left = '1' and i_right = '1' then
                    next_state <= HAZARD;
                elsif i_left = '1' then
                    next_state <= L1;
                else
                    next_state <= OFF;
                end if;

            when R1 =>
                next_state <= R2;
            when R2 =>
                next_state <= R3;
            when R3 =>
                if i_left = '1' and i_right = '1' then
                    next_state <= HAZARD;
                elsif i_right = '1' then
                    next_state <= R1;
                else
                    next_state <= OFF;
                end if;

            when HAZARD =>
                next_state <= OFF;
        end case;
    end process;

    -- Output Logic
    process(current_state)
    begin
        o_lights_L <= "000";
        o_lights_R <= "000";

        case current_state is
            when L1 =>
                o_lights_L <= "001"; -- LA
            when L2 =>
                o_lights_L <= "011"; -- LA + LB
            when L3 =>
                o_lights_L <= "111"; -- LA + LB + LC

            when R1 =>
                o_lights_R <= "100"; -- RA
            when R2 =>
                o_lights_R <= "110"; -- RA + RB
            when R3 =>
                o_lights_R <= "111"; -- RA + RB + RC

            when HAZARD =>
                o_lights_L <= "111";
                o_lights_R <= "111";

            when others =>
                o_lights_L <= "000";
                o_lights_R <= "000";
        end case;
    end process;
	-----------------------------------------------------					   
				  
end thunderbird_fsm_arch;