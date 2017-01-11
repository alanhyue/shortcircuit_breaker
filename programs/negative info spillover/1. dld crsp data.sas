* Download compustat data [2009.1.1, 2016.12.31];

%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib COMPUSTAT fundamental annual: compa.funda:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=129&file_id=65811
;

* select compustat datt;
proc sql;
create table seldata as
select a.*
from crspa.msf as a
where '01Jan2009'd<=a.date<='31Dec2010'd
;quit;

* this will be a permanent dataset on the local pc;
proc download data=seldata out=local.neginfo_dsf_test; 
run;
endrsubmit;

data local.neginfo_dsf_test; *substr SIC;
set local.neginfo_dsf_test;
if hsiccd;
_temp=put(hsiccd,4.);
sic=substr(_temp,1,1);
if sic=. then sic=0;
run;

proc print data=local.neginfo_dsf_test (obs=30);
run;
