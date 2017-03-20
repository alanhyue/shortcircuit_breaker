PROC PRINT DATA=dsf(OBS=10);RUN;

%histo(din=dsf,var=DSSCB);
%clus2OLS(yvar=ret, xvars=p_var, cluster1=permco, cluster2=date, dset=dsf);
%REG2DSE(y=p_var, x=DSSCB LGDCL_DUM SCB_LGDCL, firm_var=permno, time_var=date, multi=0, dataset=dsf, output=aaa);
PROC PRINT DATA=aaa(OBS=10);RUN;
proc anova data=dsf;run;
proc reg data=dsf;
model P_var=DSSCB LGDCL_DUM /vif;
run;
proc surveyreg data=dsf;
/*cluster permno;*/
model P_var = DSSCB LGDCL_DUM SCB_LGDCL /anova df=502;
run;
quit;

proc means data=dsf;
var DSSCB LGDCL_DUM SCB_LGDCL;
run;
proc genmod data=dsf;
class permno;
model P_var = DSSCB LGDCL_DUM SCB_LGDCL;
repeated subject=permno / type=ind;
run;

%winsorize(din=dsf,dout=aaa,var=p_var);
PROC PRINT DATA=aaa(firstobs=5000 OBS=5300);RUN;
* mean number of obs. per class;
proc sql;
select AVG(N) as m
from (
	select count(*) as N
	from dsf
	group by permno
	)
;quit;
