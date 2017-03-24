* find double trigger instances;
proc import out=rawhalts datafile="F:\SCB\data\shohalts.csv" dbms=csv replace;
getnames=yes;
run;
data rawhalts;
set rawhalts;
date=datepart(Trigger_Time);
format date date9.;
run;
proc sort data=rawhalts out=halts nodup;
by Symbol date;
run;
data dhalts;
set halts;
prev=date-1;
format prev date9.;
double=0;
if lag(date)=prev then double=1;
run;

* aggreate No. triggers by date;
proc sql;
create table trgd as
select date, count(*) as nTrigger, sum(double) as doubles
from dhalts
group by date
order by date
;quit;
data trgdadj;
set trgd;
lastdate=lag(date);
prev=date-1;
format prev date9.;
format lastdate date9.;
leftovers=lag(nTrigger);
if lastdate=prev then do;
	overlap=1;
	total=nTrigger+leftovers-doubles;
	end;
else do;
	total=nTrigger;
	end;
run;

* pull CRSP daily number of trading stocks;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;
proc sql;
create table stkd as
select date, count(PRC) as nstk 
from crspa.dsf
where date>="01Jan2010"d
group by date
order by date
;
proc download data=stkd out=my.stkd;run;
endrsubmit;

* merge CRSP and halts counts;
proc sql;
create table mhalt as
select a.date, a.total as naffected,a.doubles, b.nstk, a.total/b.nstk*100 as pctHalt
from trgdadj as a
left join my.stkd as b
on a.date=b.date
order by date
;quit;
PROC PRINT DATA=mhalt(OBS=100);RUN;

* find the average of tha halt pct;
proc means data=mhalt;
var naffected doubles  nstk  pctHalt;
run;
