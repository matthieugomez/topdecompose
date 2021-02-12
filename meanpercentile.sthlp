{smcl}
{* *! version 0.1 7feb2021}{...}
{viewerjumpto "Syntax" "meanpercentile##syntax"}{...}
{viewerjumpto "Description" "meanpercentile##description"}{...}
{viewerjumpto "Options" "meanpercentile##options"}{...}
{viewerjumpto "Examples" "meanpercentile##examples"}{...}
{viewerjumpto "Stored results" "meanpercentile##results"}{...}
{viewerjumpto "References" "meanpercentile##references"}{...}
{viewerjumpto "Author" "meanpercentile##contact"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:meanpercentile} {hline 2}}Decomposing the Growth of the Average Wealth in a Top Percentile{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}


{p 8 15 2} {cmd:meanpercentile}
{varname}
{cmd:using filename}
[
{cmd:,}
{opth top(indicatorvar)}] 
{p_end}

{marker description}{...}
{title:Description}

{pstd}
The command decomposes the growth of an average variable ({varname}) in a top percentile (indicated by {it:indicatorvar}) over time. It returns a within, inflow, outflow, birth, death, and population growth terms. The original dataset must be in a panel form. The decomposition is saved in an external dataset specified by {it:filename}



{marker options}{...}
{title:Options}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt top(indicatorvar)}}  Dummy variable indicating whether the observation is in the top percentile or not. When left unspecified, the decomposition is done for the top 100%.


{marker examples}{...}
{title:Examples}
{pstd}Decompose average income in top 1% for a dataset with id, year, income{p_end}
{phang2}{cmd:. bys year (income): gen top = _N -_n + 1 <= 0.01 * _N}{p_end}
{phang2}{cmd:. tsset id year}{p_end}
{phang2}{cmd:. meanpercentile income using ~/tempfile, top(top)}{p_end}

{marker references}{...}
{title:References}

{phang}
Matthieu Gomez. "Decomposing the Growth of Top Wealth Shares"
{p_end}


{marker contact}{...}
{title:Author}

{phang}
Matthieu Gomez

{phang}
Department of Economics, Columbia University

{phang}
Please report issues on Github
{browse "https://github.com/matthieugomez/decomposing_the_growth_of_top_wealth_shares":https://github.com/matthieugomez/decomposing_the_growth_of_top_wealth_shares}
{p_end}


