* Calculate Pre- and post-event period volatility;
* Note: SSCB became effective on May 10, 2010;

* seperate the daily price file into pre and post periods;
data pre;
set my.permnodata;
if date<="10May2010"d;
run;

data post;
set my.permnodata;
if date>"10May2010"d;
run;

* calcualte the std for pre and post periods;
proc means data=pre(keep=permno ret) std noprint;
by permno;
output out=pre_std(keep=permno stddev)  std=stddev;
run;

proc means data=post(keep=permno ret) std noprint;
by permno;
output out=post_std(keep=permno stddev)  std=stddev;
run;

*merge these two periods together;
proc sql;
create table merged as
select a.permno, a.stddev as pre, b.stddev as post
from pre_std as a, post_std as b
where a.permno=b.permno
;quit;

* 
1. calculate variance from stddev
2. calculate diff.
;
data result;
set merged;
pre_vol=pre*pre;
post_vol=post*post;
diff=post_vol-pre_vol;
drop pre post;
run;

* move the result to my lib;
data my.pre_post_vol;
set result;
run;

PROC PRINT DATA=my.pre_post_vol(OBS=10);RUN;
