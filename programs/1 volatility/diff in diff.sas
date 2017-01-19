/* 
Author: Heng Yue 
Create: 2017-01-19 15:38:58
Desc  : Prepare data for diff-in-diff regression.
*/
* create a new copy of the table;
data permnodata;
set my.permnodata;
run;
* calculate the close-close volatility;
* because the RET is already calculated using closing prices, 
the close-close volatility is simply the square of RET;
data calc;
set permnodata;
* Close-to-close volatility;
ccvol=ret*ret; 
* semivariance;
lgret=log(prc/lag(prc));
if lgret<0 then up=0;
else up=lgret*lgret;
if lgret>0 then down=0;
else down=lgret*lgret;
* Parkinson volatility;
parkinson=log(ASKHI/BIDLO);
run;

%AppendSSCBDummy(din=calc,dout=calc);

* mark if a stock ever triggered sscb;
data valid;
set my.haltslink_clean;
if permno;
DSCBGROUP=1;
run;
proc sort data=valid nodupkey;by permno;run;

proc sql;
create table final as
select a.*, b.DSCBGROUP
from calc as a
left join valid as b
on a.permno=b.permno
;quit;

data final2;
set final;
if DSCBGROUP=. then DSCBGROUP=0;
SCBINTGROUP=DSCBGROUP*DSSCB;
run;

* FINALLY!;
proc reg data=final2;
model parkinson=DSSCB DSCBGROUP SCBINTGROUP /VIF;
run;

PROC PRINT DATA=final2(where=(DSCBGROUP=1) OBS=1000);RUN;
proc univariate data=final;var DSCBGROUP;run;