PROC PRINT DATA=halts(OBS=10);RUN;

%TickerLinkAll(din=halts,dout=a);
%CusipLinkGvkey(din=a,dout=b);
PROC PRINT DATA=b(OBS=1000);RUN;

data my.haltslink;
set b;
drop Security_Name Market_Category Trigger_Time ;
run;

PROC PRINT DATA=my.haltslink(OBS=10);RUN;

proc sort data=my.haltslink out=_temp nodup;by descending date ticker;run;
data my.haltslink_clean;
set _temp;
if date>='01Jan2016'd then delete;* delete obs outside of matching db;
if length(ticker)>=5 then delete; * keep companies with normal tickers;
run;

