proc import datafile="C:\Users\yu_heng\Downloads\shohalts.txt" out=halts replace;
getnames=yes;
delimiter=',';
run;

data my.halts;
set halts;
run;

PROC PRINT DATA=halts(OBS=183235
 firstobs=183220);RUN;
