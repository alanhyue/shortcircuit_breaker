* Checking the cusip matching result;
* replace LINKTABLE with the name of your linktable;
proc sql;
create table mylink as
select a.gvkey as hisgvkey, b.gvkey as mygvkey, a.*,b.*
from cleanlink as a
left join my.ccmxpf_linktable as b
on a.permno = b.lpermno and b.linkdt<=a.date<=b.linkenddt
;quit;

data correct;
set mylink;
if mygvkey;
if hisgvkey=mygvkey;
run;
data incorrect;
set mylink;
if mygvkey;
if hisgvkey ne mygvkey;
run;
proc sql noprint; 
select count(*)into:ncorrect
from correct
;quit;
proc sql noprint; 
select count(mygvkey)into:nmymatch
from mylink
;quit;
data bothdata;
set mylink;
if mygvkey and hisgvkey;
run;
proc sql noprint; 
select count(*)into:nhismatch
from bothdata
;quit;
proc sql noprint; 
select count(*)into:total
from mylink
;quit;
%put Hengs correct ratio: (&ncorrect/&nhismatch) %sysevalf(&ncorrect/&nhismatch);
%put Hengs match ratio: (&nhismatch/&total) %sysevalf(&nhismatch/&total);
%put My match ratio: (&nmymatch/&total) %sysevalf(&nmymatch/&total);


