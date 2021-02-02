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
 * NAME:        amiq_reg_agent_pkg.sv
 * PROJECT:     amiq_reg_agent
 * Description: Including and importing necessary files into a single package
 *******************************************************************************/


`ifndef AMIQ_SR_REG_AGENT_PKG
`define AMIQ_SR_REG_AGENT_PKG

package amiq_reg_agent_pkg;

	`include "uvm_macros.svh"
	 import uvm_pkg::*;
	 
	`include "amiq_reg_agent_item.svh" 
	`include "amiq_reg_agent_cfg_object.svh"
	`include "amiq_reg_sequencer.svh"
	`include "amiq_reg_sequence_lib.svh"
	`include "amiq_reg_agent_coverage_collector.svh"
	`include "amiq_reg_agent.svh"
	
endpackage
`endif
