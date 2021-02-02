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
 * NAME:        amiq_reg_sequence_lib.svh
 * PROJECT:     amiq_reg_agent
 * Description: The main sequences provided by the Register Agent
 *******************************************************************************/

class amiq_reg_base_sequence extends uvm_sequence;
	`uvm_object_utils(amiq_reg_base_sequence)
	`uvm_declare_p_sequencer(amiq_reg_sequencer)


	function new(string name = "amiq_reg_base_sequence");
		super.new(name);

	endfunction

	rand  int                        chance_to_access_again;
	rand  int                        chance_to_write_another_reg;
	rand  int                        chance_to_access_invalid;
	rand  int                        max_number_of_iteration;
	rand  int                        min_number_of_iteration;
	rand  uvm_reg_data_t             default_pattern;
	uvm_reg_data_t                   pattern_queue[$];
	rand  bit                        reaccess_register_knob;
	rand  bit                        do_first_read;
	rand  bit                        do_write;
	rand  bit                        do_second_read;
	bit                              is_set_pattern_queue;


	constraint chance_to_access_again_c {
		chance_to_access_again inside {[0:99]};
	}

	constraint change_to_write_another_reg_c {
		chance_to_write_another_reg inside {[0:100]};
	}

	constraint chance_to_access_invalid_c {
		chance_to_access_invalid inside {[0:100]};
	}

	constraint number_of_iteration_c{
		soft max_number_of_iteration == 100;
		soft min_number_of_iteration == 1;
		min_number_of_iteration <= max_number_of_iteration;
	}

	constraint reaccess_register_knob_c{
		soft reaccess_register_knob == 1;
	}

	constraint rwr_flags_c{
		soft do_first_read   == 1;
		soft do_write        == 1;
		soft do_second_read  == 1;
	};

	function void push_pattern_queue(uvm_reg_data_t given_queue[$]);
		foreach(given_queue[i])
			pattern_queue.push_back(given_queue[i]);
		is_set_pattern_queue = 1;
	endfunction

	function void randomize_invalid_address(ref bit[`UVM_REG_ADDR_WIDTH : 0] returned_address);
		int invalid_index;
		bit[`UVM_REG_ADDR_WIDTH : 0] invalid_address;
		std::randomize(invalid_index, invalid_address) with {
			invalid_index >= 0;
			if(p_sequencer.invalid_addr_ranges.size()) invalid_index < p_sequencer.invalid_addr_ranges.size();
			else
				invalid_index == 0;
			if(p_sequencer.invalid_addr_ranges.size()){
				invalid_address >= p_sequencer.invalid_addr_ranges[invalid_index].min;
				invalid_address <= p_sequencer.invalid_addr_ranges[invalid_index].max;
			}
		};
		returned_address = invalid_address;
	endfunction


	task read(uvm_reg register);
		uvm_reg_data_t              value;
		uvm_status_e                status;

		bit                         access_invalid;
		bit[`UVM_REG_ADDR_WIDTH:0]  invalid_address;
		int                         invalid_index;
		register.read(status, value);
		assert(status == UVM_IS_OK) else
			`uvm_error("reg_status_error", $sformatf("Read command did not complete succesfully for register %s",register.get_name()))
		std::randomize(access_invalid) with {access_invalid dist {1:=chance_to_access_invalid,
				0:= 100 - chance_to_access_invalid};};
		if(access_invalid) begin
			randomize_invalid_address(invalid_address);
			read_unmapped_register(invalid_address);
		end
	endtask


	function uvm_reg_data_t get_pattern_to_write(bit is_set_pattern_queue);
		uvm_reg_data_t  current_pattern;
		int                         index_pattern_to_write;

		if(is_set_pattern_queue) begin
			std::randomize(index_pattern_to_write) with { index_pattern_to_write >=0;
				if(pattern_queue.size()) index_pattern_to_write < pattern_queue.size();
				else
					index_pattern_to_write == 0;};
			current_pattern = pattern_queue[index_pattern_to_write];
		end
		else begin
			current_pattern = default_pattern;
		end
		return current_pattern;
	endfunction


	task write(uvm_reg register, bit is_set_pattern_queue);
		uvm_status_e                status;
		bit                         access_invalid;
		bit[`UVM_REG_ADDR_WIDTH:0]  invalid_address;
		uvm_reg_data_t              current_pattern;
		int                         invalid_index;
		int                         index_pattern_to_write;
		current_pattern = get_pattern_to_write(is_set_pattern_queue);
		register.write(status, current_pattern);
		assert(status == UVM_IS_OK) else
			`uvm_error("reg_status_error", $sformatf("Read command did not complete succesfully for register %s",register.get_name()))

		std::randomize(access_invalid) with {access_invalid dist {
				1:=chance_to_access_invalid,
				0:= 100 - chance_to_access_invalid};
		};
		if(access_invalid) begin
			randomize_invalid_address(invalid_address);
			write_unmapped_register(invalid_address, is_set_pattern_queue);
		end
	endtask


	task read_reg_with_chance_to_reaccess(uvm_reg register);
		bit access_again;
		read(register);
		std::randomize(access_again) with { access_again dist {
				1:=chance_to_access_again,
				0:= 100- chance_to_access_again };
		};
		if(reaccess_register_knob)
			while(access_again) begin
				read(register);
				std::randomize(access_again) with { access_again dist {
						1:=chance_to_access_again,
						0:= 100- chance_to_access_again };
				};
			end
	endtask


	function void push_unique_register(uvm_reg register,ref uvm_reg accessed_registers[$]);
		int already_in_queue[$] = accessed_registers.find_index(k) with (k == register);
		if(!already_in_queue.size())
			accessed_registers.push_back(register);
	endfunction


	task write_reg_with_chance_to_reaccess(uvm_reg register, bit is_set_pattern_queue);
		bit access_again;
		bit write_another_reg;
		int index_of_reg_to_write;
		uvm_reg accessed_registers[$];
		write(register, is_set_pattern_queue);
		push_unique_register(register, accessed_registers);
		if(reaccess_register_knob) begin
			std::randomize(access_again) with { access_again dist {1:=chance_to_access_again,
					0:= 100- chance_to_access_again };};
			while(access_again) begin
				std::randomize(write_another_reg) with {write_another_reg dist {1:=chance_to_write_another_reg,
						0:= 100- chance_to_write_another_reg};};
				if(write_another_reg) begin
					std::randomize(index_of_reg_to_write) with{ index_of_reg_to_write >=0;
						if(p_sequencer.reg_array.size()) index_of_reg_to_write < p_sequencer.reg_array.size();
						else
							index_of_reg_to_write == 0;};
					write(p_sequencer.reg_array[index_of_reg_to_write], is_set_pattern_queue);
					push_unique_register(p_sequencer.reg_array[index_of_reg_to_write], accessed_registers);
				end
				else begin
					write(register, is_set_pattern_queue);
					push_unique_register(register, accessed_registers);
				end
				std::randomize(access_again) with {access_again dist {1:=chance_to_access_again,
						0:= 100- chance_to_access_again };};
			end
		end
		if (accessed_registers.size())
			foreach(accessed_registers[i])
				read(accessed_registers[i]);
		accessed_registers.delete();
	endtask


	task read_unmapped_register(uvm_reg_addr_t address);
		uvm_reg_item reg_item = uvm_reg_item::type_id::create("read_item",, get_full_name());
		uvm_reg_bus_op rw_access;
		uvm_sequence_item bus_req;
		uvm_reg_adapter adapter = p_sequencer.reg_block.default_map.get_adapter();

		reg_item.offset = address;
		reg_item.kind = UVM_READ;
		reg_item.local_map = p_sequencer.reg_block.default_map;
		rw_access.addr = address;
		rw_access.kind = UVM_READ;
		rw_access.n_bits = p_sequencer.reg_array[$].get_n_bits();
		adapter.m_set_item(reg_item);
		bus_req = adapter.reg2bus(rw_access);
		adapter.m_set_item(null);
		bus_req.set_sequencer(p_sequencer.reg_block.default_map.get_sequencer());
		start_item(bus_req);
		finish_item(bus_req);
	endtask


	task write_unmapped_register(uvm_reg_addr_t address, bit is_set_pattern_queue);
		uvm_reg_item reg_item = uvm_reg_item::type_id::create("read_item",, get_full_name());
		uvm_reg_bus_op rw_access;
		uvm_sequence_item bus_req;
		uvm_reg_adapter adapter = p_sequencer.reg_block.default_map.get_adapter();
		uvm_reg_data_t value;
		value = get_pattern_to_write(is_set_pattern_queue);

		reg_item.offset = address;
		reg_item.kind = UVM_WRITE;
		reg_item.local_map = p_sequencer.reg_block.default_map;
		rw_access.addr = address;
		rw_access.kind = UVM_WRITE;
		rw_access.n_bits = p_sequencer.reg_array[$].get_n_bits();
		rw_access.data = value;
		adapter.m_set_item(reg_item);
		bus_req = adapter.reg2bus(rw_access);
		adapter.m_set_item(null);
		bus_req.set_sequencer(p_sequencer.reg_block.default_map.get_sequencer());
		start_item(bus_req);
		finish_item(bus_req);
	endtask


	function int get_address_gap();
		int address_iterator = p_sequencer.reg_array[$].get_n_bits() / 8;
		if(p_sequencer.reg_array[$].get_n_bits() % 8 != 0) begin
			address_iterator +=1;
			`uvm_warning("No byte alignment", $sformatf("Size of registers are not byte aligned. Size: %0d", p_sequencer.reg_array[$].get_n_bits()))
		end
		return address_iterator;
	endfunction


	//Check validity of the fields.
	virtual task pre_body();
		if(is_set_pattern_queue) begin
			SEQ_FLAGS_CONFIGURATION:
			assert(pattern_queue.size()) else
				`uvm_error("REG_AGENT_SEQ_ERR_TAG", "Sequence is not properly configured. No patterns added in queue.")
		end

		if(chance_to_access_again > 80)
			`uvm_warning("REG_AGENT_SEQ_WRN_TAG", "Sequence configuration warning: High chance of re-accessing will conclude in higher simulation times.")

		if(chance_to_access_again == 100 && reaccess_register_knob)
			`uvm_fatal("REG_AGENT_SEQ_FATAL_TAG", "Chance of 100% will conclude in infinite re-accesses.")

		if(min_number_of_iteration > max_number_of_iteration)
			`uvm_fatal("REG_AGENT_SEQ_FATAL_TAG", "min_number_of_iteration must be lower than max_number_of_iteration.")

	endtask


	virtual task body();
		`uvm_fatal("base_seq", "The base sequence of register agent can't be instantiated")
	endtask
endclass


//Sequence that access all registers in a READ-WRITE-READ order.
class amiq_reg_rwr_seq extends amiq_reg_base_sequence;
	`uvm_object_utils(amiq_reg_rwr_seq)
	`uvm_declare_p_sequencer(amiq_reg_sequencer)


	function new(string name = "amiq_reg_rwr_seq");
		super.new(name);
	endfunction

	virtual task pre_body();
		super.pre_body();
		if(!do_first_read && !do_second_read && !do_write)
			`uvm_warning("REG_AGENT_SEQ_WRN_TAG", "This configuration of fields concludes in no access of registers for read-write-read sequences.")

		if(do_second_read == 0 || do_write == 0)
			`uvm_warning("REG_AGENT_SEQ_WRN_TAG", "Sequence configuration warning: The second read of registers will not be executed for read-write-read sequences.")
	endtask

	virtual task body();
		`uvm_info(get_name(), $sformatf("Starting Read-Write-Sequence for every register"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);
		`uvm_info(get_name(), $sformatf("First read = %0d, Write = %0d, Second read = %0d.", do_first_read, do_write, do_second_read), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

		foreach(p_sequencer.reg_array[i]) begin
			if(do_first_read)
				read(p_sequencer.reg_array[i]);
			if(do_write)
				write(p_sequencer.reg_array[i], is_set_pattern_queue);
			if(do_second_read && do_write)
				read(p_sequencer.reg_array[i]);
		end
		`uvm_info(get_name(), $sformatf("End of Read-Write-Sequence for every register"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);
	endtask
endclass


//Sequence that reads all registers in a shuffled order.
class amiq_reg_random_read_seq extends amiq_reg_base_sequence;
	`uvm_object_utils(amiq_reg_random_read_seq)
	`uvm_declare_p_sequencer(amiq_reg_sequencer)

	function new(string name = "amiq_reg_random_read_seq");
		super.new(name);
	endfunction

	uvm_reg shuffled_queue[$];

	virtual task body();
		`uvm_info(get_name(), $sformatf("Starting Random Read Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);
		`uvm_info(get_name(), $sformatf("Shuffling addresses to be read"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

		foreach(p_sequencer.reg_array[i])
			shuffled_queue.push_back(p_sequencer.reg_array[i]);
		shuffled_queue.shuffle();

		`uvm_info(get_name(), $sformatf("Starting accesses"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

		foreach(shuffled_queue[i]) begin
			read_reg_with_chance_to_reaccess(shuffled_queue[i]);
		end

		`uvm_info(get_name(), $sformatf("End of Random Read Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);
	endtask
endclass


//Sequence that access all mapped registers in a shuffled order.
//The action is repeated for a random ~number_of_iterations~, every time the order of access being shuffled.
class amiq_reg_random_seq extends amiq_reg_base_sequence;
	`uvm_object_utils(amiq_reg_random_seq)
	`uvm_declare_p_sequencer(amiq_reg_sequencer)

	function new(string name = "amiq_reg_random_seq");
		super.new(name);
	endfunction

	uvm_reg shuffled_queue[$];

	virtual task body();
		int number_of_iterations;
		bit access_type;
		`uvm_info(get_name(), $sformatf("Starting Random Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

		std::randomize(number_of_iterations) with { number_of_iterations inside {[min_number_of_iteration:max_number_of_iteration]};};

		`uvm_info(get_name(), $sformatf("The number of shuffles performed on address order is: %0d times", number_of_iterations), p_sequencer.reg_agent_config_object.reg_agent_verbosity);
		`uvm_info(get_name(), $sformatf("Starting accesses..."), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

		for(int i = 0; i < number_of_iterations; i++) begin
			foreach(p_sequencer.reg_array[i])
				shuffled_queue.push_back(p_sequencer.reg_array[i]);
			shuffled_queue.shuffle();

			foreach(shuffled_queue[i]) begin
				std::randomize(access_type);
				if(access_type) begin
					write_reg_with_chance_to_reaccess(shuffled_queue[i], is_set_pattern_queue);
				end
				else
					read_reg_with_chance_to_reaccess(shuffled_queue[i]);
			end
			shuffled_queue.delete();
		end

		`uvm_info(get_name(), $sformatf("Ending Random Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

	endtask
endclass


//Sequence that access every gap of the unmapped addresses in the following way:
//min_address, in_between_address(randomized), max_address.
//Every selected address is accessed in READ-WRITE-READ order;
class amiq_reg_unmapped_seq extends amiq_reg_base_sequence;
	`uvm_object_utils(amiq_reg_unmapped_seq)
	`uvm_declare_p_sequencer(amiq_reg_sequencer)

	function new(string name = "amiq_reg_unmapped_seq");
		super.new(name);
	endfunction

	virtual task pre_body();
		super.pre_body();
		if(!do_first_read && !do_second_read && !do_write)
			`uvm_warning("REG_AGENT_SEQ_WRN_TAG", "This configuration of fields concludes in no access of registers for read-write-read sequences.")

		if(do_second_read == 0 || do_write == 0)
			`uvm_warning("REG_AGENT_SEQ_WRN_TAG", "Sequence configuration warning: The second read of registers will not be executed for read-write-read sequences.")
	endtask

	virtual task body();
		`uvm_info(get_name(), $sformatf("Starting Unmapped Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

		foreach(p_sequencer.invalid_addr_ranges[i]) begin
			uvm_reg_addr_t random_addr;

			`uvm_info(get_name(), $sformatf("Accessing min edge of unmapped range: %0h", p_sequencer.invalid_addr_ranges[i].min), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

			if(do_first_read)
				read_unmapped_register(p_sequencer.invalid_addr_ranges[i].min);
			if(do_write)
				write_unmapped_register(p_sequencer.invalid_addr_ranges[i].min, is_set_pattern_queue);
			//Check if there was a write access before.
			//Reading the same address twice without write a value in between results in no bonus information.
			if(do_second_read && do_write)
				read_unmapped_register(p_sequencer.invalid_addr_ranges[i].min);

			if(p_sequencer.invalid_addr_ranges[i].max - p_sequencer.invalid_addr_ranges[i].min > get_address_gap()) begin

				std::randomize(random_addr) with {
					random_addr > p_sequencer.invalid_addr_ranges[i].min;
					random_addr < p_sequencer.invalid_addr_ranges[i].max;
				};

				`uvm_info(get_name(), $sformatf("Accessing random address in unmapped range: %0h", random_addr), p_sequencer.reg_agent_config_object.reg_agent_verbosity);


				if(do_first_read)
					read_unmapped_register(random_addr);
				if(do_write)
					write_unmapped_register(random_addr, is_set_pattern_queue);
				//Check if there was a write access before.
				//Reading the same address twice without write a value in between results in no bonus information.
				if(do_second_read && do_write)
					read_unmapped_register(random_addr);

			end

			`uvm_info(get_name(), $sformatf("Accessing max edge of unmapped range: %0h", p_sequencer.invalid_addr_ranges[i].max), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

			if(do_first_read)
				read_unmapped_register(p_sequencer.invalid_addr_ranges[i].max);
			if(do_write)
				write_unmapped_register(p_sequencer.invalid_addr_ranges[i].max, is_set_pattern_queue);
			//Check if there was a write access before.
			//Reading the same address twice without write a value in between results in no bonus information.
			if(do_second_read && do_write)
				read_unmapped_register(p_sequencer.invalid_addr_ranges[i].max);
		end
		`uvm_info(get_name(), $sformatf("Ending Unmapped Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);
	endtask
endclass


//Sequence that access every unmapped address in READ-WRITE-READ order.
class amiq_reg_all_unmapped_seq extends amiq_reg_base_sequence;
	`uvm_object_utils(amiq_reg_all_unmapped_seq)
	`uvm_declare_p_sequencer(amiq_reg_sequencer)

	function new(string name = "amiq_reg_all_unmapped_seq");
		super.new(name);
	endfunction

	virtual task pre_body();
		super.pre_body();
		if(!do_first_read && !do_second_read && !do_write)
			`uvm_warning("REG_AGENT_SEQ_WRN_TAG", "This configuration of fields concludes in no access of registers for read-write-read sequences.")

		if(do_second_read == 0 || do_write == 0)
			`uvm_warning("REG_AGENT_SEQ_WRN_TAG", "Sequence configuration warning: The second read of registers will not be executed for read-write-read sequences.")
	endtask

	virtual task body();
		`uvm_info(get_name(), $sformatf("Starting All-Unmapped Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

		foreach(p_sequencer.invalid_addr_ranges[i]) begin
			`uvm_info(get_name(), $sformatf("Access every address in range: %0h - %0h", p_sequencer.invalid_addr_ranges[i].min, p_sequencer.invalid_addr_ranges[i].max), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

			for(bit[`UVM_REG_ADDR_WIDTH:0] invalid_addr = p_sequencer.invalid_addr_ranges[i].min; invalid_addr <=p_sequencer.invalid_addr_ranges[i].max; invalid_addr += get_address_gap()) begin
				if(do_first_read)
					read_unmapped_register(invalid_addr);
				if(do_write)
					write_unmapped_register(invalid_addr, is_set_pattern_queue);
				//Check if there was a write access before.
				//Reading the same address twice without write a value in between results in no bonus information.
				if(do_second_read && do_write)
					read_unmapped_register(invalid_addr);
			end
		end
		`uvm_info(get_name(), $sformatf("Ending All-Unmapped Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);
	endtask
endclass

class amiq_reg_walking_1_seq extends amiq_reg_base_sequence;
	`uvm_object_utils(amiq_reg_walking_1_seq)
	`uvm_declare_p_sequencer(amiq_reg_sequencer)


	function new (string name = "amiq_reg_walking_1_seq");
		super.new(name);
	endfunction

	virtual task body();
		`uvm_info(get_name(), $sformatf("Starting Walking-1 Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);

		foreach(p_sequencer.reg_array[i]) begin
			for(int k = 0; k < `UVM_REG_DATA_WIDTH; k++) begin
				default_pattern = uvm_reg_addr_t'(1) << k;
				`uvm_info(get_full_name(), $sformatf("Value written = %b in address = %0h", default_pattern, p_sequencer.reg_array[i].get_address()), p_sequencer.reg_agent_config_object.reg_agent_verbosity)
				write(p_sequencer.reg_array[i], 0);
				read(p_sequencer.reg_array[i]);
			end
		end
		`uvm_info(get_name(), $sformatf("Ending Walking-1 Sequence"), p_sequencer.reg_agent_config_object.reg_agent_verbosity);
	endtask
endclass

//Main sequence that starts all sequences in order to cover all the coverage defined in coverage collector of the ~amiq_reg_agent~.
class amiq_reg_main_seq extends amiq_reg_base_sequence;
	`uvm_object_utils(amiq_reg_main_seq)
	`uvm_declare_p_sequencer(amiq_reg_sequencer)

	amiq_reg_rwr_seq                 rwr_seq;
	amiq_reg_walking_1_seq           walking_1_seq;
	amiq_reg_random_seq              random_seq;
	amiq_reg_unmapped_seq            unmapped_seq;

	function new (string name = "amiq_reg_main_sequence");
		super.new(name);
	endfunction

	function void randomize_sequence(amiq_reg_base_sequence base_seq);
		int nof_registers = p_sequencer.reg_array.size();
		if(!base_seq.randomize() with {
					chance_to_access_again      inside {[70:99]};
					chance_to_access_invalid    == local::chance_to_access_invalid;
					chance_to_write_another_reg inside {[70:100]};
					default_pattern             == local::default_pattern;
					do_first_read               == 1;
					do_second_read              == 1;
					do_write                    == 1;
					reaccess_register_knob      == 1;
					max_number_of_iteration     inside {[nof_registers / 2 : nof_registers]};
					min_number_of_iteration     inside {[nof_registers / 2 : nof_registers]};
				}) `uvm_fatal("RAND_FAILED", $sformatf("Randomization failed for %0s", base_seq.type_name));
	endfunction

	virtual task body();
		//create and start read-write-read sequence
		rwr_seq =amiq_reg_rwr_seq::type_id::create("rwr_seq", p_sequencer);
		randomize_sequence(rwr_seq);
		rwr_seq.push_pattern_queue(pattern_queue);
		rwr_seq.start(p_sequencer);

		//create and start walking 1 sequence
		walking_1_seq =amiq_reg_walking_1_seq::type_id::create("walking_1_seq", p_sequencer);
		randomize_sequence(walking_1_seq);
		walking_1_seq.push_pattern_queue(pattern_queue);
		walking_1_seq.start(p_sequencer);

		//create and start random sequence sequence
		random_seq =amiq_reg_random_seq::type_id::create("random_seq", p_sequencer);
		randomize_sequence(random_seq);
		random_seq.push_pattern_queue(pattern_queue);
		random_seq.start(p_sequencer);

		//create and start unmapped sequence for accessing unmapped ranges
		unmapped_seq =amiq_reg_unmapped_seq::type_id::create("unmapped_seq", p_sequencer);
		randomize_sequence(unmapped_seq);
		unmapped_seq.push_pattern_queue(pattern_queue);
		unmapped_seq.start(p_sequencer);
	endtask
endclass
