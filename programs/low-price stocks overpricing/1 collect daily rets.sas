* match daily price, low, and high for selected firms;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname my 'C:\Users\yu_heng\Downloads\';

* Prepare unique PERMNO;
data haspermno;
set my.haltslink;
if permno;
run;

proc sort data=haspermno out=unique nodupkey;
by permno;
run;

* Reference to lib crspa:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137&file_id=67061;

rsubmit;

proc upload data=unique out=secus;run;

proc sql;
create table seldata as
select a.PERMNO, a.date, a.prc, a.BIDLO, a.ASKHI, a.ret
from crspa.dsf as a, secus as b
where a.permno=b.permno and '10Nov2010'd<=a.date
;quit;
* Organize the data base.
1. calculate the return from PRC.
2. reverse the negative PRC to positive. They are 
	negative because it is calculated from bid/ask 
	price.
;
data org;
set seldata;
if prc<0 then prc=-prc;
if ret<0 then ret=-ret;
/*ret=(prc-lag(prc))/lag(prc);*/
run;

* this will be a permanent dataset on the local pc;
proc download data=org out=my.stkret; 
run;
endrsubmit;
