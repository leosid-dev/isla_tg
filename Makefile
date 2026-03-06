MAKE_ROOT ?= .
ISLA_SAIL := $(MAKE_ROOT)/isla/isla-sail
SAIL_RISCV := $(MAKE_ROOT)/sail-riscv
ISLA_SRC := $(MAKE_ROOT)/isla
ISLA_BUILD := $(ISLA_SRC)/target/release
ISLA_TG_SRC := $(MAKE_ROOT)/isla-testgen
ISLA_TG_BUILD := $(ISLA_TG_SRC)/target/release

SAIL_ISLA_DIR = $(MAKE_ROOT)/src

# Opam switch configuration
OPAM_SWITCH ?= 5.1.0
OPAM_EXEC ?= opam exec --switch $(OPAM_SWITCH) --

check-prereq:
	@echo "Checking prerequisites..."
	@command -v opam >/dev/null 2>&1 || { echo "Error: opam not found. Please install opam >= 2.0"; exit 1; }
	@if [ ! -d "$(HOME)/.opam" ]; then \
		echo "Opam not initialized. Running opam init..."; \
		opam init --bare -y || { echo "Error: failed to initialize opam"; exit 1; }; \
	fi
	@if ! opam switch list --short | grep -qx "$(OPAM_SWITCH)"; then \
		echo "Opam switch $(OPAM_SWITCH) not found. Creating it..."; \
		opam switch create $(OPAM_SWITCH) || { echo "Error: failed to create opam switch $(OPAM_SWITCH)"; exit 1; }; \
	fi
	@command -v rustc >/dev/null 2>&1 || { echo "Error: rustc not found. Please install Rust (https://rustup.rs/)"; exit 1; }
	@command -v cargo >/dev/null 2>&1 || { echo "Error: cargo not found. Please install Rust (https://rustup.rs/)"; exit 1; }
	@command -v z3 >/dev/null 2>&1 || { echo "Error: z3 not found. Please install z3"; exit 1; }
	@if ! $(OPAM_EXEC) command -v dune >/dev/null 2>&1; then \
		echo "Dune not found in opam switch $(OPAM_SWITCH). Installing dune..."; \
		opam install dune -y --switch $(OPAM_SWITCH); \
	fi
	@command -v pkg-config >/dev/null 2>&1 || { echo "Error: pkg-config not found. Please install pkg-config"; exit 1; }
	@pkg-config --exists gmp || { echo "Error: gmp not found. Please install libgmp-dev"; exit 1; }
	@echo "All prerequisites found in opam switch $(OPAM_SWITCH)."

init-submodules:
	@echo "Initializing and updating submodules to latest remote commits..."
	git submodule update --init --recursive

install-sail: init-submodules check-prereq
	@if $(OPAM_EXEC) command -v sail >/dev/null 2>&1; then \
		echo "Sail is already installed in switch $(OPAM_SWITCH)."; \
	else \
		echo "Installing Sail in switch $(OPAM_SWITCH)..."; \
		opam install sail -y --switch $(OPAM_SWITCH); \
	fi

install-isla: init-submodules check-prereq
	@if [ -d $(ISLA_BUILD) ];then \
		echo "Isla is already installed."; \
	else \
		echo "Installing Isla "; \
		$(OPAM_EXEC) $(MAKE) -C $(ISLA_SRC) isla isla-sail; \
	fi
	
install-isla-testgen: init-submodules
	@if [ -d $(ISLA_TG_BUILD) ];then \
	echo "Isla testgen is already installed."; \
	else \
		echo "Installing Isla Testgen "; \
		cd $(ISLA_TG_SRC) && \
		cargo build --release; \
	fi

install-sail-riscv: init-submodules
	@echo "Checking Sail RISC-V model..."
	@test -d $(SAIL_RISCV)/model || { echo "Error: $(SAIL_RISCV)/model not found. Submodule update failed?"; exit 1; }
	@cd $(SAIL_RISCV) && \
	$(OPAM_EXEC) command ./build_simulator.sh

install-all: install-sail install-isla install-isla-testgen
	@echo "All components installed successfully."

# Default architecture
ARCH ?= RV32
ifeq ($(ARCH),32)
  override ARCH := RV32
else ifeq ($(ARCH),64)
  override ARCH := RV64
endif


SAIL_MODEL_DIR=$(SAIL_RISCV)/model

#--------------------------------------------------------------------------------------------------
#  Prelude

PRELUDE = $(SAIL_MODEL_DIR)/prelude/prelude.sail \
          $(SAIL_MODEL_DIR)/prelude/errors.sail


BEFORE_CORE = $(SAIL_MODEL_DIR)/extensions/Zicbop/zicbop_types.sail \
              $(SAIL_MODEL_DIR)/extensions/Zicbom/zicbom_types.sail \
              $(SAIL_MODEL_DIR)/extensions/Zibi/zibi_types.sail \
              $(SAIL_MODEL_DIR)/extensions/A/aext_types.sail \
              $(SAIL_MODEL_DIR)/extensions/I/base_types.sail \
              $(SAIL_MODEL_DIR)/extensions/M/mext_types.sail \
              $(SAIL_MODEL_DIR)/extensions/B/bext_types.sail


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

#--------------------------------------------------------------------------------------------------
#  Core sources

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

#  V_core


V_CORE = $(SAIL_MODEL_DIR)/extensions/V/vreg_type.sail \
         $(SAIL_MODEL_DIR)/extensions/V/vext_regs.sail \
         $(SAIL_MODEL_DIR)/extensions/V/vext_control.sail


SMCNTRPMF = $(SAIL_MODEL_DIR)/extensions/Smcntrpmf/smcntrpmf.sail


EXCEPTIONS = $(SAIL_MODEL_DIR)/exceptions/sys_exceptions.sail \
             $(SAIL_MODEL_DIR)/exceptions/sync_exception.sail



PMP = $(SAIL_MODEL_DIR)/pmp/pmp_regs.sail \
      $(SAIL_MODEL_DIR)/pmp/pmp_control.sail



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


EXT_SUPPORT = $(SAIL_MODEL_DIR)/extensions/Zicntr/zicntr_control.sail \
              $(SAIL_MODEL_DIR)/extensions/Zihpm/zihpm.sail \
              $(SAIL_MODEL_DIR)/extensions/Sscofpmf/sscofpmf.sail \
              $(SAIL_MODEL_DIR)/extensions/Ssqosid/ssqosid.sail

BEFORE_I_INSTS = $(SAIL_MODEL_DIR)/extensions/Zihintntl/zihintntl_insts.sail \
                 $(SAIL_MODEL_DIR)/extensions/Zicbop/zicbop_insts.sail \
                 $(SAIL_MODEL_DIR)/extensions/Zihintpause/zihintpause_insts.sail \
                 $(SAIL_MODEL_DIR)/extensions/cfi/zicfilp_insts.sail


I_INSTS = $(SAIL_MODEL_DIR)/extensions/I/base_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/I/jalr_seq.sail

#--------------------------------------------------------------------------------------------------
#Extensions

A_INSTS = $(SAIL_MODEL_DIR)/extensions/A/zaamo_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/A/zalrsc_insts.sail

M_INSTS = $(SAIL_MODEL_DIR)/extensions/M/mext_insts.sail

C_INSTS = #$(SAIL_MODEL_DIR)/extensions/C/zca_insts.sail \
          #$(SAIL_MODEL_DIR)/extensions/C/zcb_insts.sail

B_INSTS = $(SAIL_MODEL_DIR)/extensions/B/zba_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/B/zbb_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/B/zbc_insts.sail \
          $(SAIL_MODEL_DIR)/extensions/B/zbs_insts.sail


FD_INSTS = $(SAIL_MODEL_DIR)/extensions/FD/fext_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/zcf_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/dext_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/zcd_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/zfh_insts.sail \
           $(SAIL_MODEL_DIR)/extensions/FD/zfa_insts.sail


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


MOPS = $(SAIL_MODEL_DIR)/mops/Zimop/zimop_insts.sail \
       $(SAIL_MODEL_DIR)/mops/Zcmop/zcmop_insts.sail

#--------------------------------------------------------------------------------------------------
#  Postlude

POSTLUDE = $(SAIL_MODEL_DIR)/postlude/insts_end.sail \
           $(SAIL_MODEL_DIR)/postlude/csr_end.sail \
           $(SAIL_MODEL_DIR)/postlude/step_common.sail \
           $(SAIL_MODEL_DIR)/postlude/step_ext.sail \
           $(SAIL_MODEL_DIR)/postlude/decode_ext.sail \
           $(SAIL_MODEL_DIR)/postlude/fetch_rvfi.sail \
           $(SAIL_MODEL_DIR)/postlude/fetch.sail \
           $(SAIL_MODEL_DIR)/postlude/step.sail

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

#--------------------------------------------------------------------------------------------------

generated_definitions/riscv_model_%.ir: $(SAIL_SRCS) $(SAIL_ISLA_DIR)/isla.sail Makefile
	mkdir -p generated_definitions/
	$(OPAM_EXEC) $(ISLA_SAIL)/isla-sail $(SAIL_FLAGS) --config ./rv32d_v128_e32.json --instantiate --all-modules --all-warnings --memo-z3 \
		--isla-preserve isla_footprint \
		--isla-preserve isla_testgen_init \
		--isla-preserve isla_testgen_step \
		$(SAIL_SRCS) $(SAIL_ISLA_DIR)/isla.sail \
		-o $(basename $@)

ir: generated_definitions/riscv_model_$(ARCH).ir

fp: ir
	$(ISLA_BUILD)/isla-footprint -s -A generated_definitions/riscv_model_$(ARCH).ir -C ./rv32_core.toml \
	    -i "vadd.vv v24, v8, v16"
	
tg: ir
	$(ISLA_TG_BUILD)/isla-testgen -a cheriot -A generated_definitions/riscv_model_$(ARCH).ir -C ./rv32_core.toml    

clean:
	rm -rf generated_definitions
	
purge:
	rm -rf generated_definitions/*.ir $(ISLA_BUILD) $(ISLA_TG_BUILD)
	

.PHONY: ir clean purge check-prereq init-submodules install-sail install-isla install-isla-testgen install-sail-riscv install-all
	
