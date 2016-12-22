* match daily price, low, and high for selected firms;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname my 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib crspa:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137&file_id=67061;


proc sql;
create table want as
select a.*, b.CSHOQ
from compm.sec_shortint as a
left join compm.secm as b
on a.gvkey=b.gvkey and year(a.datadate)=year(b.datadate)
	and month(a.datadate)=month(b.datadate)
where "01Jan2007"d<=a.datadate<="31Dec2013"d;

;quit;


* this will be a permanent dataset on the local pc;
proc download data=want out=my.short_interest; 
run;
endrsubmit;

proc print data=my.short_interest (obs=30);
run;
