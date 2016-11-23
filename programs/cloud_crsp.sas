* Sample Cloud computing.
This program reads the Compustat data on the UNIX server, downloads it to the local computer, and prints it from the local system.
;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib crspa:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137&file_id=67061;

* this is a temporary dataset on the unix machine;
/*data mydata;*/
/*set crspa.dsf;*/
/*where PERMNO=10138;*/

proc upload data=my.test_secus out=test_secus;run;

proc sql;
create table seldata as
select a.*
from crspa.dsf as a, test_secus as b
where a.permno=b.permno and '01Jan2007'd<=a.date<='07Jan2007'd
;quit;

* this will be a permanent dataset on the local pc;
proc download data=seldata out=local.permnodata; 
run;
endrsubmit;

proc print data=local.permnodata (obs=30);
run;
