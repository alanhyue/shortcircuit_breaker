* add a dummpy;
data withdummy;
set my.shvol_crsp;
if date<="10May2010"d then dsscb=0;
else dsscb=1;
rel_short=shvol/daily_vol;
run;

PROC PRINT DATA=withdummy(OBS=10);RUN;
%let tb=withdummy ;
%let Y=rel_short ;
%let X=dsscb ;

proc reg data=&tb;
model &Y=&X;
run;

proc sgplot data=withdummy;
scatter x=date y=dsscb;
run;
