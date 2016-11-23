/*Calculate the semivariance. 
The approach refers to the Diether et al. (2009) "It's SHO time" paper.
*/

* prepare the log variance;
data a;
set my.Permnodata;
ret=log(prc/lag(prc));
if date<="10May2010"d then dsscb=0;
else dsscb=1;
run;

* calculate the upwards and downwards semivariance;
data semi;
set a;
if ret<0 then up=0;
else up=ret*ret;
if ret>0 then down=0;
else down=ret*ret;
run;

* calculate the semivariances;
proc means data=semi mean noprint;
by permno dsscb;
var up down;
output out=semiwant mean= /autoname;
run;

PROC PRINT DATA=semiwant(OBS=10);RUN;

proc means data=semidown(keep=permno ret) mean noprint;
by permno;
output out=down mean=semidown;
run;

* merge the upwards and downwards semivariances together;
proc sql;
create table merged as
select a.permno, a.semiup, b.semidown
from up as a
left join down as b
on a.permno = b.permno
;quit;

* save it to my local drive;
data my.semivariances;
set merged;
run;

PROC PRINT DATA=my.semivariances(OBS=10);RUN;
