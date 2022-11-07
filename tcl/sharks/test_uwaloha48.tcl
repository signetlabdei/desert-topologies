#
# Copyright (c) 2015 Regents of the SIGNET lab, University of Padova.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University of Padova (SIGNET lab) nor the 
#  names of its contributors may be used to endorse or promote products 
#  derived from this software without specific prior written permission.
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
# This script is used to test UW-TDMA protocol
# with a CBR (Constant Bit Rate) Application Module
# Here the complete stack used for each node in the simulation
#
# N.B.: UnderwaterChannel and UW/PHYSICAL are used for PHY layer and channel
#
# Authors: Filippo Campagnaro <campagn1@dei.unipd.it>
# Version: 1.0.0
#
# NOTE: tcl sample tested on Ubuntu 11.10, 64/32 bits OS
#
# Stack of the nodes
#   +-------------------------+
#   |  7. UW/CBR        |
#   +-------------------------+
#   |  6. UW/UDP        |
#   +-------------------------+
#   |  5. UW/STATICROUTING  |
#   +-------------------------+
#   |  4. UW/IP         |
#   +-------------------------+
#   |  3. UW/MLL        |
#   +-------------------------+
#   |  2. UW/TDMA       |
#   +-------------------------+
#   |  1. UW/PHYSICAL     |
#   +-------------------------+
#       |     |  
#   +-------------------------+
#   |   UnderwaterChannel   |
#   +-------------------------+

######################################
# Flags to enable or disable options #
######################################
set opt(verbose) 		1
set opt(trace_files)		1
set opt(bash_parameters) 	0

#####################
# Library Loading   #
#####################
load libMiracle.so
load libMiracleWirelessCh.so 
load libMiracleBasicMovement.so
load libuwip.so
load libuwstaticrouting.so
load libmphy.so
load libmmac.so
load libuwmll.so
load libuwudp.so
load libuwcbr.so
load libuwsmposition.so
load libuwtracker.so
load libuwinterference.so
load libUwmStd.so
load libUwmStdPhyBpskTracer.so
load libuwphy_clmsgs.so
load libuwstats_utilities.so
load libuwphysical.so
load libuwmmac_clmsgs.so
load libuwcsmaaloha.so
load libuwahoi_phy.so

#############################
# NS-Miracle initialization #
#############################
# You always need the following two lines to use the NS-Miracle simulator
set ns [new Simulator]
$ns use-Miracle

##################
# Tcl variables  #
##################
set opt(start_clock) [clock seconds]

set opt(nn)         48 ;# Number of Nodes
set opt(starttime)      1	
set opt(stoptime)       10001
set opt(txduration)     [expr $opt(stoptime) - $opt(starttime)] ;# Duration of the simulation
set opt(txpower)      156.0;#158.263 ;#Power transmitted in dB re uPa 185.8 is the maximum
set opt(propagation_speed) 1500;# m/s

set opt(maxinterval_)     200
set opt(freq)               50000.0 ;#Frequency used in Hz
set opt(bw)                 25000.0 ;#Bandwidth used in Hz
set opt(bitrate)      195.3 ;#150000;#bitrate in bps
set opt(ack_mode)           "setNoAckMode"

set rng [new RNG]

if {$opt(bash_parameters)} {
	if {$argc != 1} {
		puts "The script requires three inputs:"
		puts "- the first for the seed"
		puts "- the second one is for the Poisson CBR period"
		puts "- the third one is the cbr packet size (byte);"
		puts "example: ns TDMA_exp.tcl 1 60 125"
		puts "If you want to leave the default values, please set to 0"
		puts "the value opt(bash_parameters) in the tcl script"
		puts "Please try again."
		return
	} else {
		set opt(seedcbr)  [lindex $argv 0]
	}
} else {
	set opt(seedcbr)	1
}
$rng seed     $opt(seedcbr)
set opt(pktsize)  32
set opt(cbr_period)   3
set opt(poisson_traffic) 0

set rnd_gen [new RandomVariable/Uniform]
$rnd_gen use-rng $rng
if {$opt(trace_files)} {
	set opt(tracefilename) "./test_uwtdma_frame.tr"
	set opt(tracefile) [open $opt(tracefilename) w]
	set opt(cltracefilename) "./test_uwtdma_frame.cltr"
	set opt(cltracefile) [open $opt(tracefilename) w]
} else {
	set opt(tracefilename) "/dev/null"
	set opt(tracefile) [open $opt(tracefilename) w]
	set opt(cltracefilename) "/dev/null"
	set opt(cltracefile) [open $opt(cltracefilename) w]
}


#########################
# Module Configuration  #
#########################
### APP ###
Module/UW/CBR set packetSize_    $opt(pktsize)
Module/UW/CBR set PoissonTraffic_  $opt(poisson_traffic)
Module/UW/CBR set period_     $opt(cbr_period)
Module/UW/CBR set debug_       0
Module/UW/CBR set tracefile_enabler_       1

Module/UW/TRACKER set max_tracking_distance_ 50
Module/UW/TRACKER set packetSize_    $opt(pktsize)
Module/UW/TRACKER set PoissonTraffic_  $opt(poisson_traffic)
Module/UW/TRACKER set period_     $opt(cbr_period)
Module/UW/TRACKER set debug_       0
Module/UW/TRACKER set tracefile_enabler_       1
Module/UW/TRACKER set send_only_active_trace_ 1

### Channel ###
MPropagation/Underwater set practicalSpreading_ 2
MPropagation/Underwater set debug_        0
MPropagation/Underwater set windspeed_      10
MPropagation/Underwater set shipping_       1

set channel [new Module/UnderwaterChannel]
set propagation [new MPropagation/Underwater]
set data_mask [new MSpectralMask/Rect]
$data_mask setFreq        $opt(freq)
$data_mask setBandwidth     $opt(bw)
$data_mask setPropagationSpeed  $opt(propagation_speed)

### MAC ###
Module/UW/CSMA_ALOHA set listen_time_     1

### PHY ###
Module/UW/AHOI/PHY  set BitRate_                    $opt(bitrate)
Module/UW/AHOI/PHY  set AcquisitionThreshold_dB_    5.0 
Module/UW/AHOI/PHY  set RxSnrPenalty_dB_            0
Module/UW/AHOI/PHY  set TxSPLMargin_dB_             0
Module/UW/AHOI/PHY  set MaxTxSPL_dB_                $opt(txpower)
Module/UW/AHOI/PHY  set MinTxSPL_dB_                10
Module/UW/AHOI/PHY  set MaxTxRange_                 200
Module/UW/AHOI/PHY  set PER_target_                 0    
Module/UW/AHOI/PHY  set CentralFreqOptimization_    0
Module/UW/AHOI/PHY  set BandwidthOptimization_      0
Module/UW/AHOI/PHY  set SPLOptimization_            0
Module/UW/AHOI/PHY  set debug_                      0
################################
# Procedure(s) to create nodes #
################################
proc createNode { id } {

  global channel ns cbr position node udp portnum portnumH ipr ipif
  global opt mll mac propagation data_mask interf_data
  
  set node($id) [$ns create-M_Node $opt(tracefile) $opt(cltracefile)] 
	for {set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
		set cbr($id,$cnt)  [new Module/UW/TRACKER] 
	}
  set udp($id)  [new Module/UW/UDP]
  set ipr($id)  [new Module/UW/StaticRouting]
  set ipif($id) [new Module/UW/IP]
  set mll($id)  [new Module/UW/MLL] 
  set mac($id)  [new Module/UW/CSMA_ALOHA]
  set phy($id)  [new Module/UW/AHOI/PHY]  
	
  for {set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
    $node($id) addModule 7 $cbr($id,$cnt)   1  "CBR"
  }

  $node($id) addModule 6 $udp($id)   1  "UDP"
  $node($id) addModule 5 $ipr($id)   1  "IPR"
  $node($id) addModule 4 $ipif($id)  1  "IPF"   
  $node($id) addModule 3 $mll($id)   1  "MLL"
  $node($id) addModule 2 $mac($id)   1  "MAC"
  $node($id) addModule 1 $phy($id)   1  "PHY"

  for {set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
    $node($id) setConnection $cbr($id,$cnt)   $udp($id)   0
    set portnum($id,$cnt) [$udp($id) assignPort $cbr($id,$cnt) ]
  }

  $node($id) setConnection $udp($id)   $ipr($id)   1
  $node($id) setConnection $ipr($id)   $ipif($id)  1
  $node($id) setConnection $ipif($id)  $mll($id)   1
  $node($id) setConnection $mll($id)   $mac($id)   1
  $node($id) setConnection $mac($id)   $phy($id)   1
  $node($id) addToChannel  $channel    $phy($id)   1


  #Set the IP address of the node
  #$ipif($id) addr "1.0.0.${id}"
  $ipif($id) addr [expr $id + 1]
  
  # Set the MAC address
  $mac($id) $opt(ack_mode)
  $mac($id) initialize

  Position/BM set debug_ 1
  set position($id) [new "Position/BM"]
  $node($id) addPosition $position($id)
  
  #Interference model
  set interf_data($id)  [new "Module/UW/INTERFERENCE"]
  $interf_data($id) set maxinterval_ $opt(maxinterval_)
  $interf_data($id) set debug_     0

  #Propagation model
  $phy($id) setPropagation $propagation
  
  $phy($id) setSpectralMask $data_mask
  $phy($id) setInterference $interf_data($id)
  $phy($id) setInterferenceModel "MEANPOWER"
  $phy($id) setRangePDRFileName "../dbs/ahoi/default_pdr.csv"
  #$phy($id) setRangePDRFileName "../dbs/ahoi/dumb_pdr.csv"
  $phy($id) setSIRFileName "../dbs/ahoi/default_sir.csv"
  #$phy($id) setSIRFileName "../dbs/ahoi/dumb_sir.csv"
  $phy($id) initLUT

}

#################
# Node Creation #
#################
# Create here all the nodes you want to network together
for {set id 0} {$id < $opt(nn)} {incr id}  {
  createNode $id
  puts "Node $id created"
}
Position/UWSM set debug_ 0
set shark_position [new "Position/UWSM"]
source "position48.tcl"

################################
# Inter-node module connection #
################################
proc connectNodes {id1 des1} {
  global ipif ipr portnum cbr opt 
  $cbr($id1,$des1) set destAddr_ [$ipif($des1) addr]
  $cbr($id1,$des1) set destPort_ $portnum($des1,$id1)
}

##################
# Setup flows  #
##################
for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
  for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
    if {$id1 != $id2} {
	     connectNodes $id1 $id2
    }
  }
}

###################
# Fill ARP tables #
###################
for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
  for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
	   $mll($id1) addentry [$ipif($id2) addr] [$mac($id2) addr]
  }
}



########################
# Setup routing tables #
########################
for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
  for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
    if {$id1 != $id2} {
      $ipr($id1) addRoute [$ipif($id2) addr] [$ipif($id2) addr]
    }
  }
}




#####################
# Start/Stop Timers #
#####################
# Set here the timers to start and/or stop modules (optional)
# e.g., 
# Set here the timers to start and/or stop modules (optional)
# e.g., 

for {set dest_id 1} {$dest_id < [expr $opt(nn)/4]} {set dest_id [expr $dest_id + 3]}  {
  puts "dest_id =  $dest_id"
  set id_src [expr $dest_id - 1]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
  set id_src [expr $dest_id + 1]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"  
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
  set id_src [expr $dest_id + $opt(nn)/4 - 1]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
  set id_src [expr $dest_id + $opt(nn)/4]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
  set id_src [expr $dest_id + $opt(nn)/4 + 1]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
}; 

for {set dest_id [expr 1 + $opt(nn)/2]} {$dest_id < [expr 3*$opt(nn)/4]} {set dest_id [expr $dest_id + 3]}  {
  puts "dest_id =  $dest_id"
  set id_src [expr $dest_id - 1]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
  set id_src [expr $dest_id + 1]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"  
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
  set id_src [expr $dest_id + $opt(nn)/4 - 1]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
  set id_src [expr $dest_id + $opt(nn)/4]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
  set id_src [expr $dest_id + $opt(nn)/4 + 1]
  puts "id_src =  $id_src"
  $cbr($dest_id,$id_src) setLogSuffix "[expr $dest_id+1],[expr $id_src+1]"
  $cbr($id_src,$dest_id) setTrack $shark_position
  $ns at $opt(starttime)  "$cbr($id_src,$dest_id) start"
  $ns at $opt(stoptime)   "$cbr($id_src,$dest_id) stop"
}; 

###################
# Final Procedure #
###################
# Define here the procedure to call at the end of the simulation
proc finish {} {
  global ns opt outfile
  global mac propagation phy_data channel db_manager propagation
  global node_coordinates 
  global ipr ipif udp cbr phy 
  global node_stats tmp_node_stats
  if ($opt(verbose)) {
    puts "-----------------------------------------------------------------"
    puts "Simulation summary"
    puts "-----------------------------------------------------------------"
    puts "Total simulation time  : [expr $opt(stoptime)-$opt(starttime)] s"
    puts "Number of nodes      : $opt(nn)"
    puts "Packet size        : $opt(pktsize) byte(s)"
    puts "Control CBR period         : $opt(cbr_period) s"
    puts "-----------------------------------------------------------------"
  }

  set sum_cbr_throughput  0
  set sum_mac_sent_pkts   0
  set sum_mac_recv_pkts   0  
  set sum_sent_pkts   0.0
  set sum_recv_pkts   0.0  
  set sum_pcks_in_buffer  0
  set sum_upper_pcks_rx   0
  set sum_mac_pcks_tx     0
  set sent_pkts 0
  set recv_pkts 0

  for {set i 0} {$i < $opt(nn)} {incr i}  {

  	set mac_sent_pkts    [$mac($i) getDataPktsTx]
  	set mac_recv_pkts    [$mac($i) getDataPktsRx]

    puts "MAC received Packets($i)   : $mac_recv_pkts"

    set sum_mac_pcks_tx  [expr $sum_mac_pcks_tx + $mac_sent_pkts]
    set sum_mac_recv_pkts  [expr $sum_mac_recv_pkts + $mac_recv_pkts]
  }
 
  if ($opt(verbose)) {
    puts "MAC tot sent Packets     : $sum_mac_pcks_tx"
    puts "MAC tot received Packets   : $sum_mac_recv_pkts"
  }
  
  $ns flush-trace
  close $opt(tracefile)
}


###################
# start simulation
###################
if ($opt(verbose)) {
  puts "\nStarting Simulation\n"
}


$ns at [expr $opt(stoptime) + 50.0]  "finish; $ns halt" 

$ns run
