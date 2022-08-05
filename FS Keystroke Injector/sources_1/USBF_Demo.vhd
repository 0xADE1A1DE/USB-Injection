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
    inclkp  : in std_logic; 
    inclkn  : in std_logic;
    --clk100 : in  std_logic;  --100 MHz clock for the sdram interface DLL
    reset    : in  std_logic;  -- switch
    sw2     : in    std_logic; -- onebutton
    btnC    : in    std_logic;
    btnD    : in    std_logic;
    btnU    : in    std_logic;
    btnL    : in    std_logic;
    btnR    : in    std_logic;
    inj     : in    std_logic;
    DOSswitch: in   std_logic;
    ----USB CONNECTIONS (with one 1.5K pull up to 3.3v)  ---------------
    dplus  : inout std_logic;   --D+ data line , pin D16   -- rxd change pins
    dminus : inout std_logic    --D- data line, pin E14
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
  signal started : std_logic := '0';
  signal flipper : std_logic := '0';
  signal clk100Ms: std_logic;
-----------------------------------------------

begin

--===============================================
-- Main USB interface Component.
  UUSB : USBF_IFC
    port map(
      --clk100M     => synced100M,        --synced 100MHz master clock from DRAM DLL
      clk100M=>       clk100Ms,         -- external 100MHz master clock
      reset       => reset,            -- XST reset push button
      PCIn        => PCIn,              --data array to PC host 
      PCOut       => PCOut,             --data array from PC host
      new_dat     => new_dat,           --pulses high when new data packet arrives
      rd_req      => rd_req,            --pulses high when new read packet starts
      mode        => mode,              --mode byte received by set_feature packet.
      ----USB CONNECTIONS               ---------
      dplus       => dplus,             --differential data
      dminus      => dminus,
      inj         => inj, 
      DOSswitch   => DOSswitch,
      ----------------------------
      config_done => config_done
      );
--=============================================
--When a read is performed by the PC, the values in array PCInput are sent in a packet.
--When a write is performed by the PC, the array PCOutput latches the data until the next write.

-- Used differential clock pins in this design
    clk_wiz_inst : clk_wiz_0
        port map(
            clk_in1_p => inclkp,
            clk_in1_n => inclkn, 
            clk_out1 => clk100Ms
        );


  PCIn             <= windows_key when (btnL = '1' and btnR = '0') else
                      windows_key_and_r when (btnL = '1' and btnR = '1') else--no_buttons when sw2 = '0' else dummy_input;  --mode=2 is mem read mode
                      letter_c when (btnU = '1') else
                      letter_m when (btnC = '1') else
                      letter_d when (btnD = '1') else
                      enter_key when (btnL = '0' and btnR = '1') else
                      no_buttons;

---- Code left behind from attempt to automate payload keystroke typing sequence (unsuccessfully)
--
--   process(clk100) is
--   variable counter : integer range 0 to 100000000;
--   begin
--    if rising_edge(clk100) then
--        counter := counter + 1;
        
--        if (counter = 100000000) then
--            flipper <= not flipper;
--        end if;
--    end if;
--   end process;
   
--   process(flipper) is
--   variable TMP : integer := 0;
--   begin
--   if rising_edge(flipper) then
--    if (btnC = '1' and started = '0') then
--        started <= '1';
--        PCIn <= windows_key;
--    end if;
--    if (started = '1') then
--        case TMP is
--            when 0 =>
--                PCIn <= no_buttons;
--                TMP := TMP + 1;
--            when 1 =>
--                PCIn <= windows_key_and_r;
--                TMP := TMP + 1;
--            when 2 =>
--                PCIn <= no_buttons;
--                TMP := TMP + 1;
--            when 3 =>
--                PCIn <= letter_c;
--                TMP := TMP + 1;
--            when 4 =>
--                PCIn <= no_buttons;
--                TMP := TMP + 1;
--            when 5 =>
--                PCIn <= letter_m;
--                TMP := TMP + 1;
--            when 6 =>
--                PCIn <= no_buttons;
--                TMP := TMP + 1;
--            when 7 =>
--                PCIn <= letter_d;
--                TMP := TMP + 1;
--            when 8 =>
--                PCIn <= no_buttons;
--                TMP := TMP + 1;
--            when 9 =>
--                PCIn <= enter_key;
--                TMP := TMP + 1;
--            when 10 =>
--                PCIn <= no_buttons;
--                started <= '0';
--                TMP := 0;
--            when others => null;
--        end case;
--    end if;
--   end if;
--   end process;
                      
end arch;
