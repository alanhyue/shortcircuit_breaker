%MACRO Rank(din=,dout=,var=,n=10);
proc sort data=&din out=_temp;
by year symbol;
run;

proc rank data=_temp out=_temp2 group=&n ties=low;
/*by year;*/ * rank firm-year observation;
var &var;
ranks &var._rank;
run;

data &dout;
set _temp2;
run;
%MEND Rank;
%Rank(din=funda_halts,dout=a,var=prc);
PROC PRINT DATA=a(OBS=10);RUN;

%MACRO Winsorize(din=,dout=,var=,pct=1);
proc sort data=&din out=_temp;
by &var;
run;
proc sql noprint;
select count(*) into:nobs
from _temp
;quit;
%let chunk=%eval(&nobs*&pct/100);
%let begrec=%eval(0+&chunk);
%let endrec=%eval(&nobs-&chunk);
%put There are &nobs observations.;
%put Winsorizing the lowest and highest &pct percent.;
%put &pct percent corresponds to &chunk observations.;
data &dout;
set _temp(firstobs=&begrec obs=&endrec);
run;
proc delete data=_temp;run;
%MEND Winsorize;


%MACRO TestDecilePortfo(din=,dout=,var=);
%Winsorize(din=&din,dout=_tdptemp,var=&var);
%Rank(din=_tdptemp,dout=_tdptemp2,var=&var);
* cluster (year-firm)-rank;
proc sql;
create table _temp_decile_rank as 
select &var._rank, avg(&var) as avg_&var, sum(N) as total, count(*) as obs
from _tdptemp2
group by &var._rank
;quit;
proc tabulate data=_temp_decile_rank format=8.;
class &var._rank;
var total avg_&var;
table &var._rank ALL, 
(total * (sum colpctsum) avg_&var*mean*f=8.4)  / rts=10;
run;
%MEND TestDecilePortfo;
