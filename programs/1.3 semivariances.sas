/*Calculate the semivariance. 
The approach refers to the Diether et al. (2009) "It's SHO time" paper. P31.
*/

* Step1: prepare the log variance;
data a;
set my.Permnodata;
ret=log(prc/lag(prc));
if date<="10May2010"d then dsscb=0;
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

* Step3: calculate the semivariances;
proc means data=semi mean noprint;
by permno dsscb;
var up down;
output out=semiwant(drop=_:) mean=;
run;

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
