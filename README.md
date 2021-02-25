This package provides a command to decompose the growth of an average quantity in a top percentile (in particular, the average wealth).
The syntax is
```
growthpercentile varname  [, Percentile(numlist) TOPindicator(indicatorvariable) save(filename) replace clear Detail]
```
where 
- `varname` is the variable to decompose
- `Percentile` percentile to use (99 to decompose the top 1%). Alternatively specify directly a `indicatorvariable`, which is a dummy variable indicating whether the observation belongs to the top percentile
- `filename` a filepath to save the output as a dataset. Alternatively, `clear` to replace the existing dataset
- `details` provides more intermediary quantities (e.g. average quantity in subsets of individuals)

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
net install growthpercentile, from("~/SOMEFOLDER")
```
