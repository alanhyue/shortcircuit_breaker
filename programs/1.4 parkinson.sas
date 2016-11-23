* Calculate the Parkinson volatility measure;
* Methodology: the intraday volatility is calculated as 
the logarithm of the daily high price divided by the daily 
low price.
The pre (post) period intraday volatility is calculated as
the time-series average of the secrity in the pre (post) period.
;
data da;
set my.Permnodata;
parkinson=log(ASKHI/BIDLO);
if date<="10May2010"d then dsscb=0;
else dsscb=1;
run;

* Step1: calculate the pre and post period mean Parikinson volatility.;
proc means data=da mean noprint;
by permno dsscb;
var parkinson;
output out=outmean mean=/autoname;
run;

* Step2: Organize pre and post means period together;
proc transpose data=outmean out=trans(rename=(col1=pre col2=post));
by permno;
var parkinson_Mean;
run;

* Step3: Calculate the cross-sectional mean of the Parkinson volatility.;
proc means data=org mean;
var pre post;
output out=out_csmean mean=/autoname;
run;

* Step4: Calcualte the diff.;
data cs_org;
set out_csmean;
diff=post_mean-pre_mean;
run;

* save the result to local drive;
data my.parkinson;
set cs_org;
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
