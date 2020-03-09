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


class amiq_reg_agent_cfg_object extends uvm_object;
	`uvm_object_utils(amiq_reg_agent_cfg_object)

	function new(string name = "amiq_reg_agent_cfg_object");
		super.new(name);
	endfunction
	
	
	bit				 has_coverage = 1;
	bit				 has_checks   = 1;
	string	 		 skip_list[$];
	uvm_reg_addr_t   lower_unmaped_space = 0;
	//maximum accessible address 
	uvm_reg_addr_t   upper_unmaped_space = uvm_reg_addr_t'(-1);
	
endclass