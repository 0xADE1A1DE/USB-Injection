----------------------------------------------------------------------------------
-- Company: UoA/DSTG
-- Engineer: Robbie Dumitru
-- 
-- Design Name: USB Test Bench
-- Module Name: tbusb - Behavioral
-- Project Name: USB injection
-- Target Devices: Basys 3
-- Tool Versions: Vivado 2020.1
-- Description: Test bench made for testing and debugging self-contained USB HID core created by Johns Hopkins University
--              ECE department. 
-- 
-- Additional Comments: This test bench helped identify and fix the following two bugs:
--                          -   Interpretation of the 8-bit start-of-packet (SOP) synchronisation transmission sequence
--                              would occasionally begin 2 bits late, causing a 2 bit offset resulting in nonsensical
--                              decoding of all subsequent transmission bits for that packet.
--                          -   No insertion of stuff bit in cyclic redundancy check (CRC) portion of transmissions,
--                              causing rare transmissions errors
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;


entity USB_Demo_tb is
end;

architecture bench of USB_Demo_tb is

  component USB_Demo
    port(
      clk100 : in  std_logic;
      reset    : in  std_logic;
      dplus  : inout std_logic;
      dminus : inout std_logic
      );
  end component;

  signal clk100: std_logic;
  signal reset: std_logic;
  signal dplus: std_logic;
  signal dminus: std_logic ;

  constant clk_period : time := 10ns;
  constant bit_period_times3 : time := 2000ns;

begin

  uut: USB_Demo port map ( clk100 => clk100,
                           reset    => reset,
                           dplus  => dplus,
                           dminus => dminus );

clk_process: process
begin
    clk100 <= '0';
    wait for clk_period/2;
    clk100 <= '1';
    wait for clk_period/2;
end process;

  stimulus: process
  begin
  reset <= '0';

    dminus <= '1';  -- connected idle state - 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- reset - SE0 state
    dplus <= '0';
    wait for 10ms;
    dminus <= '1';  -- connected idle state - 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    
    -- SYNC start of packet
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    
    -- transmit 1st packet data: NRZI encoding of SETUP 0x2d 0x00 0x10
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
     dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
     dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
     dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
     dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
     dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- LS EOP SE0 state for two bit periods
    dplus <= '0';
    wait for 2*bit_period_times3/3;
    dminus <= '1';  -- connected idle state - 'J' state
    dplus <= '0';
    wait for 2*bit_period_times3/3;
    
    -- SYNC start of packet
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    
    -- transmit 2nd packet data: nrzi encoding of DATA 0x2d 0x00 0x10 0xc3 0x80 0x06 0x00 0x01 0x00 0x00 0x40 0x00 0xdd 0x94
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;

    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- LS EOP SE0 state for two bit periods
    dplus <= '0';
    wait for 2*bit_period_times3/3;
    dminus <= '1';  -- connected idle state - 'J' state
    dplus <= '0';   -- wait here for device response
    wait for bit_period_times3/3;
    dminus <= 'Z';
    dplus <= 'Z';
    
    wait for 29*bit_period_times3/3; -- Send first IN
    -- SYNC start of packet
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    
    -- IN transaction data
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- LS EOP SE0 state for two bit periods
    dplus <= '0';
    wait for 2*bit_period_times3/3;
    dminus <= '1';  -- connected idle state - 'J' state
    dplus <= '0';   -- wait here for device response
    wait for bit_period_times3/3;
    dminus <= 'Z';
    dplus <= 'Z';
    
    --wait for 69332ns;
    wait for 106*bit_period_times3/3;
    
    -- SYNC start of packet
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    
    -- ACK data
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- LS EOP SE0 state for two bit periods
    dplus <= '0';
    wait for 2*bit_period_times3/3;
    dminus <= '1';  -- connected idle state - 'J' state
    dplus <= '0';   -- wait here for device response
    wait for bit_period_times3/3;
    dminus <= 'Z';
    dplus <= 'Z';
    wait for 2*bit_period_times3/3;
    
-- Send second in
    -- SYNC start of packet
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state for start of packet sync
    dplus <= '1';
    wait for bit_period_times3/3;
    
    -- IN transaction data
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    dminus <= '0';  -- 'K' state
    dplus <= '1';
    wait for bit_period_times3/3;
    dminus <= '1';  -- 'J' state
    dplus <= '0';
    wait for bit_period_times3/3;
    
    dminus <= '0';  -- LS EOP SE0 state for two bit periods
    dplus <= '0';
    wait for 2*bit_period_times3/3;
    dminus <= '1';  -- connected idle state - 'J' state
    dplus <= '0';   -- wait here for device response
    wait for bit_period_times3/3;
    dminus <= 'Z';
    dplus <= 'Z';
    
    wait for 1ms;
    dminus <= '0';  -- keep alive - LS EOP SE0 state for two bit periods
    dplus <= '0';
    wait for 2*bit_period_times3/3;
    dminus <= '1';  -- connected idle state - 'J' state
    dplus <= '0';   -- wait here for device response

    wait;
  end process;

end;
  