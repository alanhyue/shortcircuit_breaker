/* 
Author: Heng Yue 
Create: 2017-03-06 09:25:08
Desc  : calculate the standard volatilty from daily price for a security
table IN:
static.dsf
table OUT:
prepost_variance
*/

/*Step 1. append the sscb dummy;*/
%AppendSSCBDummy(din=static.dsf,dout=dsf_scb);

/*Step 2. Calculate the pre- and post-circuit breaker period variances*/
* sort before running PROC MEANS by permno;
proc sort data=dsf_scb out=dsf_scb_sorted;
by dsscb permno date;
run;
* calculate the volatility for each firm;
proc means data=dsf_scb_sorted var noprint;
by dsscb permno;
var ret;
output out=prepost_variance var=variance;
run;
