* add a dummpy;
data withdummy;
set my.shvol_crsp;
/*if date<="10May2010"d then dsscb=0;*/
if date<="10Nov2010"d then dsscb=0;
else dsscb=1;
rel_short=shvol/daily_vol;
run;

PROC PRINT DATA=withdummy(OBS=10);RUN;

proc means data=withdummy mean;
var shvol;
by dsscb;
run;

* test for the change in daily market short volume;
proc reg data=withdummy;
model shvol=dsscb;
run;

* test for change in number of short trades;
proc reg data=withdummy;
model num_of_short_order=dsscb;
run;

* test for change in average short size;
proc reg data=withdummy;
model avg_short_size=dsscb;
run;

* test for change in average trade size;
proc reg data=withdummy;
model avg_trdsize=dsscb;
run;

* test for change in relative short size;
proc reg data=withdummy;
model rel_short=dsscb;
run;

proc sgplot data=withdummy;
scatter x=date y=dsscb;
run;
