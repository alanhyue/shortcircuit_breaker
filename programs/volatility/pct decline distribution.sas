/*Calculate the semivariance. 
The approach refers to the Diether et al. (2009) "It's SHO time" paper. P31.
*/

data da;
set my.permnodata;
by permno;
decpct=(bidlo-lag(prc))/lag(prc);
decpct=decpct;
if first.permno then delete;
run;

* delete unusual observations;
data cutoff;
set da;
if decpct<-1 then delete;
run;
%Winsorize(din=cutoff,dout=db,var=decpct);
%AppendSSCBDummy(din=db,dout=dc);

* draw the frequency distribution;
proc univariate data=dc(where=(dsscb=0));
var decpct;
histogram decpct;
run;

proc univariate data=dc(where=(dsscb=1));
var decpct;
histogram decpct;
run;

* calculate the percentage of DECPCT that is below -10%;
* PRE-BREAKER;
data pretotal;
set dc(where=(dsscb=0));
run;
data prebelow;
set pretotal;
if decpct<-0.10;
run;
proc sql; 
select count(*) into:below
from prebelow
;quit;
proc sql;
select count(*) into:total
from pretotal
;quit;
%put # total is &total;
%put # below -10% is &below;
%put the percentage below -10% is %sysevalf(&below/&total);
* POST-BREAKER;
data pretotal;
set dc(where=(dsscb=1));
run;
data prebelow;
set pretotal;
if decpct<-0.10;
run;
proc sql; 
select count(*) into:below
from prebelow
;quit;
proc sql;
select count(*) into:total
from pretotal
;quit;
%put # total is &total;
%put # below -10% is &below;
%put the percentage below -10% is %sysevalf(&below/&total);

***********tests**********************;
proc sort data=da out=sorted;
by decpct;
run;
PROC PRINT DATA=sorted(firstobs=7796200 OBS=7796311);RUN;
proc sort data=dc out=test;by permno date;run;
PROC PRINT DATA=test(OBS=1000);RUN;

data tmp;
set da;
if permno=80960;
run;
PROC PRINT DATA=tmp(OBS=3000);RUN;
