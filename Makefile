# Makefile for ISLA IR generation with RISC-V Vector support
# Targeting latest upstream riscv/sail-riscv (restructured model directory)

# Default architecture
ARCH ?= RV32
ifeq ($(ARCH),32)
  override ARCH := RV32
else ifeq ($(ARCH),64)
  override ARCH := RV64
endif

SAIL_RISCV_DIR=sail-riscv
SAIL_MODEL_DIR=$(SAIL_RISCV_DIR)/model
SAIL_ISLA_DIR=src

ISLA_DIR = isla/target/release/

# --------------------------------------------------------------------------
#  Sail tool configuration
# --------------------------------------------------------------------------

SAIL := sail
SAIL_DIR := $(shell $(SAIL) -dir)
SAIL_LIB_DIR := $(SAIL_DIR)/lib

# --------------------------------------------------------------------------
#  Prelude
# --------------------------------------------------------------------------

PRELUDE = $(SAIL_MODEL_DIR)/prelude/prelude.sail \
          $(SAIL_MODEL_DIR)/prelude/errors.sail

# --------------------------------------------------------------------------
#  "Before core" types (must come before core)
# --------------------------------------------------------------------------

BEFORE_CORE = $(SAIL_MODEL_DIR)/extensions/Zicbop/zicbop_types.sail \
              $(SAIL_MODEL_DIR)/extensions/Zicbom/zicbom_types.sail \
              $(SAIL_MODEL_DIR)/extensions/Zibi/zibi_types.sail \
              $(SAIL_MODEL_DIR)/extensions/A/aext_types.sail \
              $(SAIL_MODEL_DIR)/extensions/I/base_types.sail \
              $(SAIL_MODEL_DIR)/extensions/M/mext_types.sail \
              $(SAIL_MODEL_DIR)/extensions/B/bext_types.sail

# --------------------------------------------------------------------------
#  "Before sys" types (must come before sys, after prelude)
# --------------------------------------------------------------------------

BEFORE_SYS = $(SAIL_MODEL_DIR)/extensions/Stateen/stateen_regs.sail \
             $(SAIL_MODEL_DIR)/extensions/Stateen/stateen_csrs.sail \
             $(SAIL_MODEL_DIR)/extensions/Stateen/stateen_access_checks.sail \
             $(SAIL_MODEL_DIR)/extensions/V/vext_types.sail \
             $(SAIL_MODEL_DIR)/extensions/Zicsr/zicsr_types.sail \
             $(SAIL_MODEL_DIR)/extensions/Zawrs/zawrs_types.sail \
             $(SAIL_MODEL_DIR)/extensions/Zicond/zicond_types.sail \
             $(SAIL_MODEL_DIR)/extensions/K/types_kext.sail \
             $(SAIL_MODEL_DIR)/extensions/cfi/cfi_types.sail \
             $(SAIL_MODEL_DIR)/extensions/cfi/zicfilp_regs.sail \
             $(SAIL_MODEL_DIR)/extensions/Zihintntl/zihintntl_types.sail

# --------------------------------------------------------------------------
#  Core sources
# --------------------------------------------------------------------------

CORE = $(SAIL_MODEL_DIR)/core/xlen.sail \
       $(SAIL_MODEL_DIR)/core/flen.sail \
       $(SAIL_MODEL_DIR)/core/vlen.sail \
       $(SAIL_MODEL_DIR)/core/mem_addrtype.sail \
       $(SAIL_MODEL_DIR)/core/mem_metadata.sail \
       $(SAIL_MODEL_DIR)/core/phys_mem_interface.sail \
       $(SAIL_MODEL_DIR)/core/arithmetic.sail \
       $(SAIL_MODEL_DIR)/core/range_util.sail \
       $(SAIL_MODEL_DIR)/core/float_classify.sail \
       $(SAIL_MODEL_DIR)/core/rvfi_dii.sail \
       $(SAIL_MODEL_DIR)/core/rvfi_dii_v1.sail \
       $(SAIL_MODEL_DIR)/core/rvfi_dii_v2.sail \
       $(SAIL_MODEL_DIR)/core/platform_config.sail \
       $(SAIL_MODEL_DIR)/core/extensions.sail \
       $(SAIL_MODEL_DIR)/core/types_common.sail \
       $(SAIL_MODEL_DIR)/core/types_ext.sail \
       $(SAIL_MODEL_DIR)/core/types.sail \
       $(SAIL_MODEL_DIR)/core/vmem_types.sail \
       $(SAIL_MODEL_DIR)/core/mem_type_utils.sail \
       $(SAIL_MODEL_DIR)/core/csr_begin.sail \
       $(SAIL_MODEL_DIR)/core/callbacks.sail \
       $(SAIL_MODEL_DIR)/core/reg_type.sail \
       $(SAIL_MODEL_DIR)/core/regs.sail \
       $(SAIL_MODEL_DIR)/core/pc_access.sail \
       $(SAIL_MODEL_DIR)/core/sys_regs.sail \
       $(SAIL_MODEL_DIR)/core/ext_regs.sail \
       $(SAIL_MODEL_DIR)/core/interrupt_regs.sail \
       $(SAIL_MODEL_DIR)/core/addr_checks_common.sail \
       $(SAIL_MODEL_DIR)/core/addr_checks.sail \
       $(SAIL_MODEL_DIR)/core/misa_ext.sail \
       $(SAIL_MODEL_DIR)/core/softfloat_interface.sail

FD_CORE = $(SAIL_MODEL_DIR)/extensions/FD/freg_type.sail \
          $(SAIL_MODEL_DIR)/extensions/FD/fdext_regs.sail \
          $(SAIL_MODEL_DIR)/extensions/FD/fdext_control.sail
# --------------------------------------------------------------------------
#  V_core (vector register file + control, requires FD_core)
# --------------------------------------------------------------------------

V_CORE = $(SAIL_MODEL_DIR)/extensions/V/vreg_type.sail \
         $(SAIL_MODEL_DIR)/extensions/V/vext_regs.sail \
         $(SAIL_MODEL_DIR)/extensions/V/vext_control.sail

# --------------------------------------------------------------------------
#  Extensions that sys depends on
# --------------------------------------------------------------------------

SMCNTRPMF = $(SAIL_MODEL_DIR)/extensions/Smcntrpmf/smcntrpmf.sail

# --------------------------------------------------------------------------
#  Exceptions
# --------------------------------------------------------------------------

EXCEPTIONS = $(SAIL_MODEL_DIR)/exceptions/sys_exceptions.sail \
             $(SAIL_MODEL_DIR)/exceptions/sync_exception.sail

# --------------------------------------------------------------------------
#  PMP
# --------------------------------------------------------------------------

PMP = $(SAIL_MODEL_DIR)/pmp/pmp_regs.sail \
      $(SAIL_MODEL_DIR)/pmp/pmp_control.sail

# --------------------------------------------------------------------------
#  System / platform sources
# --------------------------------------------------------------------------

SYS = $(SAIL_MODEL_DIR)/sys/sys_reservation.sail \
      $(SAIL_MODEL_DIR)/sys/sys_control.sail \
      $(SAIL_MODEL_DIR)/sys/platform.sail \
      $(SAIL_MODEL_DIR)/sys/pma.sail \
      $(SAIL_MODEL_DIR)/sys/mem.sail \
      $(SAIL_MODEL_DIR)/sys/vmem_pte.sail \
      $(SAIL_MODEL_DIR)/sys/vmem_ptw.sail \
      $(SAIL_MODEL_DIR)/sys/callbacks.sail \
      $(SAIL_MODEL_DIR)/sys/vmem_tlb.sail \
      $(SAIL_MODEL_DIR)/sys/vmem.sail \
      $(SAIL_MODEL_DIR)/sys/insts_begin.sail \
      $(SAIL_MODEL_DIR)/sys/vmem_utils.sail

# --------------------------------------------------------------------------
#  Additional extension support (CSR / counters, needed by sys or postlude)
# --------------------------------------------------------------------------

EXT_SUPPORT = $(SAIL_MODEL_DIR)/extensions/Zicntr/zicntr_control.sail \
              $(SAIL_MODEL_DIR)/extensions/Zihpm/zihpm.sail \
              $(SAIL_MODEL_DIR)/extensions/Sscofpmf/sscofpmf.sail \
              $(SAIL_MODEL_DIR)/extensions/Ssqosid/ssqosid.sail

# --------------------------------------------------------------------------
#  Instructions: "before I_insts" (must come before base instructions)
# --------------------------------------------------------------------------

BEFORE_I_INSTS = $(SAIL_MODEL_DIR)/extensions/Zihintntl/zihintntl_insts.sail \
                 $(SAIL_MODEL_DIR)/extensions/Zicbop/zicbop_insts.sail \
                 $(SAIL_MODEL_DIR)/extensions/Zihintpause/zihintpause_insts.sail \
                 $(SAIL_MODEL_DIR)/extensions/cfi/zicfilp_insts.sail

# --------------------------------------------------------------------------
#  Base instructions (I extension)
# --------------------------------------------------------------------------

I_INSTS = $(SAIL_MODEL_DIR)/extensions/I/base_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/I/jalr_seq.sail

# --------------------------------------------------------------------------
#  A, M, C, B extension instructions
# --------------------------------------------------------------------------

A_INSTS = $(SAIL_MODEL_DIR)/extensions/A/zaamo_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/A/zalrsc_insts.sail

M_INSTS = $(SAIL_MODEL_DIR)/extensions/M/mext_insts.sail

C_INSTS = #$(SAIL_MODEL_DIR)/extensions/C/zca_insts.sail \
          #$(SAIL_MODEL_DIR)/extensions/C/zcb_insts.sail

B_INSTS = $(SAIL_MODEL_DIR)/extensions/B/zba_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/B/zbb_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/B/zbc_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/B/zbs_insts.sail

# --------------------------------------------------------------------------
#  Floating-point instructions (F + D)
# --------------------------------------------------------------------------

FD_INSTS = $(SAIL_MODEL_DIR)/extensions/FD/fext_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/zcf_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/dext_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/zcd_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/zfh_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/zfa_insts.sail

# --------------------------------------------------------------------------
#  Vector extension instructions (V)
# --------------------------------------------------------------------------

V_INSTS = $(SAIL_MODEL_DIR)/extensions/V/vext_utils_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_fp_utils_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_vset_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_arith_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_fp_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_mem_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_mask_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_vm_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_fp_vm_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_red_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/V/vext_fp_red_insts.sail

# --------------------------------------------------------------------------
#  Other extension instructions (CSR, crypto, fence, cache, hypervisor, etc.)
# --------------------------------------------------------------------------

OTHER_INSTS = $(SAIL_MODEL_DIR)/extensions/Zicsr/zicsr_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/Svinval/svinval_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/Sstc/sstc.sail \
              $(SAIL_MODEL_DIR)/extensions/Zawrs/zawrs_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/Zicond/zicond_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/Zicbom/zicbom_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/Zibi/zibi_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/Zicboz/zicboz_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/Zifencei/zifencei_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/K/zkn_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/K/zks_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/K/zkr_control.sail \
              $(SAIL_MODEL_DIR)/extensions/K/zbkb_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/K/zbkx_insts.sail \
              $(SAIL_MODEL_DIR)/extensions/H/hext_insts.sail

# --------------------------------------------------------------------------
#  May-be-operations (after extensions)
# --------------------------------------------------------------------------

MOPS = $(SAIL_MODEL_DIR)/mops/Zimop/zimop_insts.sail \
       $(SAIL_MODEL_DIR)/mops/Zcmop/zcmop_insts.sail

# --------------------------------------------------------------------------
#  Postlude (step, fetch, decode, etc.)
#  NOTE: model.sail excluded - isla.sail replaces it as the entry point
# --------------------------------------------------------------------------

POSTLUDE = $(SAIL_MODEL_DIR)/postlude/insts_end.sail \
           $(SAIL_MODEL_DIR)/postlude/csr_end.sail \
           $(SAIL_MODEL_DIR)/postlude/step_common.sail \
           $(SAIL_MODEL_DIR)/postlude/step_ext.sail \
           $(SAIL_MODEL_DIR)/postlude/decode_ext.sail \
           $(SAIL_MODEL_DIR)/postlude/fetch_rvfi.sail \
           $(SAIL_MODEL_DIR)/postlude/fetch.sail \
           $(SAIL_MODEL_DIR)/postlude/step.sail

# --------------------------------------------------------------------------
#  Complete ordered source list
# --------------------------------------------------------------------------

SAIL_SRCS = $(PRELUDE) \
            $(BEFORE_CORE) \
            $(CORE) \
            $(BEFORE_SYS) \
            $(FD_CORE) \
            $(V_CORE) \
            $(SMCNTRPMF) \
            $(EXCEPTIONS) \
            $(PMP) \
            $(EXT_SUPPORT) \
            $(SYS) \
            $(BEFORE_I_INSTS) \
            $(I_INSTS) \
            $(A_INSTS) \
            $(M_INSTS) \
            $(C_INSTS) \
            $(B_INSTS) \
            $(FD_INSTS) \
            $(V_INSTS) \
            $(OTHER_INSTS) \
            $(MOPS) \
            $(POSTLUDE)

# --------------------------------------------------------------------------
#  IR generation target (isla)
# --------------------------------------------------------------------------

generated_definitions/riscv_model_%.ir: $(SAIL_SRCS) $(SAIL_ISLA_DIR)/isla.sail Makefile
	mkdir -p generated_definitions/
	isla-sail $(SAIL_FLAGS) --instantiate --all-modules --all-warnings --memo-z3 \
	    --config ./rv32d_v128_e32.json \
		--isla-preserve isla_testgen_init \
		--isla-preserve isla_testgen_step \
		$(SAIL_SRCS) $(SAIL_ISLA_DIR)/isla.sail \
		-o $(basename $@)

# --------------------------------------------------------------------------
#  Phony targets
# --------------------------------------------------------------------------

.PHONY: ir clean

ir: generated_definitions/riscv_model_$(ARCH).ir

footprint:

clean:
	-rm -rf generated_definitions/*.ir
	
