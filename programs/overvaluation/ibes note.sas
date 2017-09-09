PROC PRINT DATA=ibes.statsum_epsus(OBS=10);RUN;
PROC PRINT DATA=est(OBS=10);RUN;

MEASURE=“EPS” *take EPS forecasts;
and FISCALP=“ANN” * take annual forecasts;
and FPI=‘1’; * take forecasts for fiscal year 1;


* Using DET file;
PROC PRINT DATA=diver(OBS=100);RUN;

PROC PRINT DATA=diver(OBS=300);RUN;

data test;
set ibeswant;
if cusip="00103110";
run;
