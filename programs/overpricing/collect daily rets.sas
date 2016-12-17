* match daily price, low, and high for selected firms;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname my 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib crspa:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137&file_id=67061;

proc upload data=my.Alive_secus out=secus;run;

proc sql;
create table seldata as
select a.PERMNO, a.date, a.prc, a.BIDLO, a.ASKHI, a.ret
from crspa.dsf as a, secus as b
where a.permno=b.permno and '01Jan2007'd<=a.date<='31Dec2013'd
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
