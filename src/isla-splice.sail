/*=======================================================================================*/
/*  isla-splice.sail: Memory access overrides for isla IR generation                     */
/*                                                                                       */
/*  The upstream model uses sail_mem_write/sail_mem_read via the concurrency              */
/*  interface. For isla, we override write_ram/read_ram to use the simpler                */
/*  __write_memt/__read_memt primitives that isla understands.                            */
/*=======================================================================================*/

val __read_memt
  = impure { ocaml: "Platform.read_memt", c: "platform_read_memt", _: "read_memt" }
  : forall ('rk : Type) 'n 'addrsize, 'n > 0 & 'addrsize in {32, 64}.
  ('rk, bits('addrsize), int('n)) -> (bits(8 * 'n), bit)

val __write_memt
  = impure { ocaml: "Platform.write_memt", c: "platform_write_memt", _: "write_memt" }
  : forall ('wk : Type) 'n 'addrsize, 'n > 0 & 'addrsize in {32, 64}.
  ('wk, bits('addrsize), int('n), bits(8 * 'n), bit) -> bool

function write_ram(wk, Physaddr(addr), width, data, meta) =
  __write_memt(wk, zero_extend(addr), width, data, 0b0)

function read_ram(rk, Physaddr(addr), width, _meta) = {
  let (v, _) = __read_memt(rk, zero_extend(addr), width);
  (v, default_meta)
}
