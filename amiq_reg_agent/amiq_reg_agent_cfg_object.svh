/******************************************************************************
 * (C) Copyright 2020 AMIQ Consulting
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * NAME:        amiq_reg_agent_cfg_object.svh
 * PROJECT:     amiq_reg_agent
 * Description: The configuration object class
 *******************************************************************************/

// configuration class for the register agent
class amiq_reg_agent_cfg_object extends uvm_object;
	`uvm_object_utils(amiq_reg_agent_cfg_object)

	function new(string name = "amiq_reg_agent_cfg_object");
		super.new(name);
	endfunction
	
	
	bit				 has_coverage = 1;
	bit				 has_checks   = 1;
	string	 		 skip_list[$];
	
	uvm_verbosity    reg_agent_verbosity = UVM_LOW;
	
	uvm_reg_addr_t   lower_unmaped_space = 0;
	//maximum accessible address 
	uvm_reg_addr_t   upper_unmaped_space = uvm_reg_addr_t'(-1);
	
endclass
