* Refer to our database pool;
libname my 'C:\Users\yu_heng\Downloads\';

* Optional: print the head of a data base to visually check the data.;
PROC PRINT DATA=my.Mo07_13(OBS=10);RUN;

* Filter the security list for those that exists persistently 
through the given time period.

Here we require the security to stay alive from Jan. 2007 through
Dec. 2013, which is 7 years. I assume this means CRSP monthly 
return datashould have for 7*12=84 observations for it.

The securities that satistfies our requirements are collected into 
table [alive_secus].
;
proc sql;
create table my.alive_secus as
select permno, count(*) as N
from my.Mo07_13
group by permno
having count(*)=84
;quit;

