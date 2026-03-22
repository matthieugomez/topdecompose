{smcl}
{* *! version 2.1.0 March 2026}{...}
{viewerjumpto "Syntax" "topdecompose##syntax"}{...}
{viewerjumpto "Description" "topdecompose##description"}{...}
{viewerjumpto "Options" "topdecompose##options"}{...}
{viewerjumpto "Output" "topdecompose##output"}{...}
{viewerjumpto "Examples" "topdecompose##examples"}{...}
{viewerjumpto "References" "topdecompose##references"}{...}
{viewerjumpto "Author" "topdecompose##contact"}{...}


{title:Title}

{p2colset 4 24 24 8}{...}
{p2col :{cmd:topdecompose} {hline 2}}Decompose the growth of an average variable in a top percentile{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:topdecompose} {varname} {cmd:,} {cmd:top(}{it:dummyvar}{cmd:)} {{cmd:save(}{it:filename}{cmd:)} [{cmd:replace}] | {cmd:clear}} [{cmd:prefix(}{it:string}{cmd:)} {cmd:detail}]{p_end}


{marker description}{...}
{title:Description}

{pstd}
Suppose you have an unbalanced panel dataset of individuals observed over multiple years.
Every year, individuals are ranked with respect to some variable (e.g., wealth),
and you assign a variable {cmd:top} equal to 1 if the individual is in a
top percentile, 0 if the individual is in the economy but not in the top,
and missing if the individual is not in the economy (or simply not observed in the panel that year).

{pstd}
{cmd:topdecompose} decomposes the growth of the average {varname} in the top percentile
into interpretable components. It does so by classifying each individual into one of
five mutually exclusive groups based on their {cmd:top} status across consecutive periods:

{p2colset 8 20 22 2}{...}
{p2col :{bf:Stayer}}in the top at both {it:t}=0 and {it:t}=1 ({cmd:top} goes from 1 to 1){p_end}
{p2col :{bf:Outflow}}leaves the top ({cmd:top} goes from 1 to 0){p_end}
{p2col :{bf:Inflow}}enters the top ({cmd:top} goes from 0 to 1){p_end}
{p2col :{bf:Death}}in the top at {it:t}=0, then exits the economy ({cmd:top} goes from 1 to {cmd:.}){p_end}
{p2col :{bf:Birth}}enters the economy into the top ({cmd:top} goes from {cmd:.} to 1){p_end}
{p2colreset}{...}

{pstd}
An individual is considered "not in the economy" when the program cannot find
a value of {cmd:top} equal to 0 or 1 for that individual at that time. This
happens in two cases: either the individual has no observation in the panel for
that period, or the individual has an observation but {cmd:top} is set to
missing ({cmd:.}). Both formats are accepted and treated identically.

{pstd}
These five groups generate an exact decomposition of the growth of average {varname}
in the top percentile into three terms:

{p2colset 8 24 26 2}{...}
{p2col :{bf:Within}}the wealth growth of individuals initially in the top (excluding deaths),
holding the composition of the top fixed{p_end}
{p2col :{bf:Between}}composition changes among individuals present in both periods
(= Inflow + Outflow); always non-negative{p_end}
{p2col :{bf:Demography}}composition changes from individuals entering or exiting the economy
(= Birth + Death + Population Growth){p_end}
{p2colreset}{...}

{pstd}
The decomposition is exact: {bf:total = within + between + demography}.

{pstd}
When {varname} is individual wealth normalized by mean wealth in the economy, the
decomposition applies to the growth of the top wealth {it:share}.

{marker requirements}{...}
{title:Input requirements}

{pstd}
The input dataset must satisfy the following:

{phang}1. The dataset must be declared as panel data (using {help tsset}).{p_end}

{phang}2. {varname} must not be missing when {cmd:top} == 1 (individuals in the top).{p_end}

{phang}3. {varname} must not be missing for individuals who were in the top in the
previous period and remain in the economy (i.e., {cmd:top} == 0 and lagged {cmd:top} == 1).
This is because the decomposition requires tracking the growth of {varname} for all
individuals initially in the top, whether or not they remain in the top.{p_end}


{marker options}{...}
{title:Options}

{synoptset 25 tabbed}{...}
{synoptline}

{synopt:{cmd:top(}{it:dummyvar}{cmd:)}}a variable equal to 1 if the individual
is in the top percentile, 0 if below the top but in the economy, or missing
if not in the economy.{p_end}

{synopt:{opth save(filename)}}save the output in an external dataset.{p_end}

{synopt:{opt replace}}overwrite the file when using the {cmd:save} option.{p_end}

{synopt:{opt clear}}replace the existing dataset with the decomposition output
(alternative to {cmd:save}).{p_end}

{synopt:{cmd:prefix(}{it:string}{cmd:)}}prefix for the output variable names
(e.g., {cmd:prefix(w_)} produces {cmd:w_total}, {cmd:w_within}, etc.).{p_end}

{synopt:{opt d:etail}}additionally return the number of observations in each group,
the average {varname} in each group, and the percentile thresholds.{p_end}

{synoptline}


{marker output}{...}
{title:Output}

{pstd}
The command produces a dataset with one row per transition period containing:

{synoptset 25 tabbed}{...}
{synoptline}
{synopt:{it:timevar}{cmd:0}, {it:timevar}{cmd:1}}start and end of the period{p_end}
{synopt:{cmd:total}}total growth of average {varname} in the top percentile{p_end}
{synopt:{cmd:within}}within component{p_end}
{synopt:{cmd:between}}between component (= {cmd:inflow} + {cmd:outflow}){p_end}
{synopt:{cmd:inflow}}inflow component{p_end}
{synopt:{cmd:outflow}}outflow component{p_end}
{synopt:{cmd:demography}}demography component (= {cmd:birth} + {cmd:death} + {cmd:popgrowth}){p_end}
{synopt:{cmd:birth}}birth component{p_end}
{synopt:{cmd:death}}death component{p_end}
{synopt:{cmd:popgrowth}}population growth component{p_end}
{synoptline}

{pstd}
With the {cmd:detail} option, the output additionally includes:

{synoptset 25 tabbed}{...}
{synoptline}
{synopt:{cmd:N_P0}, {cmd:N_P1}}number of observations in the top at {it:t}=0 and {it:t}=1{p_end}
{synopt:{cmd:N_I}, {cmd:N_O}, {cmd:N_B}, {cmd:N_D}}number of observations in each group{p_end}
{synopt:{cmd:w0_P0}}average {varname} in the top at {it:t}=0{p_end}
{synopt:{cmd:w1_P1}}average {varname} in the top at {it:t}=1{p_end}
{synopt:{cmd:w1_I}, {cmd:w1_O}, {cmd:w1_B}}average {varname} at {it:t}=1 for inflow, outflow, and birth groups{p_end}
{synopt:{cmd:w0_D}}average {varname} at {it:t}=0 for the death group{p_end}
{synopt:{cmd:q0}, {cmd:q1}}percentile threshold at {it:t}=0 and {it:t}=1{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{pstd}Prepare a panel dataset of id x year x wealth{p_end}
{phang2}{cmd:. set obs 100}{p_end}
{phang2}{cmd:. gen id = _n}{p_end}
{phang2}{cmd:. expand 2}{p_end}
{phang2}{cmd:. bys id: gen year = _n - 1}{p_end}
{phang2}{cmd:. drop if runiform() <= 0.1}{p_end}
{phang2}{cmd:. gen wealth = runiform()}{p_end}

{pstd}Create the top indicator{p_end}
{phang2}{cmd:. bys year (wealth): gen top = _n >= 0.9 * _N}{p_end}

{pstd}Run the decomposition{p_end}
{phang2}{cmd:. tsset id year}{p_end}
{phang2}{cmd:. topdecompose wealth, top(top) clear}{p_end}

{pstd}Run the decomposition with detailed output{p_end}
{phang2}{cmd:. topdecompose wealth, top(top) clear detail}{p_end}


{marker references}{...}
{title:References}

{phang}
Gomez, Matthieu. "Decomposing the Growth of Top Wealth Shares." {it:Econometrica}, 2024.
{p_end}


{marker contact}{...}
{title:Author}

{phang}
Matthieu Gomez, Department of Economics, Columbia University
{p_end}

{phang}
Please report any issue on GitHub:
{browse "https://github.com/matthieugomez/topdecompose":https://github.com/matthieugomez/topdecompose}
{p_end}
