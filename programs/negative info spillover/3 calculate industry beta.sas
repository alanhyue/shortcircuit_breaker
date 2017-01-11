/* 
Author: Heng Yue 
Create: 2017-01-10 18:05:14
Update: 2017-01-10 18:05:14
Desc  : calculate industry beta for stocks, estimation period is [T-1yr, T]
*/
data neginfo_dsf_test;
set my.neginfo_dsf_test;
format date yymmn6.;
run;

proc sql;
create table mg as
select a.*, b.ind_ew_ret
from neginfo_dsf_test as a
left join my.sic1_indices as b
on a.sic=b.sic and a.date=b.date
order by sic,date, permno
;quit;

proc sort data=mg; by permno;run;

* Indutry beta estimation;
proc reg data=mg noprint outest=regresult;
model ind_ew_ret=ret;
by permno;
run;

PROC PRINT DATA=regresult(OBS=100);RUN;

data my.industry_beta;
set regresult;
run;
