This package provides a command to decompose the growth of an average wealth in a top wealth percentile into a within term, a displacement term, and a demography term.

The syntax is
```
growthpercentile varname  [, GROUPindicator(indicatorvariable) save(filename) replace clear Detail]
```
where 
- `varname` is the variable to decompose
- `groupindicator` is a dummy variable indicating whether the observation belongs to the top percentile. When not specified, the decomposition is done for the top 100%.
- `filename` a filepath to save the output as a dataset
- `clear` means that the output replaces existing dataset
- `details` provides more intermediary quantities such as average wealth in subsets of individuals

# References

Matthieu Gomez *Decomposing the Growth of Top Wealth Shares*. Working Paper

# Installation

```
net install growthpercentile from("https://raw.githubusercontent.com/matthieugomez/growthpercentile/master/")
```
If you have a version of Stata < 13, you need to install it manually

Click the "Download ZIP" button in the right column to download a zipfile.

Extract it into a folder (e.g. ~/SOMEFOLDER)

Run
```
cap ado uninstall growthpercentile
net install growthpercentile, from("~/SOMEFOLDER")
```