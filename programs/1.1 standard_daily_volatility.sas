* calculate the standard volatilty from daily price for a security;

* calculate volatility for each firm;
proc means data=my.permnodata var noprint;
by permno;
var ret;
output out=want var=variance;
run;

* cross-sectional average of the firms volatility;
* TODO;

PROC PRINT DATA=want (OBS=10);RUN;


data with_vol;
set want;
vol=stddev*stddev;
drop stddev;
run;

PROC PRINT DATA=with_vol(OBS=10);RUN;
