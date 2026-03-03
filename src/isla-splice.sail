/* 1. External Memory Mappings */
/* We keep the val declarations with mappings as they are 'specs' */

val __read_memt : forall ('rk : Type) 'n, 'n > 0. ('rk, bits(32), int('n)) -> (bits(8 * 'n), bit) effect {rmem} = {
  ocaml: "Platform.read_memt",
  c: "platform_read_memt",
  isla: "read_memt",
  _: "read_memt"
}

val __write_memt : forall ('wk : Type) 'n, 'n > 0. ('wk, bits(32), int('n), bits(8 * 'n), bit) -> bool effect {wmv} = {
  ocaml: "Platform.write_memt",
  c: "platform_write_memt",
  isla: "write_memt",
  _: "write_memt"
}

/* 2. Memory Helpers */

/* Use 'bit' or 'bits(1)' instead of 'Meta' if Meta isn't defined in the base model */
val write_ram : forall ('wk : Type) 'n, 'n > 0. ('wk, PhysAddr, int('n), bits(8 * 'n), bit) -> bool effect {wmv}
function write_ram(wk, Physaddr(addr), width, data, meta) = {
  __write_memt(wk, addr, width, data, 0b0)
}

val read_ram : forall ('rk : Type) 'n, 'n > 0. ('rk, PhysAddr, int('n), bit) -> (bits(8 * 'n), bit) effect {rmem}
function read_ram(rk, Physaddr(addr), width, _meta) = {
  let (v, tag) = __read_memt(rk, addr, width);
  /* 0b0 is a literal for 'bit', so we don't need the default_meta constant */
  (v, 0b0)
}
