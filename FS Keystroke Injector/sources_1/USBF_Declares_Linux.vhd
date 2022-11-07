--==============================================================================
--  USB Interface Declares
------------------------------------------------------------------
--Copywrite Johns Hopkins University ECE department
--This software may be freely used and modified as long as this header is retained. 
------------------------------------------------------------------
--Description: Defines constants and components used to make the FPGA act as a 
--  HID USB peripheral, and communicate over the D+/D- lines with the host.
--   
-- Authors: Brian Duddie, Brian Miller, R.E. Jenkins
-- Last Modification: Jan 3, 2009
--==============================================================================
-- USB Injection
-- Modified by: Robbie Dumitru 
-- Modifications marked with --rxd
--==============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--==================================================================
package USBF_Declares is
--==================================================================

--==================================================================
-- Constants used by tranceiver component
--==================================================================
  constant SYNC      : std_logic_vector(8 downto 1) := "10000000";
  constant ACK_PID   : std_logic_vector(4 downto 1) := "0010";
  constant STALL_PID : std_logic_vector(4 downto 1) := "1110";
  constant NAK_PID   : std_logic_vector(4 downto 1) := "1010";
  constant IN_PID    : std_logic_vector(4 downto 1) := "1001";
  ---D+/D- values for K and J states. Comment out one of the KP defs
  constant KP: std_logic:= '1';       --low speed K state for D+. 
  --constant KP        : std_logic                    := '0';  --full speed K state for D+
  constant KM        : std_logic                    := not KP;  --K state for D-
  constant JP        : std_logic                    := KM;  --J state for D+
  constant JM        : std_logic                    := KP;  --J state for D-

--  constant SETUP_PID : std_logic_vector(4 downto 1):= "1101";
--==================================================================
--USB ENUMERATION/CONTROL TRANSFER CONSTANTS
--==================================================================
-- Setup packet bmRequestType values: Standard requests
  constant USB_STD_DEVICE_REQUEST    : std_logic_vector(7 downto 0) := x"00";
  constant USB_STD_INTERFACE_REQUEST : std_logic_vector(7 downto 0) := x"01";
  constant USB_STD_ENDPOINT_REQUEST  : std_logic_vector(7 downto 0) := x"02";

-- bmRequestType: Class-specific requests (HID specific for our implementation)
  constant USB_CLASS_DEVICE_REQUEST    : std_logic_vector(7 downto 0) := x"20";
  constant USB_CLASS_INTERFACE_REQUEST : std_logic_vector(7 downto 0) := x"21";
  constant USB_CLASS_ENDPOINT_REQUEST  : std_logic_vector(7 downto 0) := x"22";

-- The following aren't used in the current implementation but are defined here
-- for completeness
-- bmRequestType: Vendor-specific requests (HID specific for our implementation)
  constant USB_VENDOR_DEVICE_REQUEST    : std_logic_vector(7 downto 0) := x"40";
  constant USB_VENDOR_INTERFACE_REQUEST : std_logic_vector(7 downto 0) := x"41";
  constant USB_VENDOR_ENDPOINT_REQUEST  : std_logic_vector(7 downto 0) := x"42";

-- Request type constants (defined in wValue)
  constant USB_TYPE_DEVICE_DESCRIPTOR    : std_logic_vector(7 downto 0) := x"01";
  constant USB_TYPE_CONFIG_DESCRIPTOR    : std_logic_vector(7 downto 0) := x"02";
  constant USB_TYPE_STRING_DESCRIPTOR    : std_logic_vector(7 downto 0) := x"03";
  constant USB_TYPE_INTERFACE_DESCRIPTOR : std_logic_vector(7 downto 0) := x"04";
  constant USB_TYPE_ENDPOINT_DESCRIPTOR  : std_logic_vector(7 downto 0) := x"05";
  constant USB_TYPE_HID_DESCRIPTOR       : std_logic_vector(7 downto 0) := x"21";

-- Sub request values (defined in bRequest)
  constant USB_GET_STATUS     : std_logic_vector(7 downto 0) := x"00";
  constant USB_CLEAR_FEATURE  : std_logic_vector(7 downto 0) := x"01";
  constant USB_SET_FEATURE    : std_logic_vector(7 downto 0) := x"03";
  constant USB_SET_ADDRESS    : std_logic_vector(7 downto 0) := x"05";
  constant USB_GET_DESCRIPTOR : std_logic_vector(7 downto 0) := x"06";
  constant USB_SET_DESCRIPTOR : std_logic_vector(7 downto 0) := x"07";
  constant USB_GET_CONFIG     : std_logic_vector(7 downto 0) := x"08";
  constant USB_SET_CONFIG     : std_logic_vector(7 downto 0) := x"09";
  constant USB_GET_INTERFACE  : std_logic_vector(7 downto 0) := x"0A";
  constant USB_SET_INTERFACE  : std_logic_vector(7 downto 0) := x"0B";
  constant USB_SYNC_FRAME     : std_logic_vector(7 downto 0) := x"0C";

-- HID class-specific bRequest values (i.e. bmRequestType = USB_CLASS_*)
  constant USB_HID_GET_REPORT : std_logic_vector(7 downto 0) := x"01";
  constant USB_HID_SET_REPORT : std_logic_vector(7 downto 0) := x"09";
  constant USB_HID_SET_IDLE   : std_logic_vector(7 downto 0) := x"0A";


--====================================================================
--USB DESCRIPTOR CONSTANTS (FOR ENUMERATION)  --------------------------
--====================================================================
-- User defined types (tranceiver's maximum data packet size is 8 or 64 bytes)
  constant PKTSIZE         : integer                := 8;  --size in bytes of a data pkt(8 or up to 64 for full speed);
--upper bounds on bit and byte counts
  constant BYTEMAX         : integer                := 68;  --upper bound on data byte counts -- rxd 65 to 68
--max data bits ever sent or rcvd in one pkt (data+16crc+1possible-dribble).
  constant BITMAX          : integer                := 8*BYTEMAX+17; 
                             type EIGHT_BYTES is array (1 to 8) of std_logic_vector(7 downto 0); 
--type PKT_BYTES is array (1 to PKTSIZE) of std_logic_vector(7 downto 0);
                                             type DEVICE_DESC_TYPE is array (1 to 3) of EIGHT_BYTES;
  type CONFIGURATION_DESC_TYPE is array (1 to 9) of EIGHT_BYTES;
  type HID_REPORT_TYPE is array (1 to 7) of EIGHT_BYTES;
  type STRING_DESC_TYPE is array (1 to 4) of EIGHT_BYTES;
----------------------------------------------------------------------
-- Device Descriptor (see pg 324 for example of most descriptors)
-- NOTE: multi-byte fields (i.e. release spec number) are little endian
-- (most significant byte last)
----------------------------------------------------------------------
  constant DEVICE_DESC     : DEVICE_DESC_TYPE       := (
    (x"12",                             -- descriptor size (18 bytes)
     USB_TYPE_DEVICE_DESCRIPTOR,
     x"10", x"01",                      -- USB spec release number (BCD, 0x0110 = USB 1.1)
     x"00",                             -- device class code (unspecified - detailed in interface descriptor)
     x"00",                             -- device subclass (none)
     x"00",                             -- device protocol (none)
     x"08"),                            -- max packet size (8 bytes)***************
    (x"22", x"11",                      -- vendor ID  (0925)
     x"22", x"11",                      -- product ID (1234)
     x"11", x"01",                      -- BCD device release # (0.01) 5.55 is FPGA special    
     x"01",                             -- manufacturer string index (0 = no string descriptor)
     x"00"),                            -- product string index
    (x"00",                             -- serial number string index
     x"01",                             -- number of configurations (minimum = 1)
     x"00", x"00", x"00", x"00", x"00", x"00")  -- padding to 3 packets
    );
  constant DEVICE_DESC_LEN : integer range 0 to 255 := 18;

constant dummy_input : EIGHT_BYTES := ("00000000", "00000000", "00001011", "00000000", "00000000", "00000000", "00000000", "00000000"); -- letter h
constant no_buttons : EIGHT_BYTES := ("00000000", "00000000", "00000000", "00000000", "00000000", "00000000", "00000000", "00000000"); -- all unpressed
constant letter_c : EIGHT_BYTES :=("00000000", "00000000", "00000110", "00000000", "00000000", "00000000", "00000000", "00000000");
constant letter_d : EIGHT_BYTES :=("00000000", "00000000", "00000111", "00000000", "00000000", "00000000", "00000000", "00000000");
constant letter_m : EIGHT_BYTES :=("00000000", "00000000", "00010000", "00000000", "00000000", "00000000", "00000000", "00000000");
constant enter_key : EIGHT_BYTES :=("00000000", "00000000", "01011000", "00000000", "00000000", "00000000", "00000000", "00000000");
constant windows_key : EIGHT_BYTES :=("00001000", "00000000", "00000000", "00000000", "00000000", "00000000", "00000000", "00000000");
constant windows_key_and_r : EIGHT_BYTES :=("00001000", "00000000", "00000000", "00010101", "00000000", "00000000", "00000000", "00000000");
---------------------------------------------------------------------------
-- Configuration Descriptor (pg 102)
-- This descriptor has several sub-descriptors in a specific order, including
-- an interface descriptor, HID class-specific descriptor, and two endpoint
-- descriptors
---------------------------------------------------------------------------
  constant CONFIGURATION_DESC : CONFIGURATION_DESC_TYPE := (  --see pg 101
    (x"09",                             -- descriptor header size (9 bytes)
     USB_TYPE_CONFIG_DESCRIPTOR,        --02h
     x"22", x"00",                      -- total size (0x29 = 41 bytes)
     x"01",                             -- number of interfaces
     x"01",                             -- configuration ID
     x"00",                             -- index of string descriptor (0 = none) 6 to e
     x"E0"),                            -- bmAttributes = self powered, remote wake up supported (see pg102) rob changed to self powered
    (x"08",                             -- 1/2 max power draw (100mA = 2x50)

     -- Interface descriptor (see pg 106, 324 for HID specific)
     x"09",                             -- descriptor size (9 bytes)
     USB_TYPE_INTERFACE_DESCRIPTOR,     --04h
     x"00",                             -- interface number
     x"00",                             -- alternate setting
     x"01",  -- number of endpoints     --number IN ADDITION TO EP0. Must be 02 for EP1 IN and OUT
     x"03",                             -- interface class (HID=03h)
     x"01"),                            -- interface subclass
    --(x"02",                             -- interface protocol
    (x"01",                             -- interface protocol
     x"00",                             -- interface string index

     -- HID Class Descriptor (extension to interface descriptor)(pg325)
     x"09",                             -- descriptor size (9 bytes)
     x"21",                             -- descriptor type (HID)
     x"10", x"01",                      -- HID Spec release number (1.1)
     x"00",                             -- country code
     x"01"),                            -- number of subordinate class descriptors. Min for HID is a report descriptor
    (x"22",                             -- subordinate descriptor type (report)
    
    x"44", x"00",
     --x"34", x"00", 
     --x"41", x"00",                      -- report descriptor size in bytes (0x2F = 47 bytes)

     -- Endpoint 1 interrupt IN descriptor (pg 110-111, 325)
     x"07",                             -- descriptor size
     USB_TYPE_ENDPOINT_DESCRIPTOR,      --05h
     x"81",                             -- endpoint address EP1IN (direction = MSB: 81=to host, EP1)
     x"03",                             -- bmAttributes: transfer type = interrupt(03) or control(00)
     x"08"), (x"00",                    -- max packet size (8 bytes)
             x"0A",                     --bInterval = polling interval = 10 ms

    x"00", x"00", x"00", x"00", x"00", x"00"),
    (x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00"), (x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00"), (x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00"),
    (x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00") -- padding to 9 packets
    );
  constant CONFIG_DESC_LEN : integer range 0 to 255 := 34;

---------------------------------------------------------------------------
-- HID Report Descriptor (pg 328-329, also see pg 361-363)
-- Details the specifications of our reports. Entries in this descriptor are
-- at least 2 bytes: first byte tells what type of entry is to follow and
-- next 1+ bytes are the value for that entry.
---------------------------------------------------------------------------
  constant HID_REPORT_DESC : HID_REPORT_TYPE := (
    ((x"05", x"01",        -- Usage Page: Generic Desktop
      x"09", x"02",        -- Usage: Mouse (2)
--        x"09", x"06",       -- Usage: Keyboard
      x"a1", x"01",       -- Collection: Application
      x"09", x"01"),         -- Usage: Pointer (1)
    (x"A1", x"00",          --Collection: Physical
    x"05", x"09",          --  Usage Page: Button (9)
    x"19", x"01",          --  Usage Minimum: Button 1
    x"29", x"03"),          --  Usage Maximum: Button 3
    (x"15", x"00",          --  Logical Minimum: 0
    x"25", x"01",          --  Logical Maximum: 1
    x"95", x"03",          --  Report Count: 3
    x"75", x"01"),          --  Report Size: 1
    (x"81", x"02",          --  Input: Data (2)
    x"95", x"01",          --  Report Count: 1
    x"75", x"05",          --  Report Size: 5
    x"81", x"01"),          --  Input: Constant (1)
    (x"05", x"01",          --  Usage Page: Generic Desktop Controls 
    x"09", x"30",           -- Usage: X
    x"09", x"31",          --  Usage: Y
    x"09", x"38"),          --  Usage: Wheel
    (x"15", x"81",          --  Logical Minimum: -127
    x"25", x"7f",          --  Logical Maximum: 127
    x"75", x"08",           -- Report Size: 8
    x"95", x"03"),          --  Report Count: 3
    (x"81", x"06",          --  Input: Data (6)
    x"C0",                --End collection
    x"C0",               --End collection
--      x"05", x"07"),       -- Usage Page: Keyboard
--      (x"19", x"e0",       -- Usage Minimum: Keyboard LeftControl
--      x"29", x"e7",       -- Usage Maximum: Keyboard Right GUI
--      x"15", x"00",       -- Logical Minimum: 0
--      x"25", x"01"),       -- Logical Maximum: 1
--      (x"75", x"01",       -- Report Size: 1
--      x"95", x"08",       -- Report Count: 8
--      x"81", x"02",       -- Input: Data (2)
--      x"95", x"01"),       -- Report Count: 1
--      (x"75", x"08",       -- Report Size: 8
--      x"81", x"01",       -- Input: Constant (1)
--      x"95", x"03",       -- Report Count: 3 
--      x"75", x"01"),       -- Report Size: 1
--      (x"05", x"08",       -- Usage Page: LEDs
--      x"19", x"01",       -- Usage Minimum: Num Lock
--      x"29", x"03",       -- Usage Maximum: Scroll Lock 
--      x"91", x"02"),       -- Output: Data (2)
--      (x"95", x"05",       -- Report Count: 5
--      x"75", x"01",       -- Report Size: 1
--      x"91", x"01",       -- Output: Constant (1)
--      x"95", x"06"),       -- Report Count: 6
--     (x"75", x"08",       -- Report Size: 8
--      x"15", x"00",       -- Logical Minimum: 0
--     x"26", x"ff", x"00",-- Logical Maximum: 255
--      x"05"), (x"07",       -- Usage Page: Keyboard/Keypad
--      x"19", x"00",       -- Usage Minimum: 0
--     x"2a", x"ff", x"00",-- Usage Maximum: 255
--      x"81", x"00"), (x"c0",-- Input: Data (0), end collection
--      x"00", x"00", x"00", x"00", x"00", x"00", x"00")) -- padded to 9 packets
    x"00", x"00", x"00", x"00")) -- padded to 7 packets
    );
    --(x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00"), -- padded to 9 packets
    --(x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00")) -- padded to 9 packets
    --);
--  constant HID_REPORT_DESC_LEN : integer range 0 to 127 := 65;
  constant HID_REPORT_DESC_LEN : integer range 0 to 127 := 68;

-----------------------------------------------------------------------
-- String Descriptors
-- These are not used in the current implementation, but can be defined by
-- setting the appropriate string descriptor index values in the descriptors
-- above, and adding some code in the USB state machine to handle
-- the requests for them. Note that string data uses Unicode.
-----------------------------------------------------------------------
-- Language ID descriptor is required if any string descriptors are defined
  constant LANGID_DESC     : EIGHT_BYTES          := (
    x"04",                              -- descriptor size
    USB_TYPE_STRING_DESCRIPTOR,
    x"04", x"09",                       -- language ID (US English)
    x"00", x"00", x"00", x"00"          -- padding to 8 bytes= 1 packet
    );
  constant LANGID_DESC_LEN : integer range 0 to 4 := 4;

-- Example string descriptor
  constant MANUFAC_STRING_DESC     : STRING_DESC_TYPE      := (
    (x"1E",                             -- size = 16 -> 7 unicode charactors
     USB_TYPE_STRING_DESCRIPTOR,
     x"52", x"00",                      -- R
     x"6F", x"00",                      -- o
     x"62", x"00"),                     -- b
    (X"27", X"00",                      -- '
     x"73", x"00",                      -- s
     x"20", x"00",                      -- 
     x"49", x"00"),                     -- I
     (x"6E", x"00",                     -- n
     x"6A", x"00",                      -- j
     x"65", x"00",                      -- e
     x"63", x"00"),                     -- c
     (x"74", x"00",                     -- t
     x"6F", x"00",                      -- o
     x"72", x"00",                      -- r
     x"00", x"00")        -- padded to 16 bytes = 2 pkts

    );
    constant MANUFAC_STRING_DESC_LEN : integer range 0 to 32 := 32; -- rxd 30 to 32
--  constant MANUFAC_STRING_DESC_LEN : integer range 0 to 16 := 16;
  
-- Example string descriptor
--  constant PROD_STRING_DESC     : STRING_DESC_TYPE      := (
--    (x"20",                             -- size = 16 -> 7 unicode charactors
--     USB_TYPE_STRING_DESCRIPTOR,
--     x"41", x"00",                      -- A
--     x"20", x"00",                      -- space
--     x"54", x"00"),                      -- T
--    (x"72", x"00",                     -- r
--     x"75", x"00",                      -- u
--     x"73", x"00",                      -- s
--     x"74", x"00"),                      -- t
--    (x"79", x"00",                      -- y
--     x"20", x"00",                      -- space
--     x"64", x"00",                      -- d
--     x"65", x"00"),                      -- e
--    (x"76", x"00",                      -- v
--     x"69", x"00",                      -- i
--     x"63", x"00",                      -- c
--     x"65", x"00")                      -- e
--    );
--  constant PROD_STRING_DESC_LEN : integer range 0 to 32 := 32;
------------------------------------------------------

-- The host may poll our device for its current status as a sort
-- of "ping" to make sure it is still alive.
  constant USB_STATUS      : EIGHT_BYTES := (  --1 packet
    x"00", x"01",                              -- remote wakeup & self-powered
    x"00", x"00", x"00", x"00", x"00", x"00"
    );
--CRC generator functions                      ----------------------------
  function NEW_CRC5(crc5   : std_logic_vector(5 downto 1); nxtbit : std_logic)
    return std_logic_vector;
  function NEW_CRC16(crc16 : std_logic_vector(16 downto 1); nxtbit : std_logic)
    return std_logic_vector;

--====================================================
--USB_DRVR COMPONENT Declaration        ----------------------
--====================================================
  component USB_DRVR is
                       port(
                         --debug:               out     std_logic_vector(50 downto 1);  --debug bits
                         clk100M       : in    std_logic;  --100MHz clock
                         inj           : in    std_logic;
                         DOSswitch     : in    std_logic;
                         reset         : in    std_logic;  --fpga reset
                         dminus        : inout std_logic;  -- USB differential D+ line
                         dplus         : inout std_logic;  -- USB differential D+ line
                         intr_reg      : out   std_logic_vector(6 downto 0);  -- interrupt register for interface
                         nakreq        : in    std_logic;  --active-hi signal to flag NAKs for interrupt IN requests
                         stallreq      : in    std_logic;  --signal from interface to flag the stall condition.
                         usb_addr      : in    std_logic_vector(6 downto 0);  -- USB assigned address 
                         bytes_to_send : in    integer range 0 to BYTEMAX;
                         send_buf      : in    EIGHT_BYTES;  -- outgoing data to send to PC
                         recv_buf      : out   EIGHT_BYTES  -- incoming data from PC
                         );
  end component;
-------------------------------------------------------
  component USBF_IFC is
                       port(
                         debug         : out   std_logic_vector(64 downto 51);  --*****DEBUG BIT
                         clk100M       : in    std_logic;  --100MHz clock
                         reset         : in    std_logic;  -- XST reset push button
                         inj           : in    std_logic;
                         DOSswitch     : in    std_logic;
                         --byte arrays for data exchanges with host.
                         PCIn          : in    EIGHT_BYTES;  --Input to interface and sent when host does a read.
                         PCOut         : out   EIGHT_BYTES;  --Received from host by device and output from interface.
                         rd_req        : out   std_logic;  --this pulses hi when a host read starts. 
                         new_dat       : out   std_logic;  --this pulses Hi when new data packet from PC arrives
                         mode          : out   std_logic_vector(7 downto 0);  --mode set by feature packet from host
                         ----USB CONNECTIONS  ---------
                         dplus         : inout std_logic;
                         dminus        : inout std_logic;
                         ----------------------------------
                         config_done   : out   std_logic
                         );
  end component;

--==============================================================================
END PACKAGE USBF_Declares;
--==============================================================================

--==============================================================================
PACKAGE BODY USBF_Declares is
----------------------
--Functions to update the crc reg based on the current bit received or sent
--We reverse the whole process so the final crc registers are reversed.
--This allows us to send them lsb first, which is the way everything else goes out.
-------------------------
  function NEW_CRC5(crc5: std_logic_vector(5 downto 1); 
                    nxtbit: std_logic) return std_logic_vector is
--We reverse the whole operation so the final crc can be sent lsb first
--constant CRC5GEN: std_logic_vector(16 downto 1):= x"00101";
    constant CRC5GEN: std_logic_vector(5 downto 1):= "10100"; --bit reversed generator
    variable bitxor: std_logic;

  begin
    bitxor:= nxtbit xor crc5(1);
    if bitxor = '1' then
      return (('0' & crc5(5 downto 2)) xor CRC5GEN);
    else
      return ('0' & crc5(5 downto 2));
    end if;

  end function NEW_CRC5;
-------------------------
  function NEW_CRC16(crc16: std_logic_vector(16 downto 1); 
                     nxtbit: std_logic) return std_logic_vector is
--We reverse the whole operation so the final crc can be sent lsb first
--constant CRC16GEN: std_logic_vector(16 downto 1):= x"8005";
    constant CRC16GEN: std_logic_vector(16 downto 1):= x"A001"; --bit-reversed generator
    variable bitxor: std_logic;

  begin
    bitxor:= nxtbit xor crc16(1);
    if bitxor = '1' then
      return (('0' & crc16(16 downto 2)) xor CRC16GEN);
    else
      return ('0' & crc16(16 downto 2));
    end if;

  end function NEW_CRC16;
----------------
END PACKAGE BODY USBF_Declares;
--==============================================================================
