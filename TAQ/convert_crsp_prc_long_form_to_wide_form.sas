proc import datafile="C:\Users\yu_heng\Downloads\security prices.xlsx" out=prices replace;
getnames=yes;
run;

PROC PRINT DATA=prices(OBS=10);RUN;

proc sort data=prices out=prices;
by names_date;
run;
proc transpose data=prices out=wide;
 by Names_Date;
 id permno;
 var Price_or_Bid_Ask_Average;
run;

PROC PRINT DATA=wide(OBS=10);RUN;

proc export data=wide(drop=_name_ _label_) outfile='C:\Users\yu_heng\Downloads\prices.xlsx' dbms=XLSX;run;
