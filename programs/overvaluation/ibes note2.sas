PROC PRINT DATA=filter_epsus(OBS=100);RUN;

* Keep the specific EPS forecasts;
data filter_epsus;
set ibes.statsum_epsus;
if MEASURE="EPS" and FISCALP="ANN" and FPI="1"; * take annual forecasts. take EPS forecasts. take forecasts for fiscal year 1;
run;

* merge IBES with DSF;
proc sql;
create table matchibes as
select a.*, 
	b.statpers,b.numest,b.numup,b.numdown,b.medest,b.meanest,b.stdev,b.highest,b.lowest
from prepdata as a
left join filter_epsus as b
on a.cusip=b.cusip and year(a.date)-1=year(b.FPEDATS) and month(a.date)=month(b.FPEDATS)
where a.datedif=0
order by permno, evt, date
;quit;

* Delete those without forecast STD and calculate IBES dispersion;
data ibeswant;
set matchibes;
if STDEV and MEANEST ne 0;
analdis1=STDEV/MEANEST;
analdis2=(HIGHEST-LOWEST)/MEANEST;
run;


%histo(din=want,var=NUMEST);
