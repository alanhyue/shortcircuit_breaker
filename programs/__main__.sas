libname my "C:\Users\yu_heng\Downloads\";
libname taqref 'E:\SCB\TAQ\data\sasdata';

%MACRO AppendSSCBDummy(din=,dout=);
data &dout;
set &din;
if date<="10Nov2010"d then dsscb=0;
else dsscb=1;
run;quit;
%MEND AppendSSCBDummy;


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


