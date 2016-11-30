proc import out=shvol datafile="C:\Users\yu_heng\Downloads\Nasdaq_TRF_REGSHO_201307_2.txt" dbms=tab replace;
delimiter='|';
getnames=yes;
run;

/*PROC PRINT DATA=shvol(OBS=10);RUN;*/

proc sql;
create table daily_overall_shovol as
select date, sum(size) as shovol
from shvol
group by date
;quit;
PROC PRINT DATA=daily_overall_shovol(OBS=10);RUN;
