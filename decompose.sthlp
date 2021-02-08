{smcl}
{* *! version 0.1 7feb2021}{...}
{viewerjumpto "Syntax" "decompose##syntax"}{...}
{viewerjumpto "Description" "decompose##description"}{...}
{viewerjumpto "Options" "decompose##options"}{...}
{viewerjumpto "Examples" "decompose##examples"}{...}
{viewerjumpto "Stored results" "decompose##results"}{...}
{viewerjumpto "References" "decompose##references"}{...}
{viewerjumpto "Author" "decompose##contact"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:decompose} {hline 2}}Decomposing the Growth of the Average Wealth in a Top Wealth Percentile{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}


{p 8 15 2} {cmd:decompose}
{varname} 
{cmd:,} 
{opth top(indicatorvariable)} 
{p_end}

{marker description}{...}
{title:Description}

{pstd}
The command decomposes the growth of an average variable ({varname}) in a top percentile over time. It returns a within term, a displacement term, and a demography term. The original dataset must be in a panel form.



{marker options}{...}
{title:Options}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt top(indicatorvariable)}}  Dummy variable indicating whether the observation is in the top percentile or not. 


{marker examples}{...}
{title:Examples}
{pstd}Decompose average income in top 1% for a dataset with id, year, income{p_end}
{phang2}{cmd:. bys year (income): gen top = _N -_n + 1 <= 0.01 * _N}{p_end}
{phang2}{cmd:. tsset id year}{p_end}
{phang2}{cmd:. decompose income, top(top)}{p_end}

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


