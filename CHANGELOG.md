# Changelog

The decomposition itself (`total`, `within`, `between`, `inflow`, `outflow`, `demography`, `birth`, `death`, `popgrowth`) has the same definition in every version. Changes concern the output layout, the input checks, and the options.

## Upgrading from 1.x

Two changes break scripts written for version 1:

- The output no longer contains the time variable itself (say `year`). It contains `year0` (start of the period) and `year1` (end of the period); version 1's `year` is `year1`. To keep old code running, add `rename year1 year` after the command.
- With `detail`, the group sizes are `N_P0`, `N_P1`, `N_I`, `N_O`, `N_B`, `N_D` instead of `n_P0`, `n_P1`, `n_I`, `n_O`, `n_B`, `n_D`.

## 2.2.0 (2026-10-26)

### Breaking
- Requires Stata 16 or later (previously 11.2), because the computation runs in a frame.
- Results are stored in double precision (previously float), so they can differ from earlier versions in the last digits.
- Specifying both `save()` and `clear` is an error. Version 2.1 saved the output and ignored `clear`.

### Added
- `top0()` and `top1()`, an alternative to `top()` for when the top at `t` differs depending on whether `t` is the start of the period from `t` to `t+1` (`top0`) or the end of the period from `t-1` to `t` (`top1`). For instance, some individuals are excluded from one specific period, or the size of the top is set period by period. `top(x)` is the same as `top0(x) top1(x)`.
- `by()`: the decomposition is computed separately within each group. An individual who moves from one group to another exits the first group and enters the second.
- `fweight`s: an individual with weight `w` counts as `w` identical individuals. The weight must be constant over time within each individual.

### Changed
- The command works on a frame holding only the variables it uses, instead of preserving the whole dataset.
- `timevar0` and `timevar1` have the storage type and display format of the time variable.
- New error when no individual is in the top in some period other than the first (previously the command stopped with a less specific error).

## 2.1.0 (2026-03-22)

### Breaking
- Stops with an error when the average of `varname` in the top, or among the individuals of the top who survive to the next period, is zero or negative. Version 2.0 returned results for negative averages.

### Changed
- `top()` is required in the syntax. It was optional, but the command failed without it.
- Clear error message when the data is not `tsset`.
- Adds a `version 11.2` statement.

### Added
- Test suite (`test/test_topdecompose.do`).

## 2.0.0 (2026-03-22)

### Breaking
- The output replaces the time variable `timevar` with `timevar0` (start of the period) and `timevar1` (end of the period). Version 1's `timevar` is `timevar1`.
- With `detail`, the group sizes are renamed from `n_*` to `N_*` (lowercase n is the relative mass in the paper).
- The check that `varname` is weakly higher for individuals in the top than for individuals out of the top is exact. Version 1 allowed the lowest value in the top to be below the highest value out of the top by up to one unit.

### Added
- With `detail`, the threshold at the start of the period, `q0`.
- Support for time steps other than one (the `delta()` of `tsset`). Version 1 stopped with the "Terms do not sum" error.
- Variable labels on the output.
- Worked example on the Forbes 400 (`example/`).

### Changed
- Clearer error messages, including a dedicated error when no individual of the top survives to the next period (version 1 stopped with the "Terms do not sum" error).

## 1.0.0 (2022-08-19)

Publication version.
