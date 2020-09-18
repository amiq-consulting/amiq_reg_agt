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
 * NAME:        amiq_reg_agent_coverage_collector.svh
 * PROJECT:     amiq_reg_agent
 * Description: The coverage collector component class for storing coverage info
 *******************************************************************************/
class reg_covergroup;
	
	local uvm_reg_addr_t 				 valid_addr[$];
	local uvm_reg_addr_t 				 past_addr = 0;
	local uvm_reg_addr_t 				 indexes[$];
	
	covergroup reg_cg with function sample(uvm_reg_bus_op reg_bus_op);
		option.per_instance = 1; 
		
		register_addr_cp: coverpoint reg_bus_op.addr{
			bins addrs_bins[] = valid_addr;
		}
		
		register_access_kind_cp: coverpoint reg_bus_op.kind {
			bins access_transition[] = (UVM_READ, UVM_WRITE => UVM_READ, UVM_WRITE);
		}
		
		access_on_every_address: cross register_addr_cp, register_access_kind_cp iff(past_addr == reg_bus_op.addr);
	endgroup
	
	function void sample_cg(uvm_reg_bus_op reg_bus_op);
		indexes = valid_addr.find(iterator) with (iterator == reg_bus_op.addr);
		if(indexes.size()) begin
			reg_cg.sample(reg_bus_op);
			past_addr = reg_bus_op.addr;
		end
		indexes.delete();
	endfunction
	
	function new(uvm_reg_addr_t valid_addr[$], string name);
		this.valid_addr = valid_addr;
		reg_cg = new(); 
		reg_cg.set_inst_name(name);
	endfunction
endclass


class amiq_reg_agent_coverage_collector extends uvm_component;
	`uvm_component_utils(amiq_reg_agent_coverage_collector)	
	
	`uvm_analysis_imp_decl(_reg_item_imp)
	uvm_analysis_imp_reg_item_imp#(uvm_reg_item, amiq_reg_agent_coverage_collector) reg_item_imp;
	
	function new(string name = "amiq_reg_agent_coverage_collector", uvm_component parent);
		super.new(name, parent);	
		reg_item_imp = new("reg_item_imp", this);
	endfunction
	
	uvm_reg 			 		 reg_array[$];
	uvm_reg_addr_t 				 valid_addr[$];
	reg_covergroup               reg_cg;
	
	function void start_of_simulation();
		uvm_reg_map_addr_range 		valid_addr_range;
		foreach(reg_array[i]) begin
			valid_addr.push_back(reg_array[i].get_address());
		end
		valid_addr.sort();
		reg_cg = new(valid_addr, "amiq_reg_agent_covergroup");
	endfunction
		
	function void write_reg_item_imp(uvm_reg_item reg_item);
		uvm_reg register_of_reg_item;
		uvm_reg_bus_op reg_op;
		
		if(!$cast(register_of_reg_item, reg_item.element))
			`uvm_fatal("CC_REG_CAST", "Could not cast the element of uvm_reg_item to uvm_reg")
			
		reg_op.addr = register_of_reg_item.get_address();
		reg_op.kind = reg_item.kind;
		reg_cg.sample_cg(reg_op);
	endfunction
	
endclass
