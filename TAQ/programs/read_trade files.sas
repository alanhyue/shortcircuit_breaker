* get Begin and End;
data a;
set Tindex;
if symbol ="MSFT";
run;

PROC PRINT DATA=a(OBS=10);RUN;
* Use Begin and End, read TyyymmX.BIN;
data TBin;
infile "C:\Users\yu_heng\Downloads\T201105B.BIN" truncover 
LRECL=19 recfm=f firstobs=17713075 obs=17885781;
input
ttim pibr4.
price pibr4.4
siz pibr4.
G127 pibr2.
corr pibr2.
cond $2.
ex $1.
;
run;
PROC PRINT DATA=tbin(OBS=1000);RUN;

PROC PRINT DATA=date2(OBS=10);RUN;

data my.date2;
set date2;
run;

PROC PRINT DATA=taqref.date2(OBS=10);RUN;
