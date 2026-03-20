# topdecompose

Suppose you have an unbalanced panel dataset of individuals, each observed over multiple years. Every year, individuals are ranked with respect to some variable — say, wealth — and you assign a variable `top` equal to 1 if the individual is in a top percentile (e.g., the top 1%), 0 if the individual is in the economy but not in the top, and missing if the individual is not in the economy (or simply not observed in the panel that year).

The average wealth in the top percentile changes over time. But why? Is it because individuals who stay in the top are getting richer (*within*)? Because high-wealth individuals are moving into the top while low-wealth individuals drop out (*between*)? Or because of demographic turnover — births, deaths, and population growth (*demography*)?

This Stata command answers these questions. It decomposes the growth of average wealth in the top percentile into interpretable components, by classifying each individual into one of five mutually exclusive groups based on their `top` status across consecutive periods:

<p align="center">
  <img src="figure/classification.png" width="500">
</p>

- **Stayer**: in the top in both periods (`top` goes from 1 to 1)
- **Outflow**: drops out of the top (`top` goes from 1 to 0)
- **Inflow**: enters the top from below (`top` goes from 0 to 1)
- **Death**: in the top, then exits the economy (`top` goes from 1 to `.`)
- **Birth**: enters the economy into the top (`top` goes from `.` to 1)

An individual is considered "not in the economy" when the program cannot find a value of `top` equal to 0 or 1 for that individual at that time. This happens in two cases: either the individual has no observation in the panel for that period, or the individual has an observation but `top` is set to missing (`.`). Both formats are accepted and treated identically.

These five groups generate an exact decomposition into three terms:

- **Within** — how much would average wealth in the top have grown if nobody moved in or out? This captures the wealth growth of individuals initially in the top (excluding deaths).
- **Between** = Inflow + Outflow — how much do composition changes among existing individuals contribute? Individuals with high wealth growth enter the top, while those with low wealth growth drop out. This term is always non-negative.
- **Demography** = Birth + Death + Population Growth — how much does demographic turnover contribute? This captures individuals entering or exiting the economy.

The decomposition is exact: **total = within + between + demography**.

When wealth is normalized by mean wealth in the economy, this decomposition applies to the growth of the top wealth *share*. For a formal derivation, see [Decomposing the Growth of Top Wealth Shares](https://www.matthieugomez.com/files/topshares.pdf) (Gomez, *Econometrica*, 2024).

## Usage

The dataset must be declared as panel data (using `tsset`). Here is a minimal example:

```stata
* Create a panel of 100 individuals over 2 years
set obs 100
gen id = _n
expand 2
bys id: gen year = _n - 1
drop if runiform() <= 0.1
gen wealth = runiform()

* Define the top 10%
bys year (wealth): gen top = _n >= 0.9 * _N

* Run the decomposition
tsset id year
topdecompose wealth, top(top) clear
list
```

### Syntax

```stata
topdecompose varname, top(dummyvar) {save(filename) [replace] | clear} [prefix(string) detail]
```

**Required arguments:**
- `varname` — the variable to decompose (e.g., wealth)
- `top(dummyvar)` — a variable equal to 1 if the individual is in the top percentile, 0 if below the top but in the economy, or missing if not in the economy

**Output options (one required):**
- `save(filename)` — save the decomposition to an external dataset (`replace` to overwrite)
- `clear` — replace the current dataset with the decomposition output

**Optional:**
- `prefix(string)` — prefix for output variable names (e.g., `prefix(w_)` produces `w_total`, `w_within`, etc.)
- `detail` — additionally return the number of observations in each group, the average wealth in each group, and the percentile thresholds

### Output

The command produces a dataset with one row per transition period containing:

| Variable | Description |
|----------|-------------|
| `year0`, `year1` | Start and end of the period |
| `total` | Total growth of average wealth in the top percentile |
| `within` | Within component |
| `between` | Between component (= `inflow` + `outflow`) |
| `inflow` | Inflow component |
| `outflow` | Outflow component |
| `demography` | Demography component (= `birth` + `death` + `popgrowth`) |
| `birth` | Birth component |
| `death` | Death component |
| `popgrowth` | Population growth component |

With the `detail` option, the output additionally includes the number of observations in each group (`N_P0`, `N_P1`, `N_I`, `N_O`, `N_B`, `N_D`), the average wealth at time 0 and/or time 1 in each group (`w0_P0`, `w1_P1`, `w1_I`, `w1_O`, `w1_B`, `w0_D`), and the percentile threshold at each time (`q0`, `q1`).

## Example: Forbes 400

The `example/` folder contains a worked example applying the decomposition to the Forbes 400, the list of the 400 wealthiest Americans published annually by Forbes (2011–2022). See [`example/example.do`](example/example.do) for the full code.

## Installation

```stata
net install topdecompose, from("https://raw.githubusercontent.com/matthieugomez/topdecompose/master/")
```

## References

Gomez, Matthieu. ["Decomposing the Growth of Top Wealth Shares."](https://doi.org/10.3982/ECTA21396) *Econometrica*, 2024.

## Author

Matthieu Gomez, Department of Economics, Columbia University.

Please report issues on [GitHub](https://github.com/matthieugomez/topdecompose).
