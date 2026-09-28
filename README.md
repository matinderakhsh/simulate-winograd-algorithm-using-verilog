# Winograd Convolution Accelerator — F(2×2, 3×3)

A fixed-point hardware implementation of the **Winograd minimal-filtering algorithm** for 2D convolution, F(2×2, 3×3): it computes a 2×2 output tile from a 4×4 input tile and a 3×3 kernel using far fewer multiplications than direct convolution, by transforming the input and kernel into a domain where the core operation becomes a simple element-wise (Hadamard) product.

```
Y (2×2) = Aᵀ ⊙ [ (Bᵀ·X·B) ⊙ (G·W·Gᵀ) ] ⊙ A
```

## Algorithm background

Direct 2×2-output / 3×3-kernel convolution needs 2×2×3×3 = 36 multiplications per tile. Winograd's F(2×2,3×3) algorithm reduces this to **16 multiplications** by pre-transforming the input tile and the kernel with fixed transform matrices (`B`, `G`, `A`, derived from the Chinese Remainder Theorem / polynomial interpolation), multiplying element-wise, then transforming back:

1. **V = Bᵀ · X · B** — transform the 4×4 input tile
2. **U = G · W · Gᵀ** — transform the 3×3 kernel into a 4×4 matrix
3. **M = U ⊙ V** — element-wise (Hadamard) product, 16 multiplications total
4. **Y = Aᵀ · M · A** — transform the result back to the 2×2 output tile

## Fixed-point format

All data ports use `WIDTH = 12` bits, signed, in **s3.8 fixed-point format** (1 sign bit + 3 integer bits + 8 fractional bits) — a value `x` is encoded as `round(x × 256)`. The testbench's `Q()` helper function performs this conversion (`$rtoi(x * 256.0)`).

> Internal pipeline comments in a couple of modules label intermediate stages as "Q4.8" or reference "Q8.16" — these refer to the *intermediate* full-precision product width (before truncation back down to the 12-bit s3.8 format used at every module boundary), not a change in the external interface format. Every module's inputs and outputs are consistently s3.8.

## Module map

| Module | Computes | Latency (`start` → `done`) |
|---|---|---|
| `winograd_constants` | Fixed transform matrices `Bt`, `G`, `At` (combinational constants, `initial`-block) | — (no clock, always valid) |
| `input_transform` | `V = Bᵀ · X · B` | 4 cycles |
| `transform_U` | `U = G · W · Gᵀ` | 4 cycles |
| `hadamard_product` | `M = U ⊙ V` | **2 cycles** |
| `output_transform` | `Y = Aᵀ · M · A` | 4 cycles |
| `top_module` | Top-level FSM sequencing the four stages above | 4+4+2+4 = **14 cycles** total (plus 1 idle→input cycle) |

## Top-level control flow

`top_module` instantiates all five submodules and drives them with a 6-state FSM:

```
S_IDLE → S_INPUT → S_WEIGHT → S_HADAM → S_OUTPUT → S_FINISH → (back to S_IDLE)
```

Each stage is triggered by a one-cycle `start_*` pulse and the FSM advances only once that stage's `done` signal goes high — the stages run **sequentially, not in parallel**, even though `input_transform` and `transform_U` have no data dependency on each other and could in principle run concurrently. `top_module`'s own `done` output is asserted for one cycle in `S_FINISH` before returning to `S_IDLE`.

### Ports

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk`, `rst`, `start` | in | 1 | Clock, synchronous reset, start pulse |
| `X11`…`X44` | in | 12 (signed, s3.8) | 4×4 input tile |
| `W11`…`W33` | in | 12 (signed, s3.8) | 3×3 kernel |
| `Y11, Y12, Y21, Y22` | out | 12 (signed, s3.8) | 2×2 output tile |
| `done` | out | 1 | Pulses high for one cycle when `Y` is valid |

## Pipeline pattern used in each transform stage

`input_transform`, `transform_U`, and `output_transform` all follow the same internal structure:

1. **Matrix multiply #1** (registered, full precision — intermediate width `2·WIDTH+1` or `+2` bits to avoid overflow)
2. **Truncate/rescale** back to `WIDTH` bits: `{result[MSB], result[22:12]}` — takes the sign bit plus an 11-bit slice of the product, discarding the extra fractional precision gained by the multiply
3. **Matrix multiply #2** (the transposed multiply, again full precision)
4. **Truncate/rescale** again → final output + `done`

`hadamard_product` uses a shorter, 2-stage version of the same pattern (one multiply + one rescale, since there's no second matrix multiply — just an element-wise product).

## Testbench (`tb_top_module`)

- Clock: 10 ns period (100 MHz).
- Provides a `Q(real)` helper function to convert human-readable real numbers into s3.8 fixed-point for test stimulus, and divides raw outputs by 256.0 to print them back as real numbers for readability.
- Holds `rst` for 20 ns with all inputs zeroed, then releases it.
- **Test Case 1**: applies a 4×4 input tile with values 1–7 and a 3×3 kernel `[[1,0,1],[0,1,0],[1,0,1]]` (an X-shaped kernel), pulses `start` for one cycle, then `wait(done)`.
- Prints `Y11`–`Y22` both as raw fixed-point integers and as converted real values.

> The testbench only checks one input combination and has no self-checking assertions — it's meant to be read by eye (or cross-checked against a reference direct-convolution calculation in MATLAB/Python/NumPy) rather than pass/fail automatically. Consider adding a known-good reference output and an `if (Y11 !== expected) $display("MISMATCH")`-style check for regression testing.

## Simulation

```bash
# Example with Icarus Verilog
iverilog -o sim tb_top_module.v top_module.v winograd_constants.v input_transform.v transform_U.v hadamard_product.v output_transform.v
vvp sim
```

Expected console output: the raw s3.8 values of `Y11`–`Y22`, followed by their real-number equivalents.

## Known quirks / things to double-check

- In `hadamard_product`, the product register `P` is declared `[2*WIDTH-1:0]` (23 bits for `WIDTH=12`), one bit narrower than the `2*WIDTH` / `2*WIDTH+1`-bit product registers used for the equivalent multiplications in the other three transform modules. Since only bits `[20:10]` are ever read out of it, this hasn't caused a visible bug here, but it's worth confirming there's enough headroom for the largest kernel/input values you expect before relying on it at the edges of the numeric range.
- `winograd_constants` is purely combinational (`initial` block, no clock) — it isn't part of the pipelined latency chain above; its outputs are valid from time 0.

## Possible extensions

- Run `input_transform` and `transform_U` concurrently (they have no data dependency) to shave ~4 cycles off the total per-tile latency.
- Parameterize/generalize beyond the fixed F(2×2,3×3) tile size to support tiling across a full feature map with sliding windows.
- Add self-checking assertions to the testbench against a software (MATLAB/NumPy) reference model.

## License

Add a license of your choice (MIT/Apache-2.0/etc.) if you intend to make this repository public.
