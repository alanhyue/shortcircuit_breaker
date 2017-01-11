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

* subtotal by rank_sector_beta;
proc sql;
create table subtotal as
select rank_sector_beta, sum(nDecline) as nDecline, sum(total) as total
from mg
group by rank_sector_beta
;quit;
data subtotal;
set subtotal;
pct=nDecline/total;
run;
PROC PRINT DATA=subtotal(OBS=10);RUN;
