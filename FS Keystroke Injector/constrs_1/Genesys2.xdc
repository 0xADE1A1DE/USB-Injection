# USB Injection - Robbie Dumitru - Constraints file #

## This file is a general .xdc for the Genesys 2 board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project


## Clock Signal
set_property -dict { PACKAGE_PIN AD11  IOSTANDARD LVDS     } [get_ports { inclkn }]; #IO_L12N_T1_MRCC_33 Sch=sysclk_n
set_property -dict { PACKAGE_PIN AD12  IOSTANDARD LVDS     } [get_ports { inclkp }]; #IO_L12P_T1_MRCC_33 Sch=sysclk_p
#create_clock -period 5.000 -name inclkp -waveform {0.000 2.500} -add [get_nets inclkp]

# Clock signal
#set_property PACKAGE_PIN W5 [get_ports clk100]
#set_property IOSTANDARD LVCMOS33 [get_ports clk100]
#create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk100]

# Switches
#set_property PACKAGE_PIN V17 [get_ports reset]
#set_property IOSTANDARD LVCMOS33 [get_ports reset]
#set_property PACKAGE_PIN V16 [get_ports inj]
#set_property IOSTANDARD LVCMOS33 [get_ports inj]
#set_property PACKAGE_PIN W16 [get_ports {DOSswitch}]
#set_property IOSTANDARD LVCMOS33 [get_ports {DOSswitch}]
#set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
#set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
#set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
#set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
#set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
#set_property PACKAGE_PIN V2 [get_ports {sw[8]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
#set_property PACKAGE_PIN T3 [get_ports {sw[9]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
#set_property PACKAGE_PIN T2 [get_ports {sw[10]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
#set_property PACKAGE_PIN R3 [get_ports {sw[11]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
#set_property PACKAGE_PIN W2 [get_ports {sw[12]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
#set_property PACKAGE_PIN U1 [get_ports {sw[13]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
#set_property PACKAGE_PIN T1 [get_ports {sw[14]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
#set_property PACKAGE_PIN R2 [get_ports {sw2}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {sw2}]
### dxr replaced
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS12 } [get_ports { reset }]; #IO_0_17 Sch=sw[0]
set_property -dict { PACKAGE_PIN G25   IOSTANDARD LVCMOS12 } [get_ports { inj }]; #IO_25_16 Sch=sw[1]
set_property -dict { PACKAGE_PIN H24   IOSTANDARD LVCMOS12 } [get_ports { DOSswitch }]; #IO_L19P_T3_16 Sch=sw[2]
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS12 } [get_ports { sw2 }]; #IO_L6P_T0_17 Sch=sw[3]
#set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS12 } [get_ports { sw[4] }]; #IO_L19P_T3_A22_15 Sch=sw[4]
#set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS12 } [get_ports { sw[5] }]; #IO_25_15 Sch=sw[5]
#set_property -dict { PACKAGE_PIN P26   IOSTANDARD LVCMOS33 } [get_ports { sw[6] }]; #IO_L10P_T1_D14_14 Sch=sw[6]
#set_property -dict { PACKAGE_PIN P27   IOSTANDARD LVCMOS33 } [get_ports { sw[7] }]; #IO_L8P_T1_D11_14 Sch=sw[7]

## LEDs
#set_property PACKAGE_PIN U16 [get_ports {led[0]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
#set_property PACKAGE_PIN E19 [get_ports {led[1]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
#set_property PACKAGE_PIN U19 [get_ports fceb]
#set_property IOSTANDARD LVCMOS33 [get_ports fceb]
#set_property PACKAGE_PIN V19 [get_ports {led[3]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
#set_property PACKAGE_PIN W18 [get_ports {led[4]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
#set_property PACKAGE_PIN U15 [get_ports {led[5]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
#set_property PACKAGE_PIN U14 [get_ports {led[6]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
#set_property PACKAGE_PIN V14 [get_ports {led[7]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
#set_property PACKAGE_PIN V13 [get_ports {led[8]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
#set_property PACKAGE_PIN V3 [get_ports {led[9]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
#set_property PACKAGE_PIN W3 [get_ports {led[10]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
#set_property PACKAGE_PIN U3 [get_ports {led[11]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
#set_property PACKAGE_PIN P3 [get_ports {led[12]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
#set_property PACKAGE_PIN N3 [get_ports {led[13]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
#set_property PACKAGE_PIN P1 [get_ports {led[14]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
#set_property PACKAGE_PIN L1 [get_ports {led[15]}]
#	set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]


##7 segment display
#set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
#set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
#set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
#set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
#set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
#set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
#set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

#set_property PACKAGE_PIN V7 [get_ports dp]
#set_property IOSTANDARD LVCMOS33 [get_ports dp]

#set_property PACKAGE_PIN U2 [get_ports {an[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
#set_property PACKAGE_PIN U4 [get_ports {an[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
#set_property PACKAGE_PIN V4 [get_ports {an[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
#set_property PACKAGE_PIN W4 [get_ports {an[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]


##Buttons
#set_property PACKAGE_PIN U18 [get_ports btnC]
#set_property IOSTANDARD LVCMOS33 [get_ports btnC]
#set_property PACKAGE_PIN T18 [get_ports btnU]
#set_property IOSTANDARD LVCMOS33 [get_ports btnU]
#set_property PACKAGE_PIN W19 [get_ports btnL]
#set_property IOSTANDARD LVCMOS33 [get_ports btnL]
#set_property PACKAGE_PIN T17 [get_ports btnR]
#set_property IOSTANDARD LVCMOS33 [get_ports btnR]
#set_property PACKAGE_PIN U17 [get_ports btnD]
#set_property IOSTANDARD LVCMOS33 [get_ports btnD]
### replaced dxr below
## Buttons
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS12 } [get_ports { btnC }]; #IO_25_17 Sch=btnc
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS12 } [get_ports { btnD }]; #IO_0_15 Sch=btnd
set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS12 } [get_ports { btnL }]; #IO_L6P_T0_15 Sch=btnl
set_property -dict { PACKAGE_PIN C19   IOSTANDARD LVCMOS12 } [get_ports { btnR }]; #IO_L24P_T3_17 Sch=btnr
set_property -dict { PACKAGE_PIN B19   IOSTANDARD LVCMOS12 } [get_ports { btnU }]; #IO_L24N_T3_17 Sch=btnu



##Pmod Header JA
##Sch name = JA1
#set_property PACKAGE_PIN J1 [get_ports {JA[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[0]}]
##Sch name = JA2
#set_property PACKAGE_PIN L2 [get_ports {JA[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[1]}]
##Sch name = JA3
#set_property PACKAGE_PIN J2 [get_ports {JA[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[2]}]
##Sch name = JA4
#set_property PACKAGE_PIN G2 [get_ports {JA[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[3]}]
##Sch name = JA7
#set_property PACKAGE_PIN H1 [get_ports {JA[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[4]}]
##Sch name = JA8
#set_property PACKAGE_PIN K2 [get_ports {JA[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[5]}]
##Sch name = JA9
#set_property PACKAGE_PIN H2 [get_ports {JA[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[6]}]
##Sch name = JA10
#set_property PACKAGE_PIN G3 [get_ports {JA[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JA[7]}]


### PMOD Header JB
##set_property -dict { PACKAGE_PIN V30   IOSTANDARD LVCMOS33 } [get_ports { jb[0] }]; #IO_L17N_T2_A13_D29_14 Sch=jb_n[1]
set_property -dict { PACKAGE_PIN V29   IOSTANDARD LVCMOS33 } [get_ports { dplus }];# USB_ULPI_DATA[4] }]; #IO_L17P_T2_A14_D30_14 Sch=jb_p[1]
#set_property -dict { PACKAGE_PIN W26   IOSTANDARD LVCMOS33 } [get_ports { ulpi_nxt_i }]; #IO_L18N_T2_A11_D27_14 Sch=jb_n[2]
set_property -dict { PACKAGE_PIN V25   IOSTANDARD LVCMOS33 } [get_ports { dminus }];# USB_ULPI_DATA[5]}]; #IO_L18P_T2_A12_D28_14 Sch=jb_p[2]
#set_property -dict { PACKAGE_PIN U25   IOSTANDARD LVCMOS33 } [get_ports { ulpi_data_io[4] }]; #IO_L14N_T2_SRCC_14 Sch=jb_n[3]
#set_property -dict { PACKAGE_PIN T25   IOSTANDARD LVCMOS33 } [get_ports { USB_ULPI_DATA[6] }]; #IO_L14P_T2_SRCC_14 Sch=jb_p[3]
#set_property -dict { PACKAGE_PIN U23   IOSTANDARD LVCMOS33 } [get_ports { ulpi_data_io[6] }]; #IO_L21N_T3_DQS_A06_D22_14 Sch=jb_n[4]
#set_property -dict { PACKAGE_PIN U22   IOSTANDARD LVCMOS33 } [get_ports { USB_ULPI_DATA[7] }]; #IO_L21P_T3_DQS_14 Sch=jb_p[4]
### dxr replaced below with above

#Pmod Header JB
#Sch name = JB1
#set_property PACKAGE_PIN A14 [get_ports dplus]
# set_property DRIVE 16 [get_ports {dplus}];  #set drive to 24mA
#set_property IOSTANDARD LVCMOS33 [get_ports dplus]
##Sch name = JB2
#set_property PACKAGE_PIN A16 [get_ports {JB[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[1]}]
#Sch name = JB3
#set_property PACKAGE_PIN B15 [get_ports dminus]
# set_property DRIVE 16 [get_ports {dminus}];  #set drive to 24mA
#set_property IOSTANDARD LVCMOS33 [get_ports dminus]
##Sch name = JB4
#set_property PACKAGE_PIN B16 [get_ports {JB[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[3]}]
##Sch name = JB7
#set_property PACKAGE_PIN A15 [get_ports {JB[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[4]}]
##Sch name = JB8
#set_property PACKAGE_PIN A17 [get_ports {JB[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[5]}]
##Sch name = JB9
#set_property PACKAGE_PIN C15 [get_ports {JB[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[6]}]
##Sch name = JB10
#set_property PACKAGE_PIN C16 [get_ports {JB[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JB[7]}]



##Pmod Header JC
##Sch name = JC1
#set_property PACKAGE_PIN K17 [get_ports {JC[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JC[0]}]
##Sch name = JC2
#set_property PACKAGE_PIN M18 [get_ports {JC[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JC[1]}]
##Sch name = JC3
#set_property PACKAGE_PIN N17 [get_ports {JC[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JC[2]}]
##Sch name = JC4
#set_property PACKAGE_PIN P18 [get_ports {JC[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JC[3]}]
##Sch name = JC7
#set_property PACKAGE_PIN L17 [get_ports {JC[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JC[4]}]
##Sch name = JC8
#set_property PACKAGE_PIN M19 [get_ports {JC[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JC[5]}]
##Sch name = JC9
#set_property PACKAGE_PIN P17 [get_ports {JC[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JC[6]}]
##Sch name = JC10
#set_property PACKAGE_PIN R18 [get_ports {JC[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JC[7]}]


##Pmod Header JXADC
##Sch name = XA1_P
#set_property PACKAGE_PIN J3 [get_ports {JXADC[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[0]}]
##Sch name = XA2_P
#set_property PACKAGE_PIN L3 [get_ports {JXADC[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[1]}]
##Sch name = XA3_P
#set_property PACKAGE_PIN M2 [get_ports {JXADC[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[2]}]
##Sch name = XA4_P
#set_property PACKAGE_PIN N2 [get_ports {JXADC[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[3]}]
##Sch name = XA1_N
#set_property PACKAGE_PIN K3 [get_ports {JXADC[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[4]}]
##Sch name = XA2_N
#set_property PACKAGE_PIN M3 [get_ports {JXADC[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[5]}]
##Sch name = XA3_N
#set_property PACKAGE_PIN M1 [get_ports {JXADC[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[6]}]
##Sch name = XA4_N
#set_property PACKAGE_PIN N1 [get_ports {JXADC[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[7]}]



##VGA Connector
#set_property PACKAGE_PIN G19 [get_ports {vgaRed[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[0]}]
#set_property PACKAGE_PIN H19 [get_ports {vgaRed[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[1]}]
#set_property PACKAGE_PIN J19 [get_ports {vgaRed[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[2]}]
#set_property PACKAGE_PIN N19 [get_ports {vgaRed[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[3]}]
#set_property PACKAGE_PIN N18 [get_ports {vgaBlue[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[0]}]
#set_property PACKAGE_PIN L18 [get_ports {vgaBlue[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[1]}]
#set_property PACKAGE_PIN K18 [get_ports {vgaBlue[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[2]}]
#set_property PACKAGE_PIN J18 [get_ports {vgaBlue[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[3]}]
#set_property PACKAGE_PIN J17 [get_ports {vgaGreen[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[0]}]
#set_property PACKAGE_PIN H17 [get_ports {vgaGreen[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[1]}]
#set_property PACKAGE_PIN G17 [get_ports {vgaGreen[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[2]}]
#set_property PACKAGE_PIN D17 [get_ports {vgaGreen[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[3]}]
#set_property PACKAGE_PIN P19 [get_ports Hsync]
#set_property IOSTANDARD LVCMOS33 [get_ports Hsync]
#set_property PACKAGE_PIN R19 [get_ports Vsync]
#set_property IOSTANDARD LVCMOS33 [get_ports Vsync]


###USB-RS232 Interface
##set_property PACKAGE_PIN B18 [get_ports RsRx]
#	#set_property IOSTANDARD LVCMOS33 [get_ports RsRx]
#set_property PACKAGE_PIN A18 [get_ports tx]
#	set_property IOSTANDARD LVCMOS33 [get_ports tx]


##USB HID (PS/2)
#set_property PACKAGE_PIN C17 [get_ports PS2Clk]
#	set_property IOSTANDARD LVCMOS33 [get_ports PS2Clk]
#	set_property PULLUP true [get_ports PS2Clk]
#set_property PACKAGE_PIN B17 [get_ports PS2Data]
#	set_property IOSTANDARD LVCMOS33 [get_ports PS2Data]
#	set_property PULLUP true [get_ports PS2Data]


##Quad SPI Flash
##Note that CCLK_0 cannot be placed in 7 series devices. You can access it using the
##STARTUPE2 primitive.
#set_property PACKAGE_PIN D18 [get_ports {QspiDB[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[0]}]
#set_property PACKAGE_PIN D19 [get_ports {QspiDB[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[1]}]
#set_property PACKAGE_PIN G18 [get_ports {QspiDB[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[2]}]
#set_property PACKAGE_PIN F18 [get_ports {QspiDB[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[3]}]
#set_property PACKAGE_PIN K19 [get_ports QspiCSn]
#set_property IOSTANDARD LVCMOS33 [get_ports QspiCSn]


#set_property DRIVE 16 [get_ports dminus]
#set_property DRIVE 16 [get_ports dplus]
#set_property SLEW FAST [get_ports dminus]
#set_property SLEW FAST [get_ports dplus]


#set_property CONFIG_VOLTAGE 3.3 [current_design]
#set_property CFGBVS VCCO [current_design]