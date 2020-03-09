/******************************************************************************
* (C) Copyright Amiq 2020 All Rights Reserved
*
* MODULE:
* AUTHOR: marghe
* DATE: Jan 13, 2020
*
* FILE DESCRIPTION:
*
*******************************************************************************/


class amiq_reg_agent_item extends uvm_sequence_item;
	`uvm_object_utils(amiq_reg_agent_item)
	
	function new(string name = "amiq_reg_agent_item");
		super.new(name);
	endfunction
	
	uvm_reg_bus_op reg_item;
endclass


