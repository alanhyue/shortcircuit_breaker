* Sample Cloud computing.
This program reads the Compustat data on the UNIX server, downloads it to the local computer, and prints it from the local system.
;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;

libname comp '/wrds/compustat/sasdata';

* this is a temporary dataset on the unix machine;
data mydata;
set comp.compann;
where yeara=2002;

* this will be a permanent dataset on the local pc;
proc download data=mydata out=local.compustatdata; 
run;
endrsubmit;

proc print data=local.compustatdata (obs=30);
run;
