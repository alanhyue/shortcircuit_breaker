* match daily price, low, and high for selected firms;
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname my 'C:\Users\yu_heng\Downloads\';

rsubmit;

* Reference to lib crspa:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137&file_id=67061
The crspa.stocknames table description:
https://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=137&file_id=67080
;
* select data sample;
data sample;
set crspa.DSENAMES ;
run;

* this will be a permanent dataset on the local pc;
proc download data=sample out=DSENAMES ; 
run;
endrsubmit;

PROC PRINT DATA=DSENAMES (OBS=100);RUN;
