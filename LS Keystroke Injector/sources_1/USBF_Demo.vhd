--==============================================================================
--Copywrite Johns Hopkins University ECE department
--This software may be freely used and modified as long as this header is retained. 
------------------------------------------------------------------
--Component USBF_IFC Implements USB enumeration and communication exchanges with
--  the usb port through the USB_DRVR traneciver component.  
--Project reset is held until interface indicates configuration done.
--==============================================================================
-- USB Injection
-- Injection platform top level module
--==============================================================================
-- This module ties keyboard report packets to buttons on the FPGA dev board
-- Modified by: Robbie Dumitru 
--==============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.USBF_Declares.all;             --constants and user type declarations for USB_IFC

----------------------------------------------------------------------
entity USB_Demo is
  port(
    clk100 : in  std_logic;     --100 MHz clock for the sdram interface DLL
    reset    : in  std_logic;   -- switch
    sw2     : in    std_logic;
    btnC    : in    std_logic;
    btnD    : in    std_logic;
    btnU    : in    std_logic;
    btnL    : in    std_logic;
    btnR    : in    std_logic;
    inj     : in    std_logic;
    DOSswitch: in   std_logic;
    ----USB CONNECTIONS (with one 1.5K pull up to 3.3v)  ---------------
    dplus  : inout std_logic;   --D+ data line   -- rxd changed pins
    dminus : inout std_logic    --D- data line
    );
end USB_Demo;
----------------------------------------------------------------------

architecture arch of USB_Demo is

-- USB signals                          -----------------------------
  signal new_dat     : std_logic;       -- USB new data flag
  signal rd_req      : std_logic;       -- USB read request flag
  signal mode        : std_logic_vector(7 downto 0);  -- USB set_feature data byte
  signal PCIn        : EIGHT_BYTES;     --Input to USB interface component for sending to PC host
  signal PCOut       : EIGHT_BYTES;     --Input from PC is output from USB interface
--PKT_BYTES and EIGTH_BYTES are identical arrays in this version of the USB interface
  signal config_done : std_logic;
--  signal reset_done  : std_logic;
  
-----------------------------------------------

begin

--===============================================
-- Main USB interface Component.
  UUSB : USBF_IFC
    port map(
      clk100M=>       clk100,           -- external 100MHz master clock
      reset       => reset,             -- reset switch
      PCIn        => PCIn,              --data array to PC host 
      PCOut       => PCOut,             --data array from PC host
      new_dat     => new_dat,           --pulses high when new data packet arrives
      rd_req      => rd_req,            --pulses high when new read packet starts
      mode        => mode,              --mode byte received by set_feature packet.
      ----USB CONNECTIONS               ---------
      dplus       => dplus,             --differential data
      dminus      => dminus,
      ----Injector states
      inj         => inj,               --switch packet injection, will feed 0-filled packets if left on
      DOSswitch   => DOSswitch,         --switch injecting DATA packets and NAKs
      ----------------------------
      config_done => config_done
      );
--=============================================
--When a read is performed by the PC, the values in array PCInput are sent in a packet.
--When a write is performed by the PC, the array PCOutput latches the data until the next write.

  PCIn             <= windows_key when (btnL = '1' and btnR = '0') else
                      windows_key_and_r when (btnL = '1' and btnR = '1') else 
                      letter_c when (btnU = '1') else
                      letter_m when (btnC = '1') else
                      letter_d when (btnD = '1') else
                      enter_key when (btnL = '0' and btnR = '1') else
                      no_buttons; 
                      
end arch;
