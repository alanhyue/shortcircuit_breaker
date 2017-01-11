/* 
Author: Heng Yue 
Create: 2017-01-10 17:14:43
Update: 2017-01-10 17:14:43
Desc  : Calculate equally-weighted industry indices.
*/
data neginfo_dsf_test;
set my.neginfo_dsf_test;
run;

proc sql;
create table ind_indices as
select a.sic, a.date, AVG(a.ret) as ind_ew_ret
from neginfo_dsf_test as a
group by sic, date
;quit;

data my.sic1_indices;
set ind_indices;
format date yymmn6.;
run;
PROC PRINT DATA=a(OBS=10);RUN;
PROC PRINT DATA=ind_indices(OBS=100);RUN;
