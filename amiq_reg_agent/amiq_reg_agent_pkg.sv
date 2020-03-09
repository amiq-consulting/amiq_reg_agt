/******************************************************************************
* (C) Copyright Amiq 2019 All Rights Reserved
*
* MODULE:
* AUTHOR: marghe
* DATE: Nov 15, 2019
*
* FILE DESCRIPTION:
*
*******************************************************************************/


`ifndef AMIQ_SR_REG_AGENT_PKG
`define AMIQ_SR_REG_AGENT_PKG

package amiq_reg_agent_pkg;

	`include "uvm_macros.svh"
	 import uvm_pkg::*;
	 
	`include "amiq_reg_agent_item.svh" 
	`include "amiq_reg_sequencer.svh"
	`include "amiq_reg_sequence_lib.svh"
	`include "amiq_reg_agent_coverage_collector.svh"
	`include "amiq_reg_agent_cfg_object.svh"
	`include "amiq_reg_agent.svh"
	
endpackage
`endif