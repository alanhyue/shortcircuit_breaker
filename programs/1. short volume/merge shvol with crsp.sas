
* merge the shvol table with the crsp table;
proc sql;
create table a as
select a.*, b.daily_vol, b.numtrd
from my.shvol as a
left join my.crsp_vol_and_numtrd as b
on a.date=b.date
;quit;

* calculate the average dailry trading volume;
data b;
set a;
avg_trdsize=daily_vol/numtrd;
run;


PROC PRINT DATA=b(OBS=10);RUN;
* save the result to local dive;
data my.shvol_crsp;
set b;
run;
