* Calculate the Parkinson volatility measure;
data da;
set my.Permnodata;
parkinson=log(ASKHI/BIDLO);
run;

* save it to local drive;
data my.parkinson;
set da;
keep permno date parkinson;
run;

PROC PRINT DATA=my.parkinson(OBS=10);RUN;
/**/
/*data da;*/
/*set my.Permnodata;*/
/*x=log(ASKHI/BIDLO);*/
/*s1=x**2/(4*log(2));*/
/*run;*/
/**/
/*proc sql;*/
/*create table db as*/
/*select permno, sum(s1)/84 as s2*/
/*from da*/
/*group by permno*/
/*;quit;*/
/**/
/*data dc;*/
/*set db;*/
/*parkinson=sqrt(s2);*/
/*run;*/
/**/
/*PROC PRINT DATA=dc(OBS=10);RUN;*/
