data test;
set my.Permnodata;
if date<="10May2010"d then dsscb=0;
else dsscb=1;
run;

proc model data=test;
parms b0 b1;
ret=b0+b1*dsscb;
FIT ret/GMM Kernel=(BART,20,0);
RUN;

PROC PRINT DATA=test(OBS=10);RUN;
