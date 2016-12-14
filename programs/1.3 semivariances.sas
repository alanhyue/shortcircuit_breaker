/*Calculate the semivariance. 
The approach refers to the Diether et al. (2009) "It's SHO time" paper. P31.
*/

* Step1: prepare the log variance;
data a;
set my.Permnodata;
ret=log(prc/lag(prc));
if date<="10Nov2010"d then dsscb=0;
else dsscb=1;
run;

* Step2: separte upwards and downwards variances;
data semi;
set a;
if ret<0 then up=0;
else up=ret*ret;
if ret>0 then down=0;
else down=ret*ret;
run;

* Step3: calculate semivariance from reg;
* cross-sectional average of the up- and down-side semivariance;
proc sql;
create table semi_crsec_avg as
select date, AVG(up) as avgup, AVG(down) as avgdown, dsscb
from semi
group by date
;quit;
proc sort data=semi_crsec_avg nodup;by date; run;
PROC PRINT DATA=semi_crsec_avg(OBS=10);RUN;
%Winsorize(din=semi_crsec_avg,dout=winsoupa,var=avgup);
proc reg data=winsoupa;
model avgup=dsscb;
run;
%Winsorize(din=semi_crsec_avg,dout=winsodown,var=avgup);
proc reg data=winsodown;
model avgdown=dsscb;
run;

* alternative approach: use PROC MEANS to calculate the semivariances;
proc means data=semi mean noprint;
by permno dsscb;
var up down;
output out=semiwant(drop=_:) mean=;
run;
PROC PRINT DATA=semiwant(OBS=10);RUN;

proc transpose data=semiwant name=Semi out=trans;
by permno;
var up down;
run;

data withsemi;
set trans(rename=(col1=pre col2=post));
diff=post-pre;
run;

PROC PRINT DATA=withsemi(OBS=10);RUN;

* save it to my local drive;
data my.semivariances;
set withsemi;
run;

PROC PRINT DATA=my.semivariances(OBS=10);RUN;
