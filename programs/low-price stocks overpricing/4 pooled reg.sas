* pooled regression ;
proc reg data=mglow;
model ret=dsscb dlow;
run;

proc panel data=mglow;
model ret=dsscb dlow /parks;
id permno date;
run;
PROC PRINT DATA=mglow(OBS=10);RUN;
