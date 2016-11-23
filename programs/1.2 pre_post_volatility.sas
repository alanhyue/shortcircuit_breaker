* Calculate Pre- and post-event period volatility;
* Note: SSCB became effective on May 10, 2010;

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
