%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

libname local 'C:\Users\yu_heng\Downloads\';

rsubmit;

proc download data=ibes.DET_EPSUS out=DET_EPSUS;run;
endrsubmit;


data local.DET_EPSUS;
set DET_EPSUS;
run;

* the local file is moved to the data\ibes folder under the SCB project;
