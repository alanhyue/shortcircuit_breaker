libname dld 'C:\Users\yu_heng\Downloads\';

PROC PRINT DATA=dld.crsp(OBS=10);RUN;

proc sort data=dld.crsp out=prices;
by date;
run;
proc transpose data=prices out=wide;
 by date;
 id permno;
 var prc;
run;

PROC PRINT DATA=wide(OBS=10);RUN;
