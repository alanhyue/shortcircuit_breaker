/* 
Author: Heng Yue 
Create: 2017-01-11 13:54:04
Update: 2017-01-11 13:54:04
Desc  : Merge ranked fundamental table with decline dummy.
*/
proc sql;
create table mg as
select a.*, b.nDecline as nDecline, b.total as total
from mg_funda_ranked as a
left join nextdecline as b
on a.permno=b.permno
;quit;

* save to local drive;
data my.mged_beta_funda_decline;
set mg;
run;

