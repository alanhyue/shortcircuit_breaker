PROC PRINT DATA=my.sample_price_daily(OBS=10);RUN;

proc sql;
select permno, count(*) as N
from my.sample_price_daily
group by permno
;quit;

%Winsorize(din=my.sample_price_daily,dout=a,var=prc);
%Winsorize(din=a,dout=b,var=ret);

* check sample stock price distribution;
proc univariate data=b;
var prc;
histogram prc;
run;

* check sample return distribution;
proc univariate data=b;
var ret;
histogram ret;
run;

* check the number of stocks in the sample;
proc sort data=my.sample_price_daily out=temp nodupkey;
by permno;
run;
proc sql;
select count(*) as Unique_stocks
from temp
;quit;
