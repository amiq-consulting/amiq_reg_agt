# Register Agent
In order to copy the register agent in your verification environment you need to run: 

$>  ./move_to_env $DESTINATION

In order to start a sequence from register agent you must:
* create the Register Abstraction Layer (register block, adapter connected to the sequencer of driver, predictor)
* assign the Register Agent Configuration Object 
* assign the Register Block handle to the reg_block field of agent, at connect_phase;

Starting a sequence:

`uvm_do_on_with (_name_of_sequence_to_start, _sequencer_provided_from_reg_agent, {//constraints applied to sequence fields})

Register agent main sequence fields explained:
chance_to_access_again:(default inside [0:100]) chance of a access to hit the same register multiple times; control knob of re-access is randomized based on this chance;
* chance_to_write_another_reg:(default inside [0:100]) chance of a write access to write a value to another register, besides the current register that is being written;
* chance_to_access_invalid:(default inside [0:100]) chance of a access to hit a unmapped address, besides the current register that is being accessed;
* max_number_of_iteration:(default 100) used in amiq_reg_random_seq; sets the maximum number of times the register array is shuffled and accessed;
* default_pattern:(random) a random value to be written in registers, in case the user doesn't set any values in the pattern_queue;
* pattern_queue:(default empty) a queue for user to set values that will be randomly used in write access type of registers;
* is_set_pattern_queue:(default 0) a bit to set in order to write values from pattern_queue or a random one;
* reaccess_register_knob:(default 1) a bit to unset in order to stop multiple accesses of same register;
* do_first_read: bit used in read-write-read sequences; dictates if first read of register is executed;
* do_write: bit used in read-write-read sequences; dictates if write of register is executed;
* do_second_read: bit used in read-write-read sequences; dictates if second read of register is executed; 
