/* 
Author: Heng Yue 
Create: 2017-01-11 15:19:00
Update: 2017-01-11 15:19:00
Desc  : Analysis.
*/
* subtotal by rank_sector_beta;
proc sql;
create table subtotal as
select rank_sector_beta, sum(nDecline) as nDecline, sum(total) as total
from my.mged_beta_funda_decline
group by rank_sector_beta
;quit;
data subtotal;
set subtotal;
pct=nDecline/total;
run;

%MACRO FundaSort(din=,var=);
* 2x2 sort;
proc sort data=&din out=_temp;
by rank_sector_beta;
run;
proc rank data=_temp out=_rank2x2 groups=5 ties=low;
var &var;
ranks rank_&var;
by rank_sector_beta;
run;
* construct result;
proc sql;
create table _subtotal as
select rank_sector_beta, rank_&var, sum(nDecline) as nDecline, sum(total) as total
from _rank2x2
group by rank_sector_beta, rank_&var
;quit;
data _subtotal; * limited to those with more than 10 obs.;
set _subtotal;
if total>=10 then pct=nDecline/total;
else pct=.;
run;
* tabulate;
proc tabulate data=_subtotal;
var pct;
class rank_sector_beta rank_&var;
table rank_sector_beta*pct, rank_&var;
run;
%MEND FundaSort;
PROC PRINT DATA=my.mged_beta_funda_decline(OBS=3);RUN;
%FundaSort(din=my.mged_beta_funda_decline,var=size_avg);
