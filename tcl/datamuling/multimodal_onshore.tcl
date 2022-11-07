# Copyright (c) 2020 Regents of the SIGNET lab, University of Padova.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University of Padova (SIGNET lab) nor the 
#    names of its contributors may be used to endorse or promote products 
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Author: Roberto Francescon
# Version: 1.0.0
# File: multimodal_onshore.tcl
#

# if set to 1 the Application listen from the socket port provided in input
set opt(AppSocket)  1;
# Protocol to use for the Application socket, TCP or UDP
set opt(protocol) "TCP" ;
# Set network addresses
set opt(net_src) 3
set opt(net_dst) 2

##############################
# Terminal's parameter check #
##############################
if {$opt(AppSocket) == 1} {
  if {$argc != 8} {
    puts "Multimodal on-shore: the script needs 8 input to work"
    puts "1 - Start time"
    puts "2 - Stop time"
	puts "3 - Packet generation period (0 if the node doesn't generate data)"
	puts "4 - IP of the modem"
    puts "5 - Port of the modem"
    puts "6 - Application socket port"
    puts "7 - Maximum read size"
    puts "8 - Experiment ID"
    puts "Please try again."
    exit
  } else {
    set opt(node)     67
    set opt(dest)     66
    set opt(start)    [lindex $argv 0]
    set opt(stop)     [lindex $argv 1]
    set opt(traffic)  [lindex $argv 2]
    set opt(ip)       [lindex $argv 3]
    set opt(port)     [lindex $argv 4]
    set opt(app_port) [lindex $argv 5]
    set opt(max_read) [lindex $argv 6]
    set opt(exp_ID)   [lindex $argv 7]
  }
} else {
  if {$argc != 7} {
    puts "Multimodal on-shore: the script needs 10 input to work"
    puts "1 - Start time"
    puts "2 - Stop time"
    puts "3 - Packet generation period (0 if the node doesn't generate data)"
    puts "4 - IP of the modem"
    puts "5 - Port of the modem"
    puts "6 - Payload size (byte)"
    puts "7 - Experiment ID"
    puts "Please try again."
    exit
  } else {
    set opt(node)     67
    set opt(dest)     66
    set opt(start)    [lindex $argv 0]
    set opt(stop)     [lindex $argv 1]
    set opt(traffic)  [lindex $argv 2]
    set opt(ip)       [lindex $argv 3]
    set opt(port)     [lindex $argv 4]
    set opt(payload_size) [lindex $argv 5]
    set opt(exp_ID)   [lindex $argv 6]
  }
}

#####################
# Library Loading   #
#####################
# Load here all the NS-Miracle libraries you need
load libMiracle.so
load libmphy.so
load libmmac.so
load libuwip.so
load libuwmll.so
load libuwstaticrouting.so
load libuwudp.so
load libuwapplication.so
load libpackeruwapplication.so
load libuwal.so
load libpackeruwip.so
load libpackercommon.so
load libpackermac.so
load libuwcbr.so
load libuwmmac_clmsgs.so
# load libuwtdma.so
load libuwcsmaaloha.so
load libpackeruwudp.so
load libuwphy_clmsgs.so
load libuwconnector.so
load libuwmodem.so
load libuwmodemcsa.so
load libuwmulti_destination.so

#############################
# NS-Miracle initialization #
#############################
# You always need the following two lines to use the NS-Miracle simulator
set ns [new Simulator]
$ns use-Miracle

#Declare the use of a Real Time Schedule (necessary for the interfacing with real hardware)
$ns use-scheduler RealTime

##################
# Tcl variables  #
##################
# address and port of the EvoLogics modem
set remote_address "${opt(ip)}:${opt(port)}"

# set MAC address for the EvoLogics modem
set addrMAC $opt(node)

# time when actually to stop the simulation
set time_stop [expr "$opt(stop)+5"]

#Trace file name
set tf_name "./multimodal_test_shorenode.tr"

#Open a file for writing the trace data
set tf [open $tf_name w]
$ns trace-all $tf

set rng [new RNG]
$rng seed         $opt(node)

set rnd_gen [new RandomVariable/Uniform]
$rnd_gen use-rng $rng

#########################
# Module Configuration  #
#########################
# Put here all the commands to set globally the initialization values of
# the binded variables (optional)

# variables for the AL module
Module/UW/AL set Dbit 0
Module/UW/AL set PSDU 1400
Module/UW/AL set debug_ 0
Module/UW/AL set interframe_period 0.e1
Module/UW/AL set frame_set_validity 0

# variables for the packer(s)
UW/AL/Packer set SRC_ID_Bits 8
UW/AL/Packer set PKT_ID_Bits 8
UW/AL/Packer set FRAME_OFFSET_Bits 1; #0
UW/AL/Packer set M_BIT_Bits 1
UW/AL/Packer set DUMMY_CONTENT_Bits 0
UW/AL/Packer set debug_ 1

NS2/COMMON/Packer set PTYPE_Bits 16
NS2/COMMON/Packer set SIZE_Bits 8
NS2/COMMON/Packer set UID_Bits 8
NS2/COMMON/Packer set ERROR_Bits 0
NS2/COMMON/Packer set TIMESTAMP_Bits 8
NS2/COMMON/Packer set PREV_HOP_Bits 8
NS2/COMMON/Packer set NEXT_HOP_Bits 8
NS2/COMMON/Packer set ADRR_TYPE_Bits 0
NS2/COMMON/Packer set LAST_HOP_Bits 0
NS2/COMMON/Packer set TXTIME_Bits 0
NS2/COMMON/Packer set debug_ 10

UW/IP/Packer set SAddr_Bits 8
UW/IP/Packer set DAddr_Bits 8
UW/IP/Packer set debug_ 1

NS2/MAC/Packer set Ftype_Bits 0
NS2/MAC/Packer set SRC_Bits 8
NS2/MAC/Packer set DST_Bits 8
NS2/MAC/Packer set Htype_Bits 0
NS2/MAC/Packer set TXtime_Bits 0
NS2/MAC/Packer set SStime_Bits 0
NS2/MAC/Packer set Padding_Bits 0
NS2/MAC/Packer set debug_ 1

UW/UDP/Packer set SPort_Bits 2
UW/UDP/Packer set DPort_Bits 2
UW/UDP/Packer set debug_ 1

UW/APP/uwApplication/Packer set SN_FIELD_ 16
UW/APP/uwApplication/Packer set RFFT_FIELD_ 0
UW/APP/uwApplication/Packer set RFFTVALID_FIELD_ 0
UW/APP/uwApplication/Packer set PRIORITY_FIELD_ 1
UW/APP/uwApplication/Packer set PAYLOADMSG_FIELD_SIZE_ 8
UW/APP/uwApplication/Packer set debug_ 1

Module/UW/APPLICATION set debug_ 1
Module/UW/APPLICATION set period_ $opt(traffic)
Module/UW/APPLICATION set PoissonTraffic_ 0
if {$opt(AppSocket) == 1} {
  Module/UW/APPLICATION set Socket_Port_ $opt(app_port)
  Module/UW/APPLICATION set max_read_length $opt(max_read)
} else {
  Module/UW/APPLICATION set Payload_size_ $opt(payload_size)
}
Module/UW/APPLICATION set drop_out_of_order_ 0  
Module/UW/APPLICATION set pattern_sequence_ 0     
Module/UW/APPLICATION set EXP_ID_ $opt(exp_ID)

# variables for the CSA modem's interface
Module/UW/UwModem/ModemCSA set buffer_size   4096
Module/UW/UwModem/ModemCSA set max_read_size 4096

# variables for the TDMA / CSMA-Aloha
# Module/UW/TDMA set fair_mode            0
# Module/UW/TDMA set tot_slots            1
# Module/UW/TDMA set guard_time           0
# Module/UW/TDMA set frame_duration       10
# Module/UW/TDMA set max_packet_per_slot  0
# Module/UW/TDMA set queue_size_          5
# Module/UW/TDMA set drop_old_            0
# Module/UW/TDMA set sea_trial_           0
# Module/UW/TDMA set debug_               1
Module/UW/CSMA_ALOHA set max_tx_tries_      0
Module/UW/CSMA_ALOHA set wait_costant_      0.0001
Module/UW/CSMA_ALOHA set debug_             0
Module/UW/CSMA_ALOHA set backoff_tuner_     0
Module/UW/CSMA_ALOHA set max_payload_       1250
Module/UW/CSMA_ALOHA set ACK_timeout_       1.0
Module/UW/CSMA_ALOHA set alpha_             0.8
Module/UW/CSMA_ALOHA set buffer_pkts_       -1
Module/UW/CSMA_ALOHA set max_backoff_counter_ 0
Module/UW/CSMA_ALOHA set listen_time_       0.0001
Module/UW/CSMA_ALOHA set MAC_addr_          0

################################
# Procedure(s) to create nodes #
################################
# Define here one or more procedures that allow you to create as many different kind of nodes
proc createNode { } {
	global ns opt socket_port node_ remote_address
	global app_ transport_ port_ routing_ ipif_ mac_ modem_ ipif_ mll_ uwal_ app_sink

	    # build the NS-Miracle node
    set node_ [$ns create-M_Node]

    # define the module(s) you want to put in the node
    # APPLICATION LAYER
    set app_ [new Module/UW/APPLICATION]
    
    # TRANSPORT LAYER
    set transport_ [new Module/UW/UDP]

    # NETWORK LAYER
    # Static Routing
    set routing_ [new Module/UW/StaticRouting]
	
    # IP interface
    set ipif_ [new Module/UW/IP]
	
    # DATA LINK LAYER - MEDIA LINK LAYER
    set mll_ [new Module/UW/MLL]
    
    # DATA LINK LAYER - MAC LAYER
    set mac_ [new Module/UW/CSMA_ALOHA]
	$mac_ setNoAckMode
    $mac_ initialize

    set uwal_ [new Module/UW/AL]

    # PHY LAYER
    set modem_ [new Module/UW/UwModem/ModemCSA]

	puts "Creating node..."

	    # insert the module(s) into the node
	$node_ addModule 8 $app_ 1 "UWA"
	$node_ addModule 7 $transport_ 1 "UDP"
	$node_ addModule 6 $routing_ 1 "IPR"
	$node_ addModule 5 $ipif_ 1 "IPIF"
	$node_ addModule 4 $mll_ 1 "ARP"  
	$node_ addModule 3 $mac_ 1 "ALOHA"
	$node_ addModule 2 $uwal_ 1 "UWAL"
	$node_ addModule 1 $modem_ 1 "CSA" 

	$node_ setConnection $app_ $transport_ trace
    $node_ setConnection $transport_ $routing_ trace
    $node_ setConnection $routing_ $ipif_ trace
    $node_ setConnection $ipif_ $mll_ trace
    $node_ setConnection $mll_ $mac_ trace
    $node_ setConnection $mac_ $uwal_ trace
    $node_ setConnection $uwal_ $modem_ trace

	# assign a port number to the application considered (uwApplication)
    set port_ [$transport_ assignPort $app_]
    $ipif_ addr $opt(net_src)
    $mac_ setMacAddr 67
	# configure CSA/TCP modem
    $modem_ set ID_ 67
	puts "DIOCANN::::address::$remote_address"
	$modem_ setModemAddress $remote_address
	$modem_ setTCP
    $modem_ setLogLevel "DBG"

    # set packer for Adaptation Layer
    set packer_ [new UW/AL/Packer]

    set packer_payload0 [new NS2/COMMON/Packer]  
    set packer_payload1 [new UW/IP/Packer]
    set packer_payload2 [new NS2/MAC/Packer]
    set packer_payload3 [new UW/UDP/Packer]
    set packer_payload4 [new UW/APP/uwApplication/Packer]
    #$packer_payload4 printAllFields
    $packer_payload4 printMap

    $packer_ addPacker $packer_payload0
    $packer_ addPacker $packer_payload1
    $packer_ addPacker $packer_payload2
    $packer_ addPacker $packer_payload3
    $packer_ addPacker $packer_payload4
    if {$opt(AppSocket) == 1} {
        $app_ setSocketProtocol $opt(protocol)
        $app_ set Socket_Port_ $opt(app_port)
    } else {
      $app_ setSocketProtocol "NONE"
    }
    $app_ set node_ID_ 3
    # $app_ print_log

    $uwal_ linkPacker $packer_
    
    $uwal_ set nodeID $opt(node)

	
}

#################
# Node Creation #
#################
# Create here all the nodes you want to network together
createNode

################################
# Inter-node module connection #
################################
# Put here all the commands required to connect nodes in the network (optional), namely, specify end to end connections, fill ARP tables, define routing settings

# connections at the application level
$app_ set destAddr_ [expr $opt(dest)]
$app_ set destPort_ 1


$routing_ addRoute $opt(net_dst) $opt(net_dst)
$mll_ addentry  $opt(net_dst) $opt(dest)
$mll_ addentry  $opt(net_src) $opt(node)

#####################
# Start/Stop Timers #
#####################
# Set here the timers to start and/or stop modules (optional)
# e.g., 

# $ns at 0 "$mac_ start"
$ns at 0 "$modem_ start"

if {$opt(traffic) != 0} {
  $ns at $opt(start) "$app_ start"
  $ns at $opt(stop) "$app_ stop"
}

$ns at $time_stop "$modem_ stop"
# $ns at $time_stop "$mac_ stop"

###################
# Final Procedure #
###################
# Define here the procedure to call at the end of the simulation
proc finish {} {
   
   global ns tf tf_name	
   # computation of the statics

   # display messages
   puts "Done!"
   #puts "tracefile: $tf_name"

   # save traces
   $ns flush-trace
   
   # close files
   close $tf
}

##################
# Run simulation #
##################
# Specify the time at which to call the finish procedure and halt ns

$ns at [expr $time_stop] "finish; $ns halt"

# You always need the following line to run the NS-Miracle simulator
$ns run
