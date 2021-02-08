This package provides the code to decompose the growth of an average wealth in a top wealth percentile, following

Matthieu Gomez "Decomposing the Growth of Top Wealth Shares". Working Paper

The overall syntax is

`decompose [varname], top(indicatorvariable)`

where `varname` is the variable to decompose and `indicatorvariable` is a dummy variable indicating whether the observation belongs to the top percentile.



# Installation
net install decompose, from("https://raw.githubusercontent.com/matthieugomez/decomposing_the_growth_of_top_wealth_shares/master/")
If you have a version of Stata < 13, you need to install it manually

Click the "Download ZIP" button in the right column to download a zipfile.

Extract it into a folder (e.g. ~/SOMEFOLDER)

Run

cap ado uninstall decompose
net install decompose, from("~/SOMEFOLDER")