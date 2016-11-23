* calculate the standard volatilty from daily price for a security;
/*data test;*/
/*set my.permnodata;*/
/*if permno<10338;*/
/*run;*/

proc means data=my.permnodata std noprint;
by permno;
var ret;
output out=want (keep=permno stddev)  std=stddev;
run;

data with_vol;
set want;
vol=stddev*stddev;
drop stddev;
run;

PROC PRINT DATA=with_vol(OBS=10);RUN;
