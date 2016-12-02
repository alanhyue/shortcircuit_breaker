data a;
set sh2009;
run;

data sh2009;
set my.shvol2009;
if "01Jan2009"d<=date<"01Jan2010"d;
run;

data sh2010;
set my.shvol2010;
if "01Jan2010"d<=date<"01Jan2011"d;
run;

proc append base=a data=my.shvol2015;run;
PROC PRINT DATA=a(OBS=10);RUN;
proc sql;
select count(*) as N
from a
;quit;

proc sort data=a out=b nodup;
by date;
run;

PROC PRINT DATA=b(OBS=200);RUN;
data my.shvol;
set b;
run;
