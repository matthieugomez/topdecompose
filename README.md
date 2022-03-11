This package provides a command to decompose the growth of an average quantity in a top percentile (in particular, the average wealth). This implements the accountiong framework defined in [Decomposing the Growth of Top Wealth Shares](https://www.matthieugomez.com/files/topshares.pdf) by Matthieu Gomez

```
topdecompose varname  [,  top(dummyvariable) save(filename) replace clear Detail]
```
where 
- `varname` is the variable to decompose
- `top` is a dummy variable indicating whether the observation belongs to the top percentile or not
- `filename` a filepath to save the output as a dataset. Alternatively, `clear` to clear the existing dataset with the output.
- `Detail` provides more intermediary quantities (e.g. average quantity in subsets of individuals)

The dataset needs to be declared as panel data before the command (using `tsset` or `xtsset`)
# Installation

```
net install topdecompose from("https://raw.githubusercontent.com/matthieugomez/topdecompose/master/")
```
If you have a version of Stata < 13, you need to install it manually

Click the "Download ZIP" button in the right column to download a zipfile.

Extract it into a folder (e.g. ~/SOMEFOLDER)

Run
```
net install topdecompose, from("~/SOMEFOLDER")
```
