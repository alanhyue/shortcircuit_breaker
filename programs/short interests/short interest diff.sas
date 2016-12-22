data si;
set my.short_interest;
year=year(datadate);
month=month(datadate);
run;

data haltfirm;
set my.haltslink;
if gvkey;
run;

* append the halts data to the short interst data;
proc sql;
create table want as 
select a.*, b.*
from si as a
left join haltfirm as b
on a.gvkey=b.gvkey and 0<=a.datadate-date<=31
;quit;

* cross-sectional average;
proc sql;
create table crosec as
select year,month, AVG(shortint) as avgSI
from want
group by year, month
;quit;

*apend dsscb dummy;
data wdummy;
set crosec;
dsscb=0;
if year>2010 then dsscb=1;
if year=2010 and month>=11 then dsscb=1;
run;
* time-series average of the cross-sectional average;
proc reg data=wdummy;
model avgSI=dsscb;
run;

proc sgplot data=wdummy;
scatter x=month y=avgSI;
run;

PROC PRINT DATA=wdummy(OBS=100);RUN;
