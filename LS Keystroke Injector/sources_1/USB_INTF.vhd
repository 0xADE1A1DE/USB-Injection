-- This file contains 2 Entities making up an HID USB interface
--===========================================================================
-- USB Interface module - Copywrite Johns Hopkins University ECE Dept.
-- This code may be used and freely distributed as long as the JHU credit is retained.
--============================================================================
-- Implements an HID USB enumeration and communication through a tranceiver implemented
-- in the FPGA to directly drive the USB diferential pair data lines.
-- On an XESS xst-2 or -3 board this requires a connection of the usb cable wires with a 1.5K 
-- pullup to 3.3V on the D+ or D- line, and the data lines connecting to 2 FPGA pins.
-- The bit rate is determined by which line has the pullup.

-- The inputs and outputs are arrays(1 to 8) of std_logic_vector(7 downto 0).
-- These arrays are the data packets sent and received via USB reports. The I/O
-- buffers for USB transactions in the tranceiver are also 8 byte arrays.

-- The interface acts as an HID class, thus only control and interrupt xfers are possible.
-- Any commented page references are to "USB Complete", 3rd Edition, by Jan Axelson
--
-- Author: Robert Jenkins
-- Last Modification: Jan 30, 2009
--==============================================================================
-- USB Injection
-- Modified by: Robbie Dumitru 
-- Modifications marked with --rxd
--==============================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.USBF_Declares.all;             --Package containing declarations needed by the USB interface        

--------------------------------------------------------------------------------
entity USBF_IFC is
  port(
    debug       : out   std_logic_vector(64 downto 51);  --*****DEBUG can be left open
    clk100M     : in    std_logic;      --100MHz project clock
    reset       : in    std_logic;      -- usually tied to the XST reset button.
    ----Byte arrays and flag signals for data exchanges with host.  ----
    
    inj         : in    std_logic;      -- switch to enable injection input 
    DOSswitch   : in    std_logic;      -- switch to send NAKs instead of zero-filled packets
    
    PCIn        : in    EIGHT_BYTES;    --Input to interface and sent when host does a read.
    PCOut       : out   EIGHT_BYTES;    --Received by device and output from interface.
    rd_req      : out   std_logic;      --this pulses hi when a PC host read is active. 
    new_dat     : out   std_logic;      --this pulses Hi when new data packet from PC arrives
    mode        : out   std_logic_vector(7 downto 0);  --mode set by a feature packet from host
    ----USB CONNECTIONS                 -----------------------------------------
    dplus       : inout std_logic;      --differential + line to/from usb hub(pulled up to 3.3)
    dminus      : inout std_logic;      --differential minus line to/from usb hub
    ------------------------------------------------------------
    config_done : out   std_logic := '0'      --goes high when enumeration successfully completes
    );
end USBF_IFC;
----------------------------------------------------------------------

architecture arch of USBF_IFC is
--==================================
--USER-DEFINED TYPES
--==================================
-- USB state machine
  type usb_sm_type is (
    Wait_Irq,                           --idle state waiting for an interrupt by driver rxd cap I
    --hang,                             --this should never happen when things are debugged                             
    Setup_Pkt1, Wait_Clr,               --states for initializing setup or IN response data 
    Write_EP_1,                         --states for loading response pkts into send_buf
    Get_EP_Dat1, Get_EP_Dat2,           --states for retrieving OUT data pkts when they arrive
    Stall_1
    --set_feature, clear_feature
    );
-- Source of outgoing USB data
  type source_type is (
    dev_desc, cfg_desc, lang_desc, manufac_desc, status, dev_cfg, hid_desc, output_data
    );
--===================================
--SIGNALS. Many constants are defined in package USBF_Declares
--===================================
--  attribute INIT          : string;
--  signals directly connected to usb_DRVR component
  signal stallreq         : std_logic := '0';
  signal nakreq           : std_logic;  --stall request flag, nak request flag
  signal usb_addr         : std_logic_vector(6 downto 0) := "0000000";  --device address set during enumeration
  signal intr_reg         : std_logic_vector(6 downto 0);  --defines interrupts from tranceiver
--signal debug_drv          : std_logic_vector(50 downto 1);  --a debug vector from the tranceiver
  signal usb_send_buf     : EIGHT_BYTES;  --data bufs used by tranceiver for all EPs
  signal usb_recv_buf     : EIGHT_BYTES;

-- signals
  signal                               clk50M        : std_logic    :='0';
  signal                               usb_endpoint  : std_logic_vector(3 downto 0);
  signal                               is_feature    : std_logic;  --flag the set_feature data packet
  signal                               device_config : std_logic_vector(7 downto 0) := x"00";
  signal                               modeI         : std_logic_vector(7 downto 0) := x"00";  --internal mode from feature report
--signal RdPending:                     boolean;  --flag that a read report has been requested
  signal                               usb_state     : usb_sm_type := Wait_Irq; -- rxd: initialisation below wasn't working properly
--  attribute INIT of usb_state                        : signal is "Wait_Irq";  --start in wait state at powerup
  signal                               data_source   : source_type;

-- Bytes we are sending to the host during the data stage of a setup transaction
  signal total_bytes_to_send : integer range -BYTEMAX to BYTEMAX;  --total to send for the current setup
  signal remaining_bytes     : integer range -BYTEMAX to BYTEMAX;  --num left to send of the total
  signal bytes_to_send       : integer range 0 to BYTEMAX;  --num to send on next IN request
-- Eight byte index of data_source array (i.e. which 8-byte pkt we are sending next)
  signal send_8byte_index    : integer range 1 to BYTEMAX;

-- USB request/setup packet identifiers
  signal bmRequestType : std_logic_vector(7 downto 0);  -- not an alias b/c we ignore MSbit
  alias bRequest       : std_logic_vector(7 downto 0) is usb_recv_buf(2);
-- low/high bytes in request pkt
  alias wValue_l       : std_logic_vector(7 downto 0) is usb_recv_buf(3);
  alias wValue_h       : std_logic_vector(7 downto 0) is usb_recv_buf(4);
  alias wIndex_l       : std_logic_vector(7 downto 0) is usb_recv_buf(5);
  alias wIndex_h       : std_logic_vector(7 downto 0) is usb_recv_buf(6);
  alias wLength_l      : std_logic_vector(7 downto 0) is usb_recv_buf(7);
  alias wLength_h      : std_logic_vector(7 downto 0) is usb_recv_buf(8);

begin
--=====================================================
--USB Tranceiver component for receiving and driving differential data lines
--The config_done output signal goes high when we are configured.
--No USB reports can be exchanged until this happens.
  config_done <= '0' when device_config = x"00" else '1';

  UDRVR : USB_DRVR                      --debug bits 50 downto 0 was removed from the port map.
    port map(clk100M       => clk100M, reset => reset, dplus => dplus, dminus => dminus,
             usb_addr      => usb_addr, nakreq => nakreq, stallreq => stallreq, intr_reg => intr_reg,
             bytes_to_send => bytes_to_send, send_buf => usb_send_buf, recv_buf => usb_recv_buf,
             inj           => inj, DOSswitch => DOSswitch);

  mode                <= modeI;         --project Mode byte set by a SetFeature report
--======================================================
--The debug port output may be left open in normal operation.
-- Debugging lines for viewing on oscilloscope or LEDs. 
--debug(50 downto 1)<= debug_drv(50 downto 1);  --these bits come from the DRVR
--additional debug set in top level INTFC: 
--51=bus reset interrupt rcvd
--52=dev descr requested
--53=config descr requested
--54=status requested
--55=at least 1 "final pkt" response requested
--56=error - IN req rcvd after all setup response pkts sent
--57=a host ack recvd, 58=in stall state, 59=assigned usb addr recvd, 60=ZLP IN request
  debug(64 downto 61) <= usb_addr(3 downto 0);

---generate 50 mhz for the interface state machine, which must be at least 4 times the bit rate
  process (clk100M) is
  begin
    if rising_edge(clk100M) then
      clk50M <= not clk50M;
    end if;
  end process;
---=================================================================
---INTERFACE STATE MACHINE - Acts like a firmware interface between tranceiver and FPGA
---=================================================================
-- This state machine is controlled by the interrupts coming from the tranceiver,
-- and acts something like a micro-processor firmware, but way faster.

-----------------------------------------
--Some combinatorial arithmetic for the Write_EP states so we know how many bytes
-- remain to be sent, and when we are at 0 or down to just one packet.
  remaining_bytes <= total_bytes_to_send - ((send_8byte_index - 1) * PKTSIZE);
-----------------------------------------
  nakreq          <= '0' when modeI(5) = '1' else '1';  --We nak interrupt reads till mode(5) set
----------------------------------------- 

  process(reset, usb_state, clk50M) is
  begin
--USB Initialization involves simply resetting registers,
--and then moving to the Wait_irq state where we wait for an interrupt from tranceiver.
--This is done on restart, powerup, and any time the USB host sends a bus reset.
--When the tranceiver receives a valid token from the host, it completes the data stage, ACKS the
--transaction, and sets the approp bit in the intr_reg to solicit a response from the interface.
    if (reset = '1') then
      usb_state           <= Wait_Irq;  --the usual initializing all FF's
      stallreq            <= '0';
      rd_req              <= '0';
      new_dat             <= '0';
      usb_addr            <= "0000000";
      device_config       <= x"00";
      modeI               <= x"00";     --default project mode is 0;
      debug(60 downto 51) <= (others => '0');
    elsif (rising_edge(clk50M)) then
      case usb_state is
                                        --when hang => null;  --hang, to stop the whole thing. This only happens for a weird action

        when Wait_Irq      =>   -- rxd only lower w wait_irq
                                        --Here we wait for an interrupt that signals the host wants a response or has sent data. 
                                        --After any response, we wait for the interrupt to clear before coming back here.
                                        --If the interrupt is a setup request, we go to the Setup_Pkt state to determine the 
                                        -- data source of the response.
                                        --If the interrupt is an IN request, we go to the Write_EP state to load the send_buf 
                                        -- from the response source.  After the response pkt is loaded, we wait for the interrupts
                                        -- to be cleared, which indicates the response is being sent. If a host ack is received,
                                        -- we increment to the next response pkt, or otherwise re-send the current one when asked. 
          debug(58)               <= stallreq;
          new_dat                 <= '0';  --clear the data OUT flag
          case intr_reg is              --Only one interrupt happens at a time so no priority is needed.
                                        ---------------------
            when "0010000" =>           --4=Bus reset. Stay here in reset and wait for the reset to end.
              stallreq            <= '0';
              usb_addr            <= "0000000";
              device_config       <= x"00";
              modeI               <= x"00";  --default project mode is 0;
              debug(51)           <= '1';  --51=bus reset rcvd
                                        -------------------- 
            when "0000001" =>           --0 = ACK by host for last IN data pkt. See #5 which also acks IN requests
              debug(57)           <= '1';  --57= an outgoing pkt received an ACK from host.  
              rd_req              <= '0';  --we reset the read flag here since read data went out successfully.    
              send_8byte_index    <= send_8byte_index + 1;  --increment pointer to the next pkt.
                                        --If this was the last data pkt, remaining_bytes will go negative.
                                        --If there's more to send or the last config pkt was full, another IN request will come.
              usb_state           <= Wait_clr;
                                        --------------------
            when "0000010" =>           --1 =  EP0 IN data pkt requested. Load next response packet.
                                        --Load response data from data_source into send buffer and wait till intrpt cleared.
                                        --We have 2 bit clocks to have data ready in the send_buf.
              usb_state           <= Write_EP_1;  --when the interrupt clears, the pkt has been sent.
                                        -----------------    
            when "0000100" =>           --2 =  OUT non-setup data pkt ready. We only expect one pkt
                                        --This can be either a ctl xfer on EP0 or an interrupt xfer on EP1 if configured.
                                        -- usb_recv_buf now holds the endpoint data.
              usb_state           <= Get_EP_Dat1;  --latch data into PCOut, and prepare for a status ZLP.
                                        -----------------            
            when "0001000" =>           --3 =  New setup request ready :  identify/setup response data source.
                                        --Starts a new control transfer. We will continue with any IN requests till 
                                        --all data pkts sent, or host halts us with a ZLP OUT.
              stallreq            <= '0';  --reset any current stall.
              bmRequestType       <= usb_recv_buf(1) and x"7F";  --mask in the setup request bits from pkt 
              usb_state           <= Setup_Pkt1;  --Identify the response, then come back to wait for data stage.     
                                        -----------------
            when "0100000" =>           --5 = ZLDP OUT pkt recvd. This ends any setup or IN transactions
                                        --We treat this as a success flag for read reports, since it acks the whole transaction.
                                        --rd_req<= '0';  --we reset the read flag here since transaction was successful.
              usb_state           <= Wait_clr;
                                        -----------------
                                        --when "10000000" =>  --7= OUT interrupt-transfer data ready. 
                                        --We use the same recv buf for EP0 and EP1, so I guess we don't need this interrupt.
                                        --usb_state <= Get_EP_Dat1;  --latch the data and handle the flags
                                        -----------------
            when "1000000" =>           --6 =  host ready for IN-data on interrupt EP1.   
                                        --This requires ReadFiles on the PC side, and EP1 configured for interrupts.(see pg392)
                                        --As long as project mode(5) is 0, we ask the transceiver to NAK interrupt IN requests.
              data_source         <= output_data;  --note we just have one EP send buffer for everything
              send_8byte_index    <= 1;  --set pointer into source array
              total_bytes_to_send <= 8;
              usb_state           <= Write_EP_1;
                                        --------------
            when others    => null;
                                        --usb_state <= hang;
          end case;

                                        ---------------------------------------------------
                                        --Entering this state, we have just received OUT data, which could be an 
                                        --arriving data packet or an arriving feature report which was flagged when the
                                        --setup packet was processed. We latch the data and wait till the intrpt is cleared
        when Get_EP_Dat1 =>             -- usb_recv_buf now holds the endpoint data.
          usb_state <= Get_EP_Dat2;     --go wait for the next interrupt after this one is cleared.
          if is_feature = '1' then      --This is "set_feature" data report giving a mode byte. 
            modeI   <= usb_recv_buf(1);  --latch the mode byte
          else                          --This is an OUT data packet: latch buffer, and raise new-dat flag
            PCOut   <= usb_recv_buf;    --data packet received in an OUT report goes out to FPGA host.
            new_dat <= '1';             --<***tell fpga side that a new data packet arrived****>
          end if;

        when Get_EP_Dat2 =>             --
          total_bytes_to_send <= 0;     --get ready for the status stage ZLDP
          send_8byte_index    <= 1;
          is_feature          <= '0';   --reset the feature flag if set
          usb_state           <= Wait_Clr;  --go wait for the next interrupt after this one is cleared.

                                        ------------------------------------------------
        when Wait_Clr =>                --Wait for interrupts to be cleared
          --We always wait till interrupts are cleared by the tranceiver before going  
          --back to wait for next interrupt to avoid a race condition.
          --IN token interrupts are cleared when the response packet has been sent.
                    --setup and OUT interrupts are cleared when the ACK is sent to host
          if intr_reg = std_logic_vector(To_UNSIGNED(0, intr_reg'length) ) then
            usb_state <= Wait_Irq;
          end if;

                                        --------------------------------------------------
                                        --Entering this state we have just rcvd a setup pkt, and we now determine the response.
                                        --Once the response data source is set, we go to the Wait_Clr state to wait for the 
                                        -- setup interrupt to be cleared. 
                                        --On each subsequent IN interrupt, the next pkt in the source array will be loaded.
        when Setup_Pkt1 =>
                                        --Most common values for next state, endpoint, index are defaults for all the cases.
                                        --The data source, bytes to send, and the array index will be different for each case.
                                        --usb_endpoint <= "0000";  --default endpoint is EP0 IN.
          usb_state        <= Wait_Clr;  --Unless we want to stall, we always wait for cleared intrpts.
          send_8byte_index <= 1;        --set default pointer to first element of source array 

                                        -- bmRequestType defines which type request the host is making
          case (bmRequestType) is
            when USB_STD_DEVICE_REQUEST             =>  --00h
              case (bRequest) is        --see page 128 for table of 11 standard device requests
                when USB_GET_DESCRIPTOR             =>  --06h
                  total_bytes_to_send       <= to_integer(unsigned(wLength_l));  --default= num requested         
                                        -- high byte of wValue tells us descriptor type
                  case (wValue_h) is
                    when USB_TYPE_DEVICE_DESCRIPTOR =>  --01h
                      if (to_integer(unsigned(wLength_l)) > DEVICE_DESC_LEN) then
                        total_bytes_to_send <= DEVICE_DESC_LEN;
                      end if;
                      data_source           <= dev_desc;  --padded to 3, 8-byte pkts
                      debug(52)             <= '1';  --52=dev descr requested 

                    when USB_TYPE_CONFIG_DESCRIPTOR =>  --02h
                      if (to_integer(unsigned(wLength_l)) >= CONFIG_DESC_LEN) then
                        total_bytes_to_send <= CONFIG_DESC_LEN;
                      end if;
                      data_source           <= cfg_desc;  --padded to 6, 8-byte pkts

                    when USB_TYPE_STRING_DESCRIPTOR =>  --03h
                                        --low byte of wValue tells us which string descriptor is requested
                      case (wValue_l) is
                        when x"00"                  =>
                                        -- language ID list
                          data_source         <= lang_desc;
                          total_bytes_to_send <= LANGID_DESC_LEN;  --padded to 2 pkts
                        when x"01"                  =>
                                        -- manufacturer string descriptor
                          data_source         <= manufac_desc;
                          total_bytes_to_send <= MANUFAC_STRING_DESC_LEN;  --16 bytes
--                        when x"02"                  =>
--                                        -- manufacturer string descriptor
--                          data_source         <= prod_desc;
--                          total_bytes_to_send <= PROD_STRING_DESC_LEN;  --16 bytes
                        when others                 =>
                          usb_state           <= Stall_1;
                          total_bytes_to_send <= 0;
                      end case;  --end case on USB_TYPE_STRING_DESCRIPTOR/wValue_l

                                             -- Unsupported/error: send to halt state so we can tell when
                                             -- this happens.  TO DO: this will cause the component to stop,
                                             -- if we want to actually report an error to the USB host, this
                                             -- should go to Stall_1 instead of hang
                    when others =>
                      usb_state <= Stall_1;  --hang;
                  end case;  --end case on USB_STD_DEVICE_REQUEST/USB_GET_DESCRIPTOR/wValue_h       

                                        -- The USB host has now given us an address.  we need to store it so
                                        -- the tranceiver state machine will use it for future communications
                when USB_SET_ADDRESS =>  --05h
                  usb_addr            <= usb_recv_buf(3)(6 downto 0);  --save the assigned address
                  Total_bytes_to_send <= 0;  --this is a no-data-stage request
                  debug(59)           <= '1';  --59= set address recvd and latched

                                        -- Status is kind of like a ping: just reply with our constant status value
                when USB_GET_STATUS =>  --00h
                  data_source         <= status;
                  total_bytes_to_send <= 2;

                                        -- Once we have completed enumeration, the host will issue this request,
                                        -- putting us in the "configured" state
                when USB_SET_CONFIG =>  --09h
                  device_config       <= usb_recv_buf(3);
                  total_bytes_to_send <= 0;  --this is a no-data-stage request  
                  modeI(5) <= '1'; --rxd added to enable ep1 

                                        -- Request for the configuration value set with the SET_CONFIG request
                when USB_GET_CONFIG =>  --08h
                  total_bytes_to_send <= 1;
                  data_source         <= dev_cfg;

                                        -- Request to enable a feature
                                        --when USB_SET_FEATURE =>
                                        --       usb_state <= set_feature;

                                        -- Let the host know we don't support TEST_MODE, DEVICE_REMOTE_WAKEUP,
                                        -- or other features we haven't coded yet by stalling the endpoint
                when others =>
                  usb_state <= Stall_1;
              end case;  --end case on USB_STD_DEVICE_REQUEST/bRequest

            when USB_STD_INTERFACE_REQUEST =>  --01h
              case (bRequest) is
                when USB_GET_DESCRIPTOR    =>
                                               -- if wValue high byte = 0x22 then we need to send the HID report descriptor
                  if (wValue_h = x"22") then
                    total_bytes_to_send <= HID_REPORT_DESC_LEN;
                    data_source         <= hid_desc;
                  else
                    usb_state           <= Stall_1;
                  end if;

                when USB_GET_STATUS =>
                  data_source         <= status;
                  total_bytes_to_send <= 2;

                                        -- We only support the default setting (zeros) for set/get interface
                when USB_SET_INTERFACE =>
                  if (usb_recv_buf(5 to 8) = (x"00", x"00", x"00", x"00")) then
                    total_bytes_to_send <= 0;  --this is a no-data-stage request
                  else
                    usb_state           <= stall_1;
                  end if;

                when USB_GET_INTERFACE =>
                  if (wIndex_l = x"00" and wIndex_h = x"00") then
                    total_bytes_to_send <= 1;
                                        --status isn't really the source of our data here, we just want to send a
                                        --zero byte, and the status constant happens to have 0 as the first byte.
                    data_source         <= status;
                  else
                    usb_state           <= Stall_1;
                  end if;

                when others =>
                  usb_state <= Stall_1;
              end case;  --end case on USB_STD_INTERFACE_REQUEST/bRequest

            when USB_CLASS_INTERFACE_REQUEST =>  --21h
              case (bRequest) is
                when USB_HID_GET_REPORT      =>  --01h. see pg 332
                                                 --request for us to send data(either feature or input).
                                                 --The output_data comes into the interface from the FPGA side.
                  total_bytes_to_send <= 8;
                  data_source         <= output_data;

                when USB_HID_SET_REPORT =>  --09h. see pgs 331, 335, 379
                                        --Notification of incoming feature or data report via a control transfer.
                                        --For either type report, as soon as the data is received,
                                        -- the tranceiver will expect a ZLDP to be ready for the status stage IN req.
                  total_bytes_to_send <= 0;  --in anticipation of status IN-request.
                  if wValue_h = "00000011" then  --incoming is feature type report.
                    is_feature        <= '1';  --flag to distinguish feature data when it comes.
                  end if;
                                        --With a feature report we will save byte(1) into the "mode" output.
                                        --With a data report we will latch it into PCIn and toggle the new_dat flag.
                  usb_state           <= Wait_Clr;  --go wait for the data packet after intrpts cleared

                when USB_HID_SET_IDLE =>  --0Ah. see pgs 331, 336, 401. Only applies if EP1 enabled.
                                        --We dont stall this req so the host knows we will operate at a 0 idle rate.
                                        --i.e. we NAK interrupt IN's unless there is data to send, as determined by the mode.
                  total_bytes_to_send <= 0;  --this is a no-data-stage request

                when others =>
                  usb_state <= Stall_1;
              end case;  --end case on USB_CLASS_INTERFACE_REQUEST/bRequest

                                        --*******I don't know what these might usefully do .
            when USB_STD_ENDPOINT_REQUEST =>
              case (bRequest) is
                when USB_CLEAR_FEATURE    =>
                                        -- endpoint halt
                  if (wValue_l = x"00" and wValue_h = x"00") then
                                        --usb_state <= clear_feature;
                    total_bytes_to_send <= 0;  --***chgd from orig
                                               --usb_endpoint <= wIndex_l;  --wIndex low byte tells us the endpoint  
                  else
                    usb_state           <= Stall_1;
                  end if;
                when USB_SET_FEATURE      =>
                                        -- endpoint halt
                  if (wValue_l = x"00" and wValue_h = x"00") then
                                        --usb_state <= set_feature; 
                    total_bytes_to_send <= 0;  --***chgd from orig
                                               --usb_endpoint <= wIndex_l;  --wIndex low byte tells us the endpoint 
                  else
                    usb_state           <= Stall_1;
                  end if;
                when others               =>
                  usb_state             <= Stall_1;
              end case;  --end case on USB_STD_ENDPOINT_REQUEST/bRequest

                                        -- Vendor requests currently aren't used, so just stall
            when USB_VENDOR_DEVICE_REQUEST   =>
              usb_state <= Stall_1;
            when USB_VENDOR_ENDPOINT_REQUEST =>
              usb_state <= Stall_1;
            when others                      =>
              usb_state <= Stall_1;
          end case;  --end case on bmRequestType

                                        --------------------------------------
                                        --This state loads the send_buf with the next byte array to be sent from the
                                        --<data_source> to the usb_endpoint. (we only have a single endpoint 0)
                                        --After loading, we wait for last interrupt to be cleared indicating it is being sent. 
                                        --We increment the data source index for the next pkt only when there is a host-ack interrupt.
                                        --This is repeated in 8-byte transactions each time there is an IN token interrupt
                                        --till total_bytes_to_send is satisfied, or a new setup request over rides it.
        when Write_EP_1 =>              --Load the next data packet to be sent in response to an IN token       
          --Remaining_bytes (computed above) is what we currently have left to send of the total:
          --       remaining_bytes<= total_bytes_to_send - ((send_8byte_index - 1)*8);
          if (stallreq = '1') then      --This is per usb 1.1 spec, 8.5.2.2.
            usb_state <= Wait_Clr;      --stay in the stall till a new setup pkt clears it.

          elsif (remaining_bytes < 0) then
            debug(56) <= '1';           --56= IN request came after all pkts sent
            stallreq  <= '1';           --signal a stall to the tranceiver, per usb 1.1 spec, 8.5.2.2.
            usb_state <= Wait_Clr;

          elsif remaining_bytes = 0 then
                                        --this is either a final data pkt for a multi-pkt IN xfer, or status for OUT xfer
            debug(60)     <= '1';       --ZLP has been requested
            bytes_to_send <= 0;
            usb_state     <= Wait_Clr;

          else                          --load the usb send buffer since there is something remaining to send
            if remaining_bytes < 8 then
                                        --This is the last, or the only, pkt for a setup response.
              debug(55)         <= '1';  --55= at least 1 "last pkt" setup response requested
              bytes_to_send     <= remaining_bytes;
            else
              bytes_to_send     <= 8;
            end if;
                                        --We are assuming send_buf gets loaded BEFORE the tranceiver gets to Send_Resp state!
                                        --This takes 2 bit periods in the transceiver, so we should be more than safe here.
            usb_state           <= Wait_Clr;  --wait for interrupts to clear, then go wait for next IN req.
            case data_source is         --load the send_buf on our way out
              when dev_desc     =>
                usb_send_buf    <= DEVICE_DESC(send_8byte_index);
              when cfg_desc     =>
                usb_send_buf    <= CONFIGURATION_DESC(send_8byte_index);
                debug(53)       <= '1';  --53=config descr requested
              when lang_desc    =>
                usb_send_buf    <= LANGID_DESC;
              when manufac_desc =>
                usb_send_buf    <= MANUFAC_STRING_DESC(send_8byte_index);
--              when prod_desc    =>
--                usb_send_buf    <= PROD_STRING_DESC(send_8byte_index);
              when status       =>
                usb_send_buf    <= USB_STATUS;
                debug(54)       <= '1';  --54=status requested
              when dev_cfg      =>
                usb_send_buf(1) <= device_config;
              when hid_desc     =>
                usb_send_buf    <= HID_REPORT_DESC(send_8byte_index);
              when output_data  =>
                usb_send_buf    <= PCIn;
                Rd_req          <= '1';
            end case;
          end if;

                                        -----------------------------------------                
                                        --Stalls specify an error or unsupported feature in a request
        when Stall_1 =>                 --we remain in the stall until a new setup starts
          stallreq  <= '1';             --signal the stall condition to the tranceiver
          usb_state <= Wait_Clr;        --wait for any interrupt to clear

                                        -----------------------------------------        
                                        --when set_feature =>
                                        --       usb_state <= wait_irq;
                                        --when clear_feature =>
                                        --       usb_state <= wait_irq;
      end case;
    end if;
  end process;
---=============================
end arch;  --END of USBF_IFC
---=============================
        
--===============================================================================
---USB_DRVR Entity (Drives and Reads D+ and D- lines to send and receive packets)
--===============================================================================
-- USB Driver - Copywrite Johns Hopkins University ECE Dept.
--This code may be used and freely distributed as long as this header is retained.
--------------------------------------------------
--Description: USB Transceiver - Sends packets on request from USB_IFC to PC
--and receives packets sent by host. It consists of two state machines, one
--to read the D+/D- lines to receive pkts and one to drive the lines to send pkts.
--It presumes all transactions are initiated by the host, so that machine #2 is
-- activated only by ACKS, Stalls, or tokens that request IN pkts.
--Constants and signal types are declared in the usb_declares pkg.
--Author: Robert Jenkins Last modification: Jan 30, 2009
--==============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.USBF_Declares.all;

--------------------------------------------------
entity USB_DRVR is
  port(                                 --*DEBUG bits currently commented out. So this port has been eliminated.
    --debug:           out   std_logic_vector(50 downto 1); 
    clk100M       : in    std_logic;    --100MHz clock
    reset         : in    std_logic;    --fpga reset
    inj           : in    std_logic;
    DOSswitch     : in    std_logic;
    
    dminus        : inout std_logic;    -- USB differential D+ line
    dplus         : inout std_logic;    -- USB differential D+ line
    intr_reg      : out   std_logic_vector(6 downto 0);  --interrupts out to interface
    nakreq        : in    std_logic;    --active-hi signal to flag NAKs for interrupt IN requests
    stallreq      : in    std_logic;    --active-hi signal to flag the stall condition
    usb_addr      : in    std_logic_vector(6 downto 0);  -- USB assigned address 
    bytes_to_send : in    integer range 0 to BYTEMAX;  --bytes to send for current IN response
    send_buf      : in    EIGHT_BYTES;  -- outgoing data to send to host
    recv_buf      : out   EIGHT_BYTES   -- incoming data from host
    );
end USB_DRVR;
---------------------------------------------------

architecture arch of USB_DRVR is
------------------------
--  component IOBUF
--    generic (IOSTANDARD :     string  := "LVCMOS33");--; rest set in IO defining
----             DRIVE      :     integer := 16;
----             SLEW       :     string  := "FAST");
--    port (O             : out std_ulogic;
--          I             : in  std_ulogic;
--          IO            : out std_ulogic;
--          T             : in  std_ulogic);
--  end component;
------------------------
--attribute INIT        :     string;
  constant DDSBITS      :     natural := 32;
                                        --Comment out the below value not being used depending on the bit rate.
                                        --Must be consistant with the 1.5K pull-up, and the KP value defined in the usb package
      --constant DDSMF        :     real    := 0.5 + 12.0*(2.0**DDSBITS)/100.0;  --12 Mhz DDS increment
  constant DDSMF: real:= 0.5 + 1.5*(2.0**DDSBITS)/100.0;  --1.5 Mhz DDS increment --rxd this line uncommented for LS mode, else FS with line above
  constant DDSM         :     signed  := TO_SIGNED(integer(DDSMF), DDSBITS);

  constant NTOKEN : natural := 33;      --Num bits in a token(8+8+7+4+5)+1 for possible dribble
                                        ----SIGNALS  ---------------------------------------------------
  signal ddsacc                             : signed(DDSBITS-1 downto 0) := (others => '0');  --dds accumulator for synthesizing bitclk
  alias sm_clk                              : std_logic is ddsacc(ddsacc'high);  --state machine clock is bitclk
  signal dp_in, dp_out, dm_in, dm_out, tout : std_logic;  --tristated dplus and dminus lines
  signal dp_last, dp_prev, output           : std_logic;
  signal input                              : std_logic := '1'; --rxd: initialised for stability, host will always contact first driving input

  signal new_usb_addr            : std_logic_vector(6 downto 0) := (others => '0');  --usb address from interface
  signal pid, endp               : std_logic_vector(3 downto 0);  --latched token pid and endp
  signal crc_reg, crc16, crcin16 : std_logic_vector(16 downto 1);
                                        --signal crc5:       std_logic_vector(5 downto 1);  --not currently tested
                                        --note that for token_in and dat_reg, we allow for a "dribble" bit (see usb spec 7.1.9.1)
  signal token_in                : std_logic_vector(NTOKEN downto 1);  --reg for receiving token bits 
  signal token_ad                : std_logic_vector(6 downto 0) := (others => '0');  --addr bits in last token
  alias token_pid                : std_logic_vector(3 downto 0) is token_in(12 downto 9);  --pid bits
  signal dat_reg                 : std_logic_vector(BITMAX downto 1);  --reg for rcvd data bits
  signal send_reg                : std_logic_vector(16 downto 1);  --reg for sending sync+pid bits
  signal out_buf                 : EIGHT_BYTES;  --array of send_buf data being sent out
  signal bit_index               : integer range 0 to 7;  --bit index into out_buf
  signal byte_index              : integer range 0 to BYTEMAX;  --byte index into out_buf 
  signal nbytes                  : integer range 0 to BYTEMAX;  --bytes to send in the write packet
  signal bitin                   : integer range 0 to BITMAX;  --bit counter for receive bits
  signal bitct                   : integer range 0 to BITMAX;  --bit counter for send bits
  signal stuffct, stuffin        : integer range 0 to 7;  --counters for stuff-bits out and in
  signal dtog                    : std_logic :='0';  --DATA togle bit

                                        --boolean flags about the current transaction
  signal                                setup, outpkt, bad_pkt : boolean;
  signal                                send_req, sendcompl    : boolean;  --Sender state machine flags- request and completed

                                        ------------------------------------------------------
                                        --These 2 state machines control input and output of usb packets
                                        ------------------------------------------------------
  type usb_sm_type is (                 --Tranceiver state machine #1 to read D+/D- lines
    Idle, halt, ChkSez,-- InSync,                 --Wait_4_EOP,
    Start_pkt1,                         --states to start a pkt reception with 1st 17 bits
    GetToken, ChkToken,                 --2 token packet reception states
    GetDat1, GetDat2,                   --2 data packet reception states
    SendAck, SendStall, SendDat0,       --states to setup and request outgoing data pkts
    SendResp, Wait_Send );
  signal                                usb_state              : usb_sm_type := Idle;
--attribute INIT of usb_state                                  : signal  is "Idle";
                                        ---------------------
  type send_sm_type is (                --Tranceiver state machine #2 to drive D+/D- lines
    Wait_Req, Start_Send, Start_Send1,  --states to start outgoing packets
    SendPid, SendDat2, Send_crc,        --states to handle outgoing bits
    Send_EOP1, Send_EOP2, Send_EOP3, Send_EOP4  --states to hande output end-of-packet
    );
  signal                                send_state             : send_sm_type := Wait_Req;
--attribute INIT of send_state                                 : signal is "Wait_Req";
------------------------------------------------------------

begin
--These could be replaced by inferred tri-stating as in the lines commented out below.
--rxd replaced
--This might be preferable to avoid problems transporting the vhdl to a different chip family.
--  U_IOBUFP : IOBUF
--    port map (O  => dp_in,              --tristate drivers for data lines 
--              IO => dplus,
--              T  => tout,
--              I  => dp_out);
------------------
--  U_IOBUFM : IOBUF
--    port map (O  => dm_in,
--              IO => dminus,
--              T  => tout,
--              I  => dm_out);
--  tout <= input and not output;         --inverted output condition

--tri-stated USB diferential pairs connected to usb cable with D+ or D- pullup to 3.3V
dp_in <= dplus when input = '1' else 'Z';
dm_in <= dminus when input = '1' else 'Z';
dplus <= dp_out when output = '1' else 'Z';
dminus <= dm_out when output = '1' else 'Z';
---=====================================================================
-----***50 debug lines sent up to INTFC  ----------
--35:46 are FF states set once in SM#1
--debug(16 downto 1)<= token_in(16 downto 1);  --Last token pid received
--debug(20 downto 17)<= new_usb_addr(3 downto 0);
--debug(24 downto 21)<= token_ad(3 downto 0);  --last token addr
--debug(33)<= sm_clk;                   --lines for scoping
--debug(33)<= dm_in;
--debug(34)<= dm_out;
--debug(50 downto 47)<= send_reg(12 downto 9);  --last pid sent
---==================================================================
-- DDS process to generate the bit rate clock for send and receive. 
--The phase is reset to falling edge each time there is a change to input D+, thus
-- we presume data changes on the falling edge and is sampled on the rising edge.  
-------------------------------------------------------------
  PDDS : process (clk100M, reset) is
  begin
    if reset = '1' then
      ddsacc      <= (others => '0');
    elsif rising_edge(clk100M) then     --run DDS at 100 Mhz        
       if (input='1') then -- and (output='0') then --rxd included for stability to only sample transitions during input
         dp_prev     <= dp_in;             --sample the input D+ line 
         if (dp_prev /= dp_in) then 
           ddsacc    <= DDSM;              --reset phase of bit_clk any time incoming data changes  
         else ddsacc <= ddsacc + DDSM; -- else at start of this line
         end if;
       else ddsacc <= ddsacc + DDSM;
       end if;
    end if;
  end process PDDS;


--===================================================================
-- USB TRANCEIVER STATE MACHINE # 1 - Data receiver
--===================================================================

  PUSB_SM : process (reset, sm_clk) is
  begin
--This state machine controls packet reception, and launches packet sends
-- when requested by IN tokens. The sm_clk is the ddsac msb, phased to the NRZI data.
--The transceiver ignores SOF's, and handles ACK's automatically.
    if (reset = '1') then
                                        --token_in<= (others=>'0');
      token_ad        <= (others => '0');
                                        --debug(46 downto 35)<= (others=>'0');  --reset any latched debug bits
      intr_reg        <= (others => '0');
      new_usb_addr    <= (others => '0');
      input           <= '1';
      usb_state       <= Idle;          --initialize to Idle state, which will wait for a host transaction
    elsif (rising_edge(sm_clk)) then    --we sync the falling edge to incoming bit changes. 
      case usb_state is
       when halt                =>     --this is an error state to halt all activity
          input       <= '1';
                                        --Idle state J is D+ high (due to 1.5K pullup) and D- low for 12 MHz speed, 
                                        --  and D+ low and D- high (due to 1.5K pullup) for 1.5 MHz 
                                        --In Idle state we wait for a new transaction initiated by the host. 
        when Idle                =>
          intr_reg    <= (others => '0');  --Waiting for next transaction, JIC clear interrupt register.
          input       <= '1';           --The FPGA line drivers stay in input mode in the idle state.   
                                        --Waiting for next host initiated transaction. Bus reset is highest priority. 
          if (output = '1') then        --rxd added for stability
            usb_state <= Idle;
          end if; 
          
          if dp_in = '0' and dm_in = '0' then  --Persistent SEZ is a bus reset                
            bitin     <= 0;
            usb_state <= ChkSez;        --2 SEZ bits could just be a 1.5 MHz keep alive.
                                        --By definition, we are out of reset if we ever get past this condition
                                        --********************************************************************

                                        --Idle state is J for either low or full speed. A K state is a pkt start
          elsif dp_in = KP and dm_in = KM then  --start of  pkt is actually 1st sync K
            dp_last   <= dp_in;         --****We always save the dp line for NRZI decoding.
            bitin     <= 2;             --we are now receiving the 1st sync K bit as SOP, next bit will be bit 2
            stuffin   <= 0;
            usb_state <= Start_pkt1;    --This MUST be the start of a new host initiated pkt.
          else usb_state <= Idle;       --rxd added
          end if;

        when ChkSez =>                  --Single Ended Zero- is this a bus reset or just a keep-alive?
          if dp_in = '0' and dm_in = '0' then  --a 10msec single ended zero is a bus reset
            if bitin < 30 then          --count the SEZ bits
              bitin       <= bitin + 1;
            else                        --must be a reset if it lasts this long
              bad_pkt     <= false;
              setup       <= false;
              outpkt      <= false;
              intr_reg(4) <= '1';       --signal bus reset interrupt to the interface   
            end if;
          else                          --Whatever it was, the SEZ ended
            --intr_reg(4)<= '0';        --clr the reset intrrpt. Done in Idle state
            usb_state     <= Idle;      --go back to Idle
          end if;
        
                                        ------Start a packet reception  -----------------        
                                        --This state starts any PC initiated transaction - we get 16 bits and chk the PID.
                                        --It could be a new setup stage starting, a data token for a data phase, an ACK, or SOF.
                                        --To simplify the logic, if it's a token with an addr that isn't ours or a hosed pid, we
                                        --still receive the whole transaction, but set a bad_pkt flag to ignore it. 
                                        --We don't respond or ACK anything until a new token with our addr arrives.
        when Start_pkt1                  =>  --Get next 15 bits(SOP is the 1st sync bit) so we can chk the PID
          dp_last             <= dp_in;  --always save the current bus state for NRZI test on nxt clk      
          if stuffin = 6 then           --after 6 '1's in a row = This is a stuff bit.
            stuffin           <= 0;     --ignore it and reset the stuff count.
          else                          --no stuff bit, get the real bit based on D+/D- lines. 
--            bitin             <= bitin + 1;  --Count the real bits. Current 'bitin' is always coming in. --rxd commented
            if dp_last = dp_in then     --NRZI test. no change -> 1
              stuffin         <= stuffin + 1;  --count the consecutive 1's
              token_in(bitin) <= '1';
              if (bitin < 8) then --rxd: clock sync occasionally misses the first K-J of pkt sync sequence
                bitin <= 9;       --rxd: this jumps/aligns the bit counter once the end of sync sequence '1' is seen
              else bitin <= bitin + 1;
              end if;
            else
              bitin <= bitin + 1; --rxd
              token_in(bitin) <= '0';
              stuffin         <= 0;     --reset the stuff-bit count when a 0
            end if;
            
                                        --concurrently we watch for 16th bit coming in, to chk the pid for how to continue.
            if bitin = 16 then          --16th bit now coming into the token_in register.
              case token_pid is
                when "0011"|"1011"       =>  --Data pkt pid's                               
                  usb_state   <= GetDat1;  --Incoming data pkt, go finish getting the data
                  crcin16     <= (others => '1');  --initialize the crc16 generator for data bits
                  bitin       <= 1;     --count the data bits received, in case its a ZLDP.
                when others              =>  --All other pid's are tokens or handshakes
                  usb_state   <= GetToken;  --so go finish the token with bit-17 coming in next  
              end case;
            end if;
          end if;

                                        --This state is entered to finish getting a token, then we check the addr and response.
                                        --We note that due to "dribble" there may be an extra real bit before the EOP 
        when GetToken =>                --First 16 bits are in. Now get 16 more bits for a complete token. 
          dp_last             <= dp_in;  --Always save the current bus state for NRZI test on nxt clk
                                        --1st priority-look for EOP SEZ to stop reception
          if dp_in = '0' and dm_in = '0' then
            usb_state         <= ChkToken;  --This is the EOP, otherwise keep getting token bits.
            pid               <= token_pid;  --latch pid, token addr, and end point
            token_ad          <= token_in(23 downto 17);
            endp              <= token_in(27 downto 24);  --save in case EP1 is configured
            if usb_addr = token_in(23 downto 17) then
              new_usb_addr    <= usb_addr;  --latch usb addr 1st time it appears in a token
            end if;
                                        --No EOP SEZ - stay here and keep getting bits
          elsif stuffin = 6 then        --6 '1's in a row = This is a stuff bit.
            stuffin           <= 0;     --ignore it and reset the stuff count.
          else                          --otherwise get the bits based on D+/D- lines   
            bitin             <= bitin + 1;  --count the real bits
            if dp_last = dp_in then     --NRZI test. no change -> '1'
              stuffin         <= stuffin + 1;  --count the consecutive 1's
              token_in(bitin) <= '1';
            else
              token_in(bitin) <= '0';
              stuffin         <= 0;     --reset the stuff-bit count when a 0
            end if;
          end if;

                                        --Now we have a complete token - check what it's about during the 2nd EOP SEZ bit.
                                        --If address doesn't match, we set bad_pkt TRUE and won't respond or ACK any transaction
                                        --till we get a new token with our addr. pkts to be ignored are flagged by bad_pkt=TRUE.
        when ChkToken      =>
                                        --Invalid address or hosed pid. We set the flag to ignore all subsequent transactions
                                        -- till a valid token with our address is recvd.
          if ((token_ad /= new_usb_addr) and (endp /= "0001")) or (pid /= not token_in(16 downto 13)) then --rxd: this enables injection
--          if (token_ad /= new_usb_addr or pid /= not token_in(16 downto 13)) then --or ((pid = IN_PID) and (endp /= "0000")) then --rxd second or on
                                        --debug(39)<= '1';
            bad_pkt                     <= true;  --flag this entire transaction to be ignored
            usb_state                   <= Idle;  --ignore it and wait for next valid transaction.        
          else
            bad_pkt                     <= false;  --If it's a new setup token with our addr we get excited.
                                        --  Here's where the transaction is understood. If it's a setup or control
                                        --  OUT req, we set a flag and wait for a DAT0 token to receive the data.
                                        --  After getting data error free, we will set the approp interrupt bit, send 
                                        --  an ACK, then go to Idle to wait for an IN TOKEN to send a response.
                                        --  If it's an IN token, we set the IN interrpt bit, and go to send_response.
            case pid is
              when ACK_PID =>           --A host ACK could be handled earlier since it is only 16 bits
                                        --debug(40)<= '1';  --40= we received a valid ack from host
                intr_reg(0)             <= '1';  --signal successful ack to interface.
                dtog                    <= not(dtog);  --toggle for the next outgoing pkt if there is one.
                usb_state               <= Idle;  --go wait for next request
              when "1010"  =>           --this is a NAK, so we sit tight for a while.
                usb_state               <= Idle;  --go wait for next request      
              when "1101"  =>           --Setup request - DAT0 pkt should come next from host.    
                                        --debug(43)<= '1';
                setup                   <= true;  --Flag this as a transaction setup stage.
                                        --outpkt<= FALSE;
                usb_state               <= Idle;  --go wait for the setup stage data pkt
              when "0001"  =>           --OUT token, means a non-setup data0 pkt is coming from host.   
                                        --This might be a premature ZLDP status stage interrupting a setup transfer.
                outpkt                  <= true;  --OUT Data coming from PC (could be a ZLDP status for an IN)
                setup                   <= false;
                usb_state               <= Idle;  --whatever it is, go wait for it to arrive.
              when IN_PID  =>           --IN token - may be a setup response or an OUT status request.  
                setup                   <= false;
                if endp = "0000" then
                  intr_reg(1)           <= '1';  --interrupt 1= host wants ctl IN data on ep0.
                  usb_state             <= SendResp;  --Go send whatever is put the send_buf
                else
                  if (nakreq = '0') and (token_ad /= new_usb_addr) and (DOSswitch = '1') then  --rxd
                                                 --rxd: address mismatch condition means device won't send any data on its own behalf
                    intr_reg(6)         <= '1';  --interrupt 6= host wants IN interrupt data on EP1
                    usb_state           <= SendResp;
                  else pid              <= NAK_PID;  --NAK interrupt reads till firmware allows 
                       send_req         <= true;  --make the request to the send-pkt state machine #2.
                       usb_state        <= Wait_Send;  --request the ACK to be sent and wait for completion
                  end if;
                end if;
              when "0101"  =>           --we ignore start of frames                     
                usb_state               <= Idle;
                                        --should never get here unless something weird. 
              when others  => usb_state <= Idle;
            end case;

          end if;
                                        ------end of token reception  -----------------------

                                        --This state is entered to finish the reception of a data pkt. It may be the data
                                        -- stage of a setup request, an OUT pkt previously set up, or status stage of an IN.
                                        --For a data packet, we expect 16(sync+pid)+64(data)+16crc. We use the token_in
                                        --reg for the first 16, the dat_reg for the data, and the crc bits.
        when GetDat1 =>                 --We already have the first 16 bits. The 1st data bit is now coming in.
          --We continue to get the rest - 64 data bytes + 16 crc bits. EOP stops the action.    
          dp_last            <= dp_in;  --save the dp line for NRZI decoding of next bit.
          if dp_in = '0' and dm_in = '0' then  --look for EOP while we receive bits
            usb_state        <= GetDat2;                            --This is the EOP, otherwise keep getting data.
            for i in 1 to PKTSIZE loop  --Latch rcvd bits into the recv buffer.
              recv_buf(i)    <= dat_reg(8+8*(i-1) downto 1+8*(i-1));
            end loop;  --We dont care if all N bytes aren't there.
            --Whatever the pkt size, the last 16 bits in dat_reg are CRC16 bits.
--          usb_state        <= GetDat2;--go chk the crc16 bits, and make an interrupt response --rxd fix
                                        --If no EOP then keep getting data bits.        
          elsif (stuffin = 6) then      --This is a stuff bit.
            stuffin          <= 0;      --Ignore it and reset the stuff count.
          else
            bitin            <= bitin + 1;  --count the real bits. A dribble will go into bit 81
            if dp_last = dp_in then     --NRZI test. no change -> 1
              stuffin        <= stuffin + 1;  --count consecutive 1's
              dat_reg(bitin) <= '1';
              crcin16        <= NEW_CRC16(crcin16, '1');
            else                        --data change -> 0
              dat_reg(bitin) <= '0';
              crcin16        <= NEW_CRC16(crcin16, '0');
              stuffin        <= 0;      --reset the stuff-bit count whenever a 0
            end if;
          end if;

                                        --We now have the data pkt, and need to interrupt the interface for action.                             
        when GetDat2 =>                 --during this state the 2nd EOP SEZ should be driving the input lines
          if bad_pkt = true then        --Only respond if it's an error free pkt for our address
            usb_state     <= Idle;      --just ignore if the token was bad pid or not our address
          else
            if bitin < 18 then          --A ZLDP IN means this is a host status-stage pkt
              usb_state   <= SendAck;   --so we just ACK it, and halt any active stage
                                        --debug(45)<= '1';
              setup       <= false;
              outpkt      <= false;
              intr_reg(5) <= '1';       --host ZLDP ACKS IN transactions even if no data ACK was recvd 
            elsif crcin16 /= x"B001" then  --chk final crc16 value
              usb_state   <= Idle;      --crc failure, dont ack and wait for a data pkt repeat       
                                        --   debug(42)<= '1';

                                        --The "firmware" interface will respond to the following interrupts while we ACK,
                                        -- but we wont send its response till we get an IN-token. Any follow-on 
                                        -- responses wont be loaded till the IN interrupt is cleared, and we get an ACK.
                                        --Responses continue till all s/u pkts sent, or an OUT token comes.
            elsif setup then            --In S/U stage we tell interface to get requested data loaded,
              setup       <= false;     -- and go out of S/U stage. After the ACK we are in data IN stage.
              intr_reg(3) <= '1';       --interrupt 3= setup request is ready in the recv_buf
              dtog        <= '1';       --set tog to start data stage with a DATA1
              usb_state   <= SendACK;
            else
              intr_reg(2) <= '1';       --interrupt 2= host OUT data is ready in the recv_buf
              dtog        <= '1';       --Prepare for a ZLP response when next IN token starts status stage
              usb_state   <= SendACK;
            end if;
          end if;
                                        -------end of data packet reception  ---------------

                                        ----Send an ACK, NAK, or Stall handshake  ----------------
        when SendAck =>                 --During this state the EOP J-state should be driving the input lines
          --stall takes precedence over ack
          if stallreq = '1' then        --the stall will be cleared when new valid setup token received
            pid     <= STALL_PID;
          else
                                        --debug(44)<= '1';  --44= sent an ACK
            pid     <= ACK_PID;         --put ACK pid into the send_reg
          end if;
                                        --we will send 16 bits for any type handshake, 1st bit goes out as the 1st sync K               
          send_req  <= true;            --make the request to the send-pkt state machine #2.
          usb_state <= Wait_Send;       --request the ACK to be sent and wait for completion    
                                        ----handshake packet now set-up and waiting for send  ------

                                        --Here we carry out the "firmware" response to the latest host IN-request for data.
                                        --In response to the interrupt, the interface should have by now (1 bit later) loaded
                                        -- the usb_send_buf, with bytes_to_send set.
        when SendResp =>
          if stallreq = '1' then        --once we stall, we remain there till a new setup token.
            usb_state <= SendStall;     --see usb spec on control xfers

          elsif ((endp = "1001") or (endp = "0001")) and nakreq = '1' then  --interrupt IN request on EP1 (token_ad = new_usb_addr) then --
            pid       <= NAK_PID;       --NAK until interface says respond
            send_req  <= true;
            usb_state <= Wait_Send;

                                        --An IN request when outpkt is true means it's the status stage of an OUT transaction
          elsif outpkt = true then
            nbytes    <= 0;             --so we send a ZLDP
            dtog      <= '1';
            outpkt    <= false;
                                        --debug(41)<= '1';  -- 41= sent a ZLDP status
            usb_state <= SendDat0;

          elsif bytes_to_send >= 0 then
            nbytes    <= bytes_to_send;  --this should never be < 0 ???
            usb_state <= SendDat0;      --set up a request to state mach #2 to send the data    
                                        --an IN request with < 0 bytes to send is a point of confusion????? 
                                        --It could only happen during the data stage of a setup transaction where total bytes=N*8.
          else
                                        --debug(38)<= '1';  -- 38= got a setup IN request with negative bytes_to_send                               
            usb_state <= SendStall;     --see usb spec on control xfers
          end if;
                                        --This is a setup or an IN response by the FPGA interface.
                                        --We assume the Send_Buf has been loaded by the interface, and dtog is set.
                                        --We will send 8 bytes per data pkt unless "bytes_to_send" is < 8.
        when SendDat0 =>                --Send an outgoing data transaction
        if ((inj = '0') and (token_ad /= new_usb_addr)) then --rxd ...and (endp /= "0001")
            send_req  <= false;         --rxd: this if stops zero-filled packets being injected to inject NAKs instead                     
            usb_state <= Idle;          --rxd: also ensures no data sent on behalf of this device
        else                            --rxd: lines below all that was in original code for this state 
          out_buf     <= send_buf;      --latch send_buf so it can be reloaded for next transaction.
          pid         <= dtog & "011";  --pid= toggled DATA0/DATA1                      
          send_req    <= true;          --request state machine #2 to do the transaction
          usb_state   <= Wait_Send;     --go wait for completion
                                        --debug(46)<= '1';
        end if;                         --rxd
                                        ----Send a stall pkt  ----------------------------
        when SendStall =>
                                        --debug(42)<= '1';              
          pid       <= STALL_PID;       --put pid in the send_reg
          send_req  <= true;            --we will send 16 bits for a STALL, 1st goes out as the 1st sync bit
          usb_state <= Wait_Send;       --request the packet to be sent and wait for completion
                                        ----Stall packet now ready to send  ----------------------

        when Wait_Send           =>     --We have kicked off an outgoing transaction. Now wait for it to finish
                                        --On entering this state we've had one or two clocks of idle on the input lines
          input       <= '0';           --tristate the data lines from input
          if sendcompl = true then      --wait for completion
            intr_reg  <= (others => '0');  --response sent, clear the interrupt register.
            send_req  <= false;         --clear the send request                        
            usb_state <= Idle;          --After any pkt sent, we go back to Idle to get the ACK
          end if;

        when others => usb_state <= Idle;
      end case;
    end if;
  end process PUSB_SM;


--======================================================================
--USB TRANCEIVER STATE MACHINE # 2 - drive data lines to send a packet out to host.
-- May be just an ACK, NAK, STALL, or ZLDP, defined when the send request is made.
--We presume any data to be sent is already in the out_buf array
--======================================================================
  send_reg(8 downto 1) <= SYNC;         --the first 8 bits out is always sync bits

  PSEND_SM : process (reset, sm_clk) is
  begin
--This is the state machine to send a single data pkt. It waits till requested
--by the recvr state machine #1, then sends the out_buf in a data pkt, assuming pid,
--dtog bit, and num bytes to send are pre-set. Then it issues an EOP sequence (SEZ,SEZ,J),
--tristates the line drivers, signals completion, then waits for next request.
--An ACK or STALL has no crc16 processing, but a ZLDP does include an all 0 crc16 portion.
    if (reset = '1') then
      output                       <= '0';
      send_reg(16 downto 9)        <= (others => '0');
      send_state                   <= Wait_Req;
    elsif (falling_edge(sm_clk)) then   --the falling edge is synched to incoming bit changes. 
      case send_state is
        when Wait_req                         =>  --Wait for a request from above to send a packet.
          output                   <= '0';  --tristate the data lines from output drivers.
          dp_out                   <= JP;  --keep outputs in idle state J
          dm_out                   <= JM;  --Note: idle state J depends on D+/D- pullup
          sendcompl                <= false;  --completion flag off
          if send_req = true then       --we have a send request. (2.5-3.5  bits of idle have elapsed)
                                        --send_reg(8:1) is permanently tied to SYNC, we now load (16:9) with pid bits
                                        --We expect the toggle bit to be already set in the pid.
            send_reg(16 downto 13) <= not pid;  --pid is set when send request is made
            send_reg(12 downto 9)  <= pid;
            send_state             <= Start_Send;
--            output <= '1'; --rxd test
          end if;
                                        ----Send an outgoing transaction  -----------------------
                                        --This may be an ACK, NAK, or STALL, or an IN data transfer.
                                        --We expect the lines to be currently tri-stated in a pullup J idle state.
        when Start_Send                       =>  --we delay 1 bit before driving the lines with a K state.
          Send_state               <= Start_Send1;  --4.5 bits max of idle have elapsed. Go right to K state
          output                   <= '1';  --turn the line drivers on in J state after 4.5 bits of idle
        when Start_Send1                      =>  --Start the pkt. All changes occur on the bit clk falling edge.
          dp_out                   <= KP;  --A sync K is always the SOP.
          dm_out                   <= KM;  --1st K bit now going out after 5.5 bits max of idle after host EOP
          bitct                    <= 2;  --NOTE: when sending, bitct is always the current bit to send   
          stuffct                  <= 0;
          Send_state               <= SendPid;  --Send_Pid starts all outgoings.

                                        ---- Send_Pid - Send the contents of the send_reg  -------
                                        --The outgoing proceeds in 4 stages, some of which may not be needed: 
                                        --finish the remaining 15 sync+pid bits in the send_reg w/o CRC processing,
                                        --then go to SendDat2 to send nbytes from the out_buf with CRC processing, 
                                        --then send the final inverted CRC bits, then end the packet.
                                        --The bitct is always the current bit to send in any state
        when SendPid                  =>  --Send the bits in the send_reg, lsb first.
          if stuffct = 6 then           --check for a stuff bit needed
            stuffct        <= 0;
            dp_out         <= not dp_out;  --send a 0 stuff bit by inverting lines.
            dm_out         <= not dm_out;  --this doesn't count as a bit.  
          else                          --send out the next real bit
            if send_reg(bitct) = '1' then
              stuffct      <= stuffct + 1;  --leave lines in same state if a 1      
            else
              stuffct      <= 0;
              dp_out       <= not dp_out;  --send a 0 bit by changing state.
              dm_out       <= not dm_out;
            end if;
                                        --concurrently we chk for the 16th real bit going out.
            if bitct = 16 then
                                        --Now sending 16th bit. From here on we end packet, or send the rest with CRC.
              if pid = ACK_PID or pid = STALL_PID or pid = NAK_PID then
                                        --This is ACK, NAK, or STALL so we are done. Note that in this case we can't 
                                        --need a stuff bit before the EOP because all pids have some 0's.
                send_state <= Send_EOP1;  --go finish with EOP
                                        --Otherwise, this is a data packet front end.
              elsif nbytes = 0 then     --ZLDP
                crc_reg    <= (others => '0');  --this is just the inverted initial FFFF
                send_state <= Send_crc;  --We have decided ZLDPs do have crc bits.
                bitct      <= 1;        --Next bit out is LSB crc bit since we reversed the generator
              else
                send_state <= SendDat2;  --Data: the rest is data followed by CRC16
                byte_index <= 1;        --byte_index range is 8:1
                bit_index  <= 0;        --bit_index range is 7:0
                crc16      <= (others => '1');  --init the crc16 state
              end if;
            else bitct     <= bitct + 1;  --if bitct<16 just count the real bits
            end if;
          end if;

                                        ------Send the data part of a data packet  ----------------
                                        --We've sent sync and pid during Send_Pid.  We now send the data from the out_buf,
                                        --which holds the data latched from send_buf, then send the crc16 bits, and finally EOP. 
        when SendDat2 =>                --Here we send the remaining data bits with crc16 processing    
          if stuffct = 6 then           --check for a stuff bit needed
            stuffct      <= 0;
            dp_out       <= not dp_out;  --send a 0 stuff bit by inverting lines
            dm_out       <= not dm_out;  --this doesn't count as a bit.
          else                          --Keep sending data and updating the crc16 state
            crc16        <= NEW_CRC16(crc16, out_buf(byte_index)(bit_index));
                                        --increment the bit and byte indices for next bit out
            if bit_index < 7 then
              bit_index  <= bit_index + 1;
            else
              bit_index  <= 0;
              byte_index <= byte_index + 1;
            end if;
                                        --concurrently send out the current byte-bit index
            if out_buf(byte_index)(bit_index) = '1' then
              stuffct    <= stuffct + 1;  --leave lines in same state if a 1
            else
              stuffct    <= 0;
              dp_out     <= not dp_out;  --send a 0 bit by changing state.
              dm_out     <= not dm_out;
            end if;
                                        --Concurrently we watch for the last data bit now going out.
            if byte_index = nbytes and bit_index = 7 then
                                        --Last data bit now going out, latch final inverted crc16 bits into crc reg
              crc_reg    <= not NEW_CRC16(crc16, out_buf(byte_index)(7));
              send_state <= Send_crc;   --this state sends the final crc16 bits
              bitct      <= 1;          --Next bit out is LSB crc bit since we reversed the generator
            end if;
          end if;
                                        --End sending data bits. Now go to send_crc for crc16 bits (effectively msb first)

                                        ----Send crc bits lsb (reversed msb) first and then end the packet  -------
                                        --We enter this state after sending the data bits, or after the pid for a ZLDP
                                        --Note that here we have to handle the case of a final stuff bit before the EOP starts.
        when Send_crc  =>               --send 16 crc bits
          if stuffct = 6 then           --Check for a stuff bit needed. 
            stuffct           <= 0;
            dp_out            <= not dp_out;  --send a 0 stuff bit by inverting lines
            dm_out            <= not dm_out;  --this doesn't count as a bit.
                                        --This could be a final stuff bit needed before the EOP, so we check the bitct.
            if bitct >= 16 then         --last crc real bit already went out- end the packet
              --send_state      <= Send_EOP1;  --go do the EOP. --rxd: edge case bug fixed here
              send_state      <= Send_crc; --rxd: changed to keep in this state incase there's a stuff bit at the end
            end if;                        
          else                          --concurrent with sending out the next real bit, we chk if it is the final one.
            if bitct = 16 then          --last real crc bit now going out
                                        ---before starting EOP, make sure a final stuff bit isn't needed
              if crc_reg(bitct) = '1' and stuffct = 5 then
                stuffct       <= 6;
                send_state    <= Send_crc;  --stay for a final stuff bit
              else send_state <= Send_EOP1;  -- otherwise go end the pkt
              end if;
            end if;
            bitct             <= bitct + 1;  --count the real bits
            if crc_reg(bitct) = '1' then  --send the next crc bit
              stuffct         <= stuffct + 1;  --leave lines in same state if a 1
            else
              stuffct         <= 0;
              dp_out          <= not dp_out;  --send a 0 bit by changing state.
              dm_out          <= not dm_out;
            end if;
          end if;
                                        ----End-of-packet sequence  --------------        
        when Send_EOP1 =>               --we take 3 clocks to finish up 
          dp_out              <= '0';   --Send an SEZ (EOP state) for 2 clocks
          dm_out              <= '0';
          send_state          <= Send_EOP2;
        when Send_EOP2 =>
          send_state          <= Send_EOP3;
        when Send_EOP3 =>               --go to idle state which should be the state of the undriven lines.
          dp_out              <= JP;    --Send a J state for 1 clk
          dm_out              <= JM;
          send_state          <= Send_EOP4;
        when Send_EOP4 =>
          output              <= '0';   --tristate line drivers
          sendcompl           <= true;  --signal to state machine #1 that the pkt is sent.                      
          if send_req = false then
            send_state        <= Wait_req;  --go wait for next send request when this one clears.
          end if;
                                        ------End of any outgoing pkt  ----------                
      end case;
    end if;
  end process PSEND_SM;
------------------------------------------------------------
end arch;
