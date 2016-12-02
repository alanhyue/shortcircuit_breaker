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

/*proc upload data=my.permnodata(keep=permno date) out=secus;run;*/
proc upload data=my.Alive_secus out=alive_secus;run;

proc sql;
create table secus as
select a.permno, a.date
from crspa.dsf as a, alive_secus as b
where a.permno=b.permno and '01Jan2007'd<=a.date<='31Dec2013'd
;quit;


proc sql;
create table seldata as
select b.*,  a.cusip, a.htick, a.htsymbol
from secus as b
left join crspa.dsfhdr as a
on a.permno=b.permno and a.begdat<=b.date<=a.enddat
;quit;

* this will be a permanent dataset on the local pc;
proc download data=seldata out=local.from_server; 
run;
endrsubmit;

* filter unique PERMNO->Ticker matches;
proc sort data=my.from_server out=a nodupkey;
by permno htick;
run;
PROC PRINT DATA=a(OBS=10);RUN;
* check if it's a 1-to-1 match;
* If it is, there should be 0 obs deleted.;
proc sort data=a out=b nodupkey;
by permno;
run;
* save to local drive;
data my.permno_to_ticker;
set b;
run;

proc print data=local.permno_to_ticker (obs=30);
run;
