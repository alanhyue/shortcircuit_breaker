data funda_halts;
set my.funda_halts;
run;
PROC PRINT DATA=funda_halts(OBS=10);RUN;

%TestDecilePortfo(din=funda_halts,dout=a,var=cf_to_prc);
%TestDecilePortfo(din=funda_halts,dout=a,var=earning_to_prc);
%TestDecilePortfo(din=funda_halts,dout=a,var=book_to_market);


* cluster year;	
proc sql;
create table decile_rank as
select avg(earning_to_prc_rank), avg(earnings)



/* testing the rank result */
proc sort data=a out=b;
by earnings;
run;

proc sql;
select year, earnings_rank, avg(earnings) as AVG_earnings, count(*) as N
from a
group by year, earnings_rank
;quit;
/*PROC PRINT DATA=b(OBS=100);RUN;*/
