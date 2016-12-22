* Sample Cloud computing.
This program reads the Compustat data on the UNIX server, downloads it to the local computer, and prints it from the local system.
;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib crspa:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137
Search for table: DSFHDR (daily stock file header)
;

* this is a temporary dataset on the unix machine;
/*data mydata;*/
/*set crspa.dsf;*/
/*where PERMNO=10138;*/

proc upload data=my.halts out=halts;run;
data halts;
set halts;
date=datepart(trigger_time);
run;

proc sql;
create table wcusip as
select a.cusip, a.permno, a.begdat,a.enddat, b.*
from halts as b
left join crspa.dsfhdr as a 
on a.htsymbol=b.symbol and a.begdat<=b.date<=a.enddat
;quit;

* this will be a permanent dataset on the local pc;
proc download data=wcusip out=local._from_server; 
run;
endrsubmit;


proc print data=local._from_server (obs=30);
run;
