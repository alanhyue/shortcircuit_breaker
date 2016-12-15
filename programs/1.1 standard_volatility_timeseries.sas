* calculate the standard volatilty from daily price for a security;

* create a new copy of the table;
data permnodata;
set my.permnodata;
run;

* winsorize the firm-day obs;
%Winsorize(din=permnodata,dout=permwinso,var=ret);
* append the sscb dummy;
%AppendSSCBDummy(din=permwinso,dout=permnowithdummy);

* (1/2)calculate variance of the period before SSCB breaker was implemented;
* sort before running PROC MEANS by permno;
proc sort data=permnowithdummy(where=(dsscb=0)) out=presscb;
by permno date;
run;
* calculate the volatility for each firm;
proc means data=presscb var noprint;
by permno;
var ret;
output out=prewant var=variance;
run;
* cross-sectional average of the volatility;
proc means data=prewant mean;
var variance;
run;


* (2/2)calculate variance after the SSCB breaker has been implemented;
* sort before running PROC MEANS by permno;
proc sort data=permnowithdummy(where=(dsscb=1)) out=postsscb;
by permno date;
run;
* calculate the volatility for each firm;
proc means data=postsscb var noprint;
by permno;
var ret;
output out=postwant var=variance;
run;
* cross-sectional average of the volatility;
proc means data=postwant mean;
var variance;
run;
