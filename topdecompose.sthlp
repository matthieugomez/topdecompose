{smcl}
{* *! version 0.1 7feb2021}{...}
{viewerjumpto "Syntax" "topdecompose##syntax"}{...}
{viewerjumpto "Description" "topdecompose##description"}{...}
{viewerjumpto "Options" "topdecompose##options"}{...}
{viewerjumpto "Examples" "topdecompose##examples"}{...}
{viewerjumpto "References" "topdecompose##references"}{...}
{viewerjumpto "Author" "topdecompose##contact"}{...}



{title:Title}

{p2colset 4 24 24 8}{...}
{p2col :{cmd:topdecompose} {hline 2}}Decompose the growth of an average variable in a top percentile{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:topdecompose} {varname} {cmd:,} [ {help topdecompose##options:options}]{p_end}

{marker description}{...}
{title:Description}

{pstd}
The command decomposes the growth of the average {varname} in a top percentile group. It returns the total growth of the average variable as well as its decomposition into a within, between (inflow and outflow), and demography (birth, death, and population growth) terms. The original dataset must be in a panel form (using {help tsset} or {help xtset}). 


{marker options}{...}
{title:Options}

{synoptset 25 tabbed}{...}
{synoptline}

{synopt:{opth p:ercentile(numlist)}} Percentile to use. Number between 0 and 100 (e.g., specify 99 to decompose the top 1%). Default to 0. {p_end}

{synopt:{opth top:indicator(strings:varname)}} Dummy variable indicating whether the observation is in the top percentile or not. {p_end}

{synopt:{opth save(filename)}}  Save output in an external dataset. {p_end}

{synopt:{opt replace}}  Overwrite the filename when using the {cmd:save} option.

{synopt:{opt clear}}  Replace the existing dataset with the result of decomposition (alternative to the {cmd:save} option). {p_end}

{synopt:{opt d:etail}}  Returns the cardinality and the average wealth within subsets of individuals used for the decomposition. {p_end}


{marker examples}{...}
{title:Examples}

{pstd}Prepare dataset of id x year x wealth{p_end}
{phang2}{cmd:. set obs 100}{p_end}
{phang2}{cmd:. gen id = _n}{p_end}
{phang2}{cmd:. expand  2}{p_end}
{phang2}{cmd:. gen year = _n > 100}{p_end}
{phang2}{cmd:. drop if  runiform() <= 0.1}{p_end}
{phang2}{cmd:. gen wealth = runiform()}{p_end}
{pstd}Create indicator variable{p_end}
{phang2}{cmd:. bys year (wealth): gen dummy = _n >= 0.9 * _N}{p_end}
{pstd}Do the decomposition{p_end}
{phang2}{cmd:. tsset id year}{p_end}
{phang2}{cmd:. topdecompose wealth, top(dummy) clear}{p_end}

{marker references}{...}
{title:References}

{phang}
Matthieu Gomez. "Decomposing the Growth of Top Wealth Shares"
{p_end}


{marker contact}{...}
{title:Author}

{phang}
Matthieu Gomez
{p_end}

{phang}
Department of Economics, Columbia University
{p_end}

{phang}
Please report any issue on Github
{browse "https://github.com/matthieugomez/topdecompose":https://github.com/matthieugomez/topdecompose}
{p_end}


