/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

val isla_reset_registers = "reset_registers" : unit -> unit
val isla_footprint : forall 'n, 'n in {16, 32}. bits('n) -> bool
val sail_end_cycle = impure "cycle_count" : unit -> unit

val isla_footprint_no_init : forall 'n, 'n in {16, 32}. bits('n) -> bool effect {barr, eamem, escape, exmem, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}

function isla_footprint_no_init(opcode) = {
  try {
    isla_reset_registers();

    sail_end_cycle();
    let ast: ast = if length(opcode) == 16 then {
      nextPC = PC + 2;
      ext_decode_compressed(opcode)
    } else {
      nextPC = PC + 4;
      ext_decode(opcode)
    };
    let _ = execute(ast);
    tick_pc();

    true
  } catch {
    _ => false
  }
}

val isla_footprint : forall 'n, 'n in {16, 32}. bits('n) -> bool effect {barr, eamem, escape, exmem, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}

function isla_footprint(opcode) = {
  try {
    init_model("");

    isla_footprint_no_init(opcode)
  } catch {
    _ => false
  }
}

function isla_testgen_init() -> unit = {
  PC = 0x80000000;
  mstatus[MIE] = 0b0;
  init_model("");
}

function isla_testgen_step() -> unit = {
  let f : FetchResult = fetch();
  let r : Retired = match f {
    F_Ext_Error(e)   => RETIRE_FAIL,
    F_Error(e, addr) => RETIRE_FAIL,
    F_RVC(h) => {
      let ast = ext_decode_compressed(h);
      nextPC = PC + 2;
      execute(ast)
    },
    F_Base(w) => {
      let ast = ext_decode(w);
      nextPC = PC + 4;
      execute(ast)
    }
  };
  match r {
    RETIRE_SUCCESS => (),
    RETIRE_FAIL => assert(false),
  };
  tick_pc();
}
