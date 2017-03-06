* Calculate the Parkinson volatility measure;
* Methodology: the intraday volatility is calculated as 
the logarithm of the daily high price divided by the daily 
low price.
The pre (post) period intraday volatility is calculated as
the time-series average of the secrity in the pre (post) period.
;
* calculate Parkinson measure for all firm-day obs.;
data da;
set my.Permnodata;
parkinson=log(ASKHI/BIDLO);
run;
%Winsorize(din=da,dout=db,var=parkinson);
* cross-sectional average of the parkinson;
proc sql;
create table crosec as 
select date, AVG(parkinson) as avgpark
from db
group by date
;quit;

%AppendSSCBDummy(din=crosec,dout=dc);
PROC PRINT DATA=dc(OBS=10);RUN;

* time-series average of cross-sectional average of Parkinson;
proc reg data=dc;
model avgpark=dsscb;
run;
