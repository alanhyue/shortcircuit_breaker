/* 
Author: Heng Yue 
Create: 2017-01-17 12:39:54
Desc  : Analysis. Mainly rank by different measures and output the 
difference between test variables.
*/
%let rank_by=variance;

proc rank data=my.complete_data out=ranked ties=low group=5;
var &rank_by;
ranks rank_&rank_by;
run;

proc sql;
create table measures as
select rank_&rank_by, 
AVG(variance) as variance,
AVG(avgup) as semiup,
AVG(avgdown) as semidown,
AVG(avgpark) as parkinson
from ranked
group by rank_&rank_by
;quit;

PROC PRINT DATA=measures(OBS=10);RUN;
