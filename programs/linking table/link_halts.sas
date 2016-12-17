PROC PRINT DATA=halts(OBS=10);RUN;

%TickerLinkAll(din=halts,dout=a);
%CusipLinkGvkey(din=a,dout=b);
PROC PRINT DATA=b(OBS=1000);RUN;

data my.haltslink;
set b;
drop Security_Name Market_Category Trigger_Time ;
run;

PROC PRINT DATA=my.haltslink(OBS=10);RUN;
