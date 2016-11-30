%macro fileread(dout=,flist=);
proc import datafile=&flist out=_filelist dbms=tab replace;
getnames=yes;
run;

proc sql noprint;
select count(*) into:total
from _filelist
;quit;

%do j=1 %to &total;
data _null_;
 set _filelist;
 if _n_=&j;
 call symput ('filein',path);
run;

proc import out=_shvol datafile="&filein" dbms=tab replace;
delimiter='|';
getnames=yes;
run;

proc sql;
create table _daily_shvol as
select date, sum(size) as shvol, count(*) as num_of_short_order
from _shvol
group by date
;quit;

proc append base=_alldata data=_daily_shvol;
run;
%end;
data &dout;
set _alldata;
run;
%mend fileread;


%fileread(dout=a,flist="C:\Users\yu_heng\Downloads\file_list.txt");


* remove duplicates and sort by date;
proc sort data=a out=b nodup;
by date shvol;
run;

* reformat the date variable;
DATA c(rename=(date2=date));
  SET b;
  DATE2 = INPUT(PUT(date,8.),YYMMDD8.);
  FORMAT DATE2 date9.;
  avg_short_size=shvol/num_of_short_order;
  DROP date;
  RUN;
* save it to local drive;
data my.shvol2015;
set c;
run;
PROC PRINT DATA=c(OBS=25);RUN;
