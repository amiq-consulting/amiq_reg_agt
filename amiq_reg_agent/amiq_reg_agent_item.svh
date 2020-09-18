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
 * NAME:        amiq_reg_agent_item.svh
 * PROJECT:     amiq_reg_agent
 * Description: The item class
 *******************************************************************************/


class amiq_reg_agent_item extends uvm_sequence_item;
	`uvm_object_utils(amiq_reg_agent_item)
	
	function new(string name = "amiq_reg_agent_item");
		super.new(name);
	endfunction
	
	uvm_reg_bus_op reg_item;
endclass


