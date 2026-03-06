val isla_footprint_no_init : forall 'n, 'n in {16, 32}. bits('n) -> bool
val isla_footprint : forall 'n, 'n in {16, 32}. bits('n) -> bool
val isla_testgen_init : unit -> unit effect {wreg, rmem}
val isla_testgen_step : unit -> unit effect {barr, eamem, escape, exmem, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}

function reset() -> unit = {
  hart_state = HART_ACTIVE();

  reset_sys();
  reset_vmem();
  reset_elp();
  ext_reset();
}

function isla_reset_registers() -> unit = {
  mstatus[VS] = 0b01;
  vtype[vill] = 0b0;
  vtype[vsew]  = 0b000; // e8
  vtype[vlmul] = 0b000; // m1
  vl     = zero_extend(0x4);            
  vstart = zeros();      
//  vlenb  = 16;          
}

function init_model() -> unit = {
  isla_reset_registers();
  reset();
  PC = zero_extend(0x80000000);
  print_string("","Model Initiated\n");
  print_bits("Starting with PC= ", PC); 
} 

function isla_footprint_no_init(opcode) = {
  try {
    let instr = if length(opcode) == 16 then {
      ext_decode_compressed(opcode)
    } else {
      ext_decode(opcode)
    };
    let _ = execute(instr);
    true
  } catch {
    _ => {
          print_endline("Instruction Failed");
          //print_endline(s);
          false
    }
  }
}

function isla_footprint(opcode) = {
  try {
    print_string("","Footprint Initiated\n");
    init_model();  
    sail_end_cycle(); 
    isla_footprint_no_init(opcode)
  } catch {
    _ => false
  }
}

function isla_testgen_init() -> unit = {
  print_string("","TestGen Initiated\n");
  init_model();
}

function isla_testgen_step() = {
  let f : FetchResult = ext_fetch_hook(fetch());
  match f {
    F_Ext_Error(e)   => assert(false, "Extension Fetch Error"),
    F_Error(e, addr) => assert(false, "Fetch Error"),
    F_Base(w) => {
      nextPC = PC + 4;
      let ast = ext_decode(w);
      if execute(ast) != RETIRE_SUCCESS then assert(false, "Execution Failed")
    }
  };
  tick_pc()
}


