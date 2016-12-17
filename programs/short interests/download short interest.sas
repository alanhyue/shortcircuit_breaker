* match daily price, low, and high for selected firms;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname my 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib crspa:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137&file_id=67061;

data si;
/*set crsp.stocknames  (obs=100);*/
set compm.sec_shortint;
if "01Jan2007"d<=datadate<="31Dec2013"d;
/*txt=input(cusip,$10.);*/
/*cusip8=substr(txt,1,8);*/
run;

* this will be a permanent dataset on the local pc;
proc download data=si out=my.downlodd; 
run;
endrsubmit;

proc print data=my.downlodd (obs=30);
run;
