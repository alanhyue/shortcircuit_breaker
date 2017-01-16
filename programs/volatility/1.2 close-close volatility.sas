/* close-close volatility is the square of the returns 
based on the closing prices */

*Calculate Pre- and post-event period volatility;
* Note: the compliance date of SSCB is 10 Nov 2010;

* create a new copy of the table;
data permnodata;
set my.permnodata;
run;
* calculate the close-close volatility;
* because the RET is already calculated using closing prices, 
the close-close volatility is simply the square of RET;
data ccvol;
set permnodata;
ccvol=ret*ret;
run;

* winsorize the 1 percentile;
%Winsorize(din=ccvol,dout=ccvolwinso,var=ccvol);
* cross-section average of the volatility;
proc sql;
create table crosec as
select date, AVG(ccvol) as avgccvol
from ccvolwinso
group by date
order by date
;quit;
* append sscb dummy;
%AppendSSCBDummy(din=crosec,dout=withdummy);
PROC PRINT DATA=withdummy(OBS=10);RUN;
* time-series average using regression;
proc reg data=withdummy;
model avgccvol=dsscb;
run;


* seperate the daily price file into pre and post periods;
data a;
set my.permnodata;
if date<="10May2010"d then dsscb=0;
else dsscb=1;
run;

* calcualte the std for pre and post periods;
proc means data=a var noprint;
by permno dsscb;
var ret;
output out=outvar  var=/autoname;
run;

* transpose the table to put pre and post period
variance on the same row;
proc transpose data=outvar out=test name=dsscb
prefix=dumval;
var ret_Var;
by permno;
run;

*calculate the diff;
data withdiff;
set test(rename=(dumval1=pre dumval2=post) drop=dsscb);
diff=post-pre;
run;

* move the result to my lib;
data my.pre_post_vol;
set withdiff;
run;

PROC PRINT DATA=my.pre_post_vol(OBS=10);RUN;
