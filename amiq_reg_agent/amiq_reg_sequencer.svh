/******************************************************************************
* (C) Copyright Amiq 2019 All Rights Reserved
*
* MODULE:
* AUTHOR: marghe
* DATE: Nov 8, 2019
*
* FILE DESCRIPTION:
*
*******************************************************************************/

class amiq_reg_sequencer extends uvm_sequencer#(uvm_sequence); 
	`uvm_component_utils(amiq_reg_sequencer)
	
	function new(string name = "amiq_sr_reg_virtual_sequencer", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	uvm_reg 					 reg_array[$];
	uvm_reg_block 				 reg_block;
	uvm_reg_map_addr_range 		 invalid_addr_ranges[$];
	
endclass