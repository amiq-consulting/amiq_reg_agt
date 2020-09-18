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
 * NAME:        amiq_reg_agent.svh
 * PROJECT:     amiq_reg_agent
 * Description: The agent class containing instances of register block, sequencer
                config object and coverage collector
 *******************************************************************************/
class amiq_reg_agent extends uvm_agent;
	`uvm_component_utils(amiq_reg_agent)

	function new(string name = "amiq_reg_agent", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	//Register block provided by user after agent's instantiation.
	uvm_reg_block             		     reg_block;
	
	
    //Configuration object of amiq_reg_agent. It contains informations about:
    // - minimum and maximum addressable space in the register block;
    // - ~has_coverage~ flag tells if the agent will collect coverage informations about register accesses;
    // - ~skip_list~ list of strings set by the user. Based on ~uvm_is_match~ function, 
    //	 the agent determines which register will be accessed by the sequence,
    //   by comparing the name of register and the values inside the queue.
	amiq_reg_agent_cfg_object  			 agent_cfg_object;
	
	
	//Sequencer of ~amiq_reg_agent~. The sequences from the library must be started on this sequencer.   
	amiq_reg_sequencer                   sequencer;
	
	
	//Coverage collector. Collects information about accesses such as: address, type of access, transitions.
	//It is instantiated only if the ~has_coverage~ flag from configuration object is true.
	amiq_reg_agent_coverage_collector	 coverage_collector;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sequencer = amiq_reg_sequencer::type_id::create("sequencer", this);
		if(agent_cfg_object == null)
			if (!uvm_config_db#(amiq_reg_agent_cfg_object)::get(this, "", "amiq_reg_agent_cfg_object", agent_cfg_object))
				`uvm_fatal(get_type_name(), "Could not get the configuration object for reg_agent.")
		if(agent_cfg_object.has_coverage)
			coverage_collector = amiq_reg_agent_coverage_collector::type_id::create("coverage_collector", this);
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_reg reg_array[$];
		uvm_reg valid_registers_array[$];
		uvm_reg_addr_t max_addr = uvm_reg_addr_t'(-1);
		uvm_reg_addr_t valid_addr[$];
		uvm_reg_addr_t invalid_addr[$];
		uvm_reg_map_addr_range invalid_addr_range;
		int indexes_array[$];
		int max_size;
		int address_iterator;
		bit is_valid_address;
		
		if(reg_block == null)
			`uvm_fatal("REG_BLOCK_NULL", "No register block has been assigned to the register agent.")
	
		if(!agent_cfg_object.has_checks) begin
			reg_block.default_map.set_check_on_read(0);
			`uvm_warning("DSBL_RCHECK", "Disabling ~has_checks~ results in disabling checks on the read value of a register.")
		end
		
		reg_block.get_registers(reg_array);
		
	//Determine the register that will be accessed by the sequence.
		foreach(reg_array[i]) begin
			string reg_name = reg_array[i].get_name();
			bit is_in_skip_list = 0;
			if(agent_cfg_object.skip_list.size())	
				foreach(agent_cfg_object.skip_list[j])
					if(uvm_is_match(agent_cfg_object.skip_list[j], reg_name)) begin
						is_in_skip_list = 1;
						break;
					end
				if(!is_in_skip_list) begin
					valid_registers_array.push_back(reg_array[i]);
					`uvm_info(get_name(), $sformatf("Register that will be accessed: %0s, with address: %0h", reg_array[i].get_name(), reg_array[i].get_address()), UVM_LOW);
				end
			valid_addr.push_back(reg_array[i].get_address(reg_block.default_map));
		end

	//Gets the gap between addresses in bytes.
		address_iterator = reg_array[0].get_max_size() / 8;
		if(reg_array[0].get_max_size() % 8 != 0) begin
			address_iterator +=1;
			`uvm_warning("No byte alignment", "Size of registers are not byte aligned.")
		end
		
	//Determines the unmapped address gaps in the register block.
		if(agent_cfg_object.upper_unmaped_space <= max_addr) begin
			uvm_reg_addr_t last_addr;
			valid_addr.sort();
			if(agent_cfg_object.lower_unmaped_space < valid_addr[0]) begin
				invalid_addr_range.min = agent_cfg_object.lower_unmaped_space;
				invalid_addr_range.max = valid_addr[0] - address_iterator;
				sequencer.invalid_addr_ranges.push_back(invalid_addr_range);
			end
			
			last_addr = valid_addr[$];

			for(uvm_reg_addr_t i = 1; i < valid_addr.size(); i++) begin
				if(valid_addr[i] - valid_addr[i-1] > address_iterator) begin
					invalid_addr_range.min = valid_addr[i-1] + address_iterator;
					invalid_addr_range.max = valid_addr[i] - address_iterator;
					sequencer.invalid_addr_ranges.push_back(invalid_addr_range);
				end
			end

			if(agent_cfg_object.upper_unmaped_space > last_addr) begin
				invalid_addr_range.min = last_addr + address_iterator;
				invalid_addr_range.max = agent_cfg_object.upper_unmaped_space;
				sequencer.invalid_addr_ranges.push_back(invalid_addr_range);
			end
		end

		foreach(sequencer.invalid_addr_ranges[i])
			`uvm_info(get_name(), $sformatf("Invalid addresses range: Min: %0h  Max: %0h", sequencer.invalid_addr_ranges[i].min,sequencer.invalid_addr_ranges[i].max), UVM_LOW);

		sequencer.reg_array = valid_registers_array;
		sequencer.reg_block = reg_block;
		if(agent_cfg_object.has_coverage)
			coverage_collector.reg_array = valid_registers_array;
	endfunction

endclass
