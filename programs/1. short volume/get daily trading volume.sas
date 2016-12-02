* Sample Cloud computing.
This program reads the Compustat data on the UNIX server, downloads it to the local computer, and prints it from the local system.
;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib crspa:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137&file_id=67061
;

proc sql;
create table seldata as
select a.date, sum(a.vol) as daily_vol, sum(a.NUMTRD) as numtrd
from crspa.dsf as a
where "03AUG2009"d<=a.date<="31DEC2015"d
group by a.date
;quit;

* this will be a permanent dataset on the local pc;
proc download data=seldata out=local.crsp_vol_and_numtrd; 
run;
endrsubmit;

proc print data=local.crsp_vol_and_numtrd (obs=30);
run;
