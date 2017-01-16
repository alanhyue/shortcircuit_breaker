/*Calculate the semivariance. 
The approach refers to the Diether et al. (2009) "It's SHO time" paper. P31.
*/

* Step1: prepare the log variance;
data a;
set my.Permnodata;
ret=log(prc/lag(prc));
run;

* Step2: separte upwards and downwards variances;
data semi;
set a;
if ret<0 then up=0;
else up=ret*ret;
if ret>0 then down=0;
else down=ret*ret;
run;

* Step3: calculate upward semivariance from reg;
* cross-sectional average of the up- and down-side semivariance;
%Winsorize(din=semi,dout=winsoup,var=up);

proc sql;
create table up_crosec as
select date, AVG(up) as avgup
from winsoup
group by date
;quit;
%AppendSSCBDummy(din=up_crosec,dout=up_withdummy);

PROC PRINT DATA=up_withdummy(OBS=10);RUN;

proc reg data=up_withdummy;
model avgup=dsscb;
run;
* Step3: calculate downward semivariance from reg;
%Winsorize(din=semi,dout=winsodown,var=down);

proc sql;
create table down_crosec as
select date, AVG(down) as avgdown
from winsodown
group by date
;quit;
%AppendSSCBDummy(din=down_crosec,dout=down_withdummy);

PROC PRINT DATA=down_withdummy(OBS=10);RUN;

proc reg data=down_withdummy;
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
