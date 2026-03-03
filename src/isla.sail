val isla_reset_registers = "reset_registers" : unit -> unit
val sail_end_cycle = impure "cycle_count" : unit -> unit
val init_model : unit -> unit effect {barr, eamem, escape, exmem, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}

function init_model() = {
  hart_state = HART_ACTIVE();
  reset_sys();
  reset_vmem();
  reset_elp();
}

val ext_init : unit -> unit effect {barr, eamem, escape, exmem, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function ext_init() = {
  ext_reset();
}

val isla_execute_helper : forall 'n, 'n in {16, 32}. bits('n) -> unit effect {escape, rreg, wreg, rmem, wmv}
function isla_execute_helper(opcode) = {
  let ast : instruction = if length(opcode) == 16 then {
    nextPC = PC + 2;
    ext_decode_compressed(opcode)
  } else {
    nextPC = PC + 4;
    ext_decode(opcode)
  };
  let _ = execute(ast);
  tick_pc()
}

val isla_footprint_no_init : forall 'n, 'n in {16, 32}. bits('n) -> bool effect {barr, eamem, escape, exmem, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function isla_footprint_no_init(opcode) = {
  try {
    isla_reset_registers();
    sail_end_cycle();
    isla_execute_helper(opcode);
    true
  } catch {
    _ => false
  }
}

val isla_footprint : forall 'n, 'n in {16, 32}. bits('n) -> bool effect {barr, eamem, escape, exmem, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function isla_footprint(opcode) = {
  ext_init();
  try {
    init_model();
    isla_footprint_no_init(opcode)
  } catch {
    _ => false
  }
}

val isla_testgen_init : unit -> unit effect {wreg, rmem}
function isla_testgen_init() = {
  PC = zero_extend(0x80000000);
  mstatus[MIE] = 0b0;
  init_model()
}

val isla_testgen_step : unit -> unit effect {barr, eamem, escape, exmem, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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
