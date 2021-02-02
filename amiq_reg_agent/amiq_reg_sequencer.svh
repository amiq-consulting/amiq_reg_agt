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
 * NAME:        amiq_reg_sequencer.svh
 * PROJECT:     amiq_reg_agent
 * Description: The sequencer class
 *******************************************************************************/

// sequencer class
class amiq_reg_sequencer extends uvm_sequencer#(uvm_sequence); 
	`uvm_component_utils(amiq_reg_sequencer)
	
	function new(string name = "amiq_sr_reg_virtual_sequencer", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	uvm_reg 					 reg_array[$];
	uvm_reg_block 				 reg_block;
	uvm_reg_map_addr_range 		 invalid_addr_ranges[$];
	amiq_reg_agent_cfg_object    reg_agent_config_object;
endclass
