#
# Copyright (c) 2021 Regents of the SIGNET lab, University of Padova.
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
# This script is used to test UW-PHYSICAL layer
# There are 4 nodes in fixed positions that can transmit each other 
# packets with a CBR (Constant Bit Rate) Application Module
#
#
# Author: Nicola Toffolo
# Version: 1.0.0
#
# NOTE: tcl sample tested on Ubuntu 20.04, 64 bits OS
#
# Stack of the nodes
#   +-------------------------+
#   |  7. UW/CBR              |
#   +-------------------------+
#   |  6. UW/UDP              |
#   +-------------------------+
#   |  5. UW/STATICROUTING    |
#   +-------------------------+
#   |  4. UW/IP               |
#   +-------------------------+
#   |  3. UW/MLL              |
#   +-------------------------+
#   |  2. UW/TDMA             |
#   +-------------------------+
#   |  1. UW/PHYSICAL         |
#   +-------------------------+
#           |         |    
#   +-------------------------+
#   |    UnderwaterChannel    |
#   +-------------------------+

######################################
# Flags to enable or disable options #
######################################
set opt(verbose) 			    0
set opt(trace_files)		  0
set opt(bash_parameters) 	1
set opt(results_file)     1

#####################
# Library Loading   #
#####################
load libMiracle.so
load libMiracleBasicMovement.so
load libmphy.so
load libmmac.so
load libuwip.so
load libuwstaticrouting.so
load libuwmll.so
load libuwudp.so
load libuwrov.so
load libuwmmac_clmsgs.so
load libuwtdma.so
load libuwcbr.so
load libuwinterference.so
load libUwmStd.so
load libUwmStdPhyBpskTracer.so
load libuwphy_clmsgs.so
load libuwstats_utilities.so
load libuwphysical.so
load libuwhmmphysical.so

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
set opt(rep_num)     10

if {$opt(bash_parameters)} {
	if {$argc != 1} {
		puts "This script requires a single parameter in input,"
		puts "that is, the repetition number rep_num, to compute"
		puts "the confidence intervals."
		puts "Please try again or set bash_parameters=0 in the script."
		exit 1
	} else {
		set opt(rep_num)       [lindex $argv 0]
	}
}

set opt(nn)                 4 ;# Number of Nodes
set opt(pktsize)            28 ;# Pkt size in byte
set opt(starttime)          1	
set opt(stoptime)           18000
set opt(midtime)            [expr ($opt(stoptime) - $opt(starttime))/2]
set opt(time_interval)      300 ;# Every time_interval seconds we compute PER and THR
set opt(txduration)         [expr $opt(stoptime) - $opt(starttime)] ;# Duration of the simulation
set opt(txpower)            165.0 ;#Power transmitted in dB re uPa
set opt(maxinterval_)       20.0
set opt(freq)               25000.0 ;#Frequency used in Hz
set opt(bw)                 5000.0 ;#Bandwidth used in Hz
set opt(bitrate)            600.0 ;#bitrate in bps
set opt(ack_mode)           "setNoAckMode"
set opt(cbr_period)         60

###########################
#Random Number Generators #
###########################

global rng
set rng [new RNG]
$rng default

for {set k 0} {$k < $opt(rep_num)} {incr k} {
     $rng next-substream
		 $rng next-substream
		 $rng next-substream
}


###############################
#Trace files and Results file #
###############################

if {$opt(trace_files)} {
	set opt(tracefilename) "./test_haifaphy.tr"
	set opt(tracefile) [open $opt(tracefilename) w]
	set opt(cltracefilename) "./test_haifaphy.cltr"
	set opt(cltracefile) [open $opt(tracefilename) w]
} else {
	set opt(tracefilename) "/dev/null"
	set opt(tracefile) [open $opt(tracefilename) w]
	set opt(cltracefilename) "/dev/null"
	set opt(cltracefile) [open $opt(cltracefilename) w]
}

if {$opt(results_file)} {
	set opt(resultsfilename) "./test_haifaphyresults.txt"
	set opt(resultsfilename) [open $opt(resultsfilename) a+]
	set opt(thrfilename) "./test_haifaphythr.txt"
	set opt(thrfilename) [open $opt(thrfilename) a+]
} else {
	set opt(resultsfilename) "/dev/null"
	set opt(resultsfilename) [open $opt(resultsfilename) a+]
	set opt(thrfilename) "/dev/null"
	set opt(thrfilename) [open $opt(thrfilename) a+]
}

#########################
# Module Configuration  #
#########################
Module/UW/CBR set packetSize_          $opt(pktsize)
Module/UW/CBR set period_              $opt(cbr_period)
Module/UW/CBR set PoissonTraffic_      1
Module/UW/CBR set debug_               0

#TDMA
Module/UW/TDMA set frame_duration       8
Module/UW/TDMA set debug_               0
Module/UW/TDMA set sea_trial_           0
Module/UW/TDMA set fair_mode            1
# FAIR Modality on
# Remeber to put silent the SetSlotDuration, SetGuardTime and setStartTime call
Module/UW/TDMA set guard_time           0.8
Module/UW/TDMA set tot_slots            $opt(nn)
Module/UW/TDMA set max_packet_per_slot  1000
Module/UW/TDMA set queue_size_          1000

# var binded by UW/PHYSICAL
Module/UW/PHYSICAL  set TxPower_                    $opt(txpower)
Module/UW/PHYSICAL  set BitRate_                    $opt(bitrate)
Module/UW/PHYSICAL  set AcquisitionThreshold_dB_    4.0 
Module/UW/PHYSICAL  set RxSnrPenalty_dB_            0
Module/UW/PHYSICAL  set TxSPLMargin_dB_             0
Module/UW/PHYSICAL  set MaxTxSPL_dB_                $opt(txpower)
Module/UW/PHYSICAL  set MinTxSPL_dB_                10
Module/UW/PHYSICAL  set MaxTxRange_                 3000
Module/UW/PHYSICAL  set PER_target_                 0    
Module/UW/PHYSICAL  set CentralFreqOptimization_    0
Module/UW/PHYSICAL  set BandwidthOptimization_      0
Module/UW/PHYSICAL  set SPLOptimization_            0
Module/UW/PHYSICAL  set ConsumedEnergy_             0
Module/UW/PHYSICAL  set NoiseSPD_                   0
Module/UW/PHYSICAL  set debug_                      0
Module/UW/PHYSICAL  set step_duration               5  ; # sampling period for channel state transitions
####################################

Module/UnderwaterChannel   set propSpeed_      1500
set channel [new Module/UnderwaterChannel]
set propagation [new MPropagation/Underwater]
set data_mask [new MSpectralMask/Rect]
$data_mask setFreq       $opt(freq)
$data_mask setBandwidth  $opt(bw)

################################
# Procedure(s) to create nodes #
################################
proc createNode { id } {

    global channel propagation data_mask ns cbr position node udp portnum ipr ipif channel_estimator
    global phy posdb opt rvposx rvposy rvposz mhrouting mll mac woss_utilities woss_creator db_manager
    global node_coordinates
    
    set node($id) [$ns create-M_Node $opt(tracefile) $opt(cltracefile)] 
	for {set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
		set cbr($id,$cnt)  [new Module/UW/CBR] 
		
	}
    set udp($id)  [new Module/UW/UDP]
    set ipr($id)  [new Module/UW/StaticRouting]
    set ipif($id) [new Module/UW/IP]
    set mll($id)  [new Module/UW/MLL] 
    set mac($id)  [new Module/UW/TDMA] 
    set phy($id)  [new Module/UW/PHYSICAL]  
	
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
		$node($id) setConnection $cbr($id,$cnt)   $udp($id)   1
		
		set portnum($id,$cnt) [$udp($id) assignPort $cbr($id,$cnt) ]
	}
    $node($id) setConnection $udp($id)   $ipr($id)   1
    $node($id) setConnection $ipr($id)   $ipif($id)  1
    $node($id) setConnection $ipif($id)  $mll($id)   1
    $node($id) setConnection $mll($id)   $mac($id)   1
    $node($id) setConnection $mac($id)   $phy($id)   1
    $node($id) addToChannel  $channel    $phy($id)   1

    if {$id > 254} {
		puts "hostnum > 254!!! exiting"
		exit
    }

    #Set the IP address of the node
    set ip_value [expr $id + 1]
    $ipif($id) addr $ip_value

    $mac($id) setMacAddr    [expr $id + 1]
    $mac($id) setSlotNumber [expr $id + 1]
    
    set position($id) [new "Position/BM"]
    $node($id) addPosition $position($id)


	#Propagation model
    $phy($id) setPropagation $propagation
    
    $phy($id) setSpectralMask $data_mask
    #$phy($id) setInterference $interf_data($id)

}

#################
# Node Creation #
#################
# Create here all the nodes you want to network together
for {set id 0} {$id < $opt(nn)} {incr id}  {
    createNode $id
}

#Setup positions
$position(0) setX_ 686456.448
$position(0) setY_ 3634124.442
$position(0) setZ_ -10

$position(1) setX_ 687170.248
$position(1) setY_ 3633783.966
$position(1) setZ_ -10

$position(2) setX_ 687666.846
$position(2) setY_ 3633189.834
$position(2) setZ_ -10

$position(3) setX_ 687109.108
$position(3) setY_ 3633560
$position(3) setZ_ -10

$ns at $opt(midtime)    "$position(0) setX_ 686656.335"
$ns at $opt(midtime)    "$position(0) setY_ 3633914.240"
$ns at $opt(midtime)    "$position(2) setX_ 687845.160"
$ns at $opt(midtime)    "$position(2) setY_ 3633378.241"

################################
# Inter-node module connection #
################################
proc connectNodes {id1 des1} {
    global ipif ipr portnum cbr cbr_sink ipif_sink ipr_sink opt 

    $cbr($id1,$des1) set destAddr_ [$ipif($des1) addr]
    $cbr($id1,$des1) set destPort_ $portnum($des1,$id1)
}

##################
# Setup flows    #
##################
for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
	for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
		connectNodes $id1 $id2
	}
}

##################
# ARP tables     #
##################
for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
    for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
      $mll($id1) addentry [$ipif($id2) addr] [$mac($id2) addr]
	}
}

##################
# Routing tables #
##################
for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
	for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
			$ipr($id1) addRoute [$ipif($id2) addr] [$ipif($id2) addr]
	}
}

#####################
# Start/Stop Timers #
#####################
# Set here the timers to start and/or stop modules (optional)
# e.g., 
for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
		$ns at $opt(starttime)    "$mac($id1) start"
		$ns at $opt(stoptime)    "$mac($id1) stop"
	for {set id2 0} {$id2 < $opt(nn)} {incr id2} {
		if {$id1 != $id2} {
			if {$id1 == 0 && $id2 == 2} { ;# communication between node 0 and node 2 starts only halfway the simulation
				$ns at $opt(midtime)    "$cbr($id1,$id2) start" 
			} elseif {$id1 == 2 && $id2 == 0} {
				$ns at $opt(midtime)    "$cbr($id1,$id2) start"
			} else {
				$ns at $opt(starttime)    "$cbr($id1,$id2) start"
			}
			$ns at $opt(stoptime)     "$cbr($id1,$id2) stop"
		}
	}
}

#########################
# Auxiliary procedures  #
#########################

proc printPER {start_node dest_node} {
	global cbr opt
	set tx_pkts [$cbr($start_node,$dest_node) getsentpkts]
	set rx_pkts [$cbr($dest_node,$start_node) getrecvpkts]
	set per [expr 1-double($rx_pkts)/$tx_pkts] ;#per
	return $per
}

for {set index 0} {$index < $opt(nn)} {incr index} {
	set partial_tot_rx($index) 0.0
}

proc printInstantThgp {node time} {
	global mac partial_tot_rx opt
	set mac_rcv_pkts [$mac($node) getDataPktsRx]
	set thr [expr ($mac_rcv_pkts-$partial_tot_rx($node))*$opt(pktsize)*8/$opt(time_interval)] ;#bps throughput
	set partial_tot_rx($node) $mac_rcv_pkts
	puts $opt(thrfilename) "[expr $node+1] $time $thr"
}

for {set t_measure $opt(time_interval)} {$t_measure <= $opt(stoptime)} {set t_measure [expr $t_measure + $opt(time_interval)]} {
	for {set n 0} {$n < $opt(nn)} {incr n} {
		$ns at $t_measure "printInstantThgp $n $t_measure"
	}
}

###################
# Final Procedure #
###################
# Define here the procedure to call at the end of the simulation
proc finish {} {

		global ns opt outfile
		global mac propagation cbr_sink mac_sink phy_data phy_data_sink channel db_manager propagation
		global node_coordinates
		global ipr_sink ipr ipif udp cbr phy phy_data_sink
		global node_stats tmp_node_stats sink_stats tmp_sink_stats
		if {$opt(verbose)} {
				puts "---------------------------------------------------------------------"
				puts "Simulation summary"
				puts "number of nodes  : $opt(nn)"
				puts "packet size      : $opt(pktsize) byte"
				puts "cbr period       : $opt(cbr_period) s"
				puts "simulation length: $opt(txduration) s"
				puts "tx power         : $opt(txpower) dB"
				puts "tx frequency     : $opt(freq) Hz"
				puts "tx bandwidth     : $opt(bw) Hz"
				puts "bitrate          : $opt(bitrate) bps"
				puts "---------------------------------------------------------------------"
		}

		for {set i 0} {$i < $opt(nn)} {incr i}  {
		for {set j 0} {$j < $opt(nn)} {incr j} {
			
			if {$i != $j} {
				if {$opt(verbose)} {
					puts "cbr link $j -> $i     pkts sent: [$cbr($j,$i) getsentpkts]    pkts recv: [$cbr($i,$j) getrecvpkts]   PER: [$cbr($i,$j) getPER]  THR: [$cbr($i,$j) getthr]"
					}
				if {$opt(results_file)} {
					puts $opt(resultsfilename) "cbr link [expr $j+1] -> [expr $i+1] PER: [$cbr($i,$j) getPER]  THR: [$cbr($i,$j) getthr]"
				}
			}
		}
		}

		$ns flush-trace
		close $opt(resultsfilename)
		close $opt(thrfilename)
		close $opt(tracefile)
}


###################
# start simulation
###################
if ($opt(verbose)) {
		puts "\nStarting Simulation\n"
		puts "----------------------------------------------"
}

$ns at [expr $opt(stoptime) + 250.0]  "finish; $ns halt" 

$ns run
