%PERMNO2GVKEY(din=my.permnodata,dout=wgvkey);

PROC PRINT DATA=unique_gvkey(OBS=100);RUN;

proc sort data=wgvkey out=unique_gvkey nodupkey;by gvkey;run;
* Download compustat data [2009.1.1, 2016.12.31];

%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib COMPUSTAT fundamental annual: compa.funda:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=129&file_id=65811
;
proc upload data=unique_gvkey(keep=permno gvkey date) out=mygvkey;run;

* select compustat datt;
proc sql;
create table seldata as
select a.*, b.AT
from mygvkey as a
left join compa.funda as b
on a.gvkey=b.gvkey and year(a.date)=b.fyear
;quit;

* this will be a permanent dataset on the local pc;
proc download data=seldata out=local.marketquality;run;
endrsubmit;

data wAT;
set local.marketquality;
if AT;
run;

proc sort data=wAT out=unique nodupkey; by gvkey AT;run;
PROC PRINT DATA=unique(OBS=10);RUN;

data local.matchtable;
set unique;
run;
