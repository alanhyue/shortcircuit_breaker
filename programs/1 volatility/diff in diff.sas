/* 
Author: Heng Yue 
Create: 2017-01-19 15:38:58
Desc  : Prepare data for diff-in-diff regression.
*/
*=======;
***NOTES***;
*1. filter the SSCB observations by implementing the rule yourself. That is, if the daily low price is a 10 percent or more declination from last trading-day's closing price, it is would have triggered the breaker. Compare your result with the data obtained directly from Nasdaq. Using this method, you can even go back to the days before the breaker came effective and mark those stocks. Reasonably, 
when the breaker was introduced, these stocks that experiences violent intraday price declination are the ones that the breaker was intended for.

2. When comparing the difference in volatility, it makes more sense to compare the difference in intra-day downside volatility. The breaker should significantly reduce the intraday downside volatility. Using the techniques introduced in point 1, we separate the sample stocks into two groups: one has triggered the breaker and one has never. Then do a diff-in-diff test for intraday-downside volatility and other volatility measures as well. The expected result is that the intraday-downside volatility is significantly reduced but the general variance is not, which proves that the breaker is sharp at its target without strong "side-effects".

3. Fixed-effect, Fama macbeth, Newey-west, https://kelley.iu.edu/nstoffma/fe.html
;
* calculate intraday decline;
data da;
set my.permnodata;
if prc; * delete obs with missing price info;
if bidlo;
by permno;
decpct=-(bidlo-lag(prc))/lag(prc);* make decline percentage a positive number;
if first.permno then delete;
run;

%AppendSSCBDummy(din=da,dout=da);

* A.1 mark obs with 10%+ intraday decline;
data db;
set da;
/*if decpct>=0.10 then mark=1;*/
if decpct>=0.10 and dsscb=0 then mark=1; * mark period switch;
;run;

* A.2 count for each stock the number of declination 10%+;
proc sql;
create table dc as
select permno, count(mark) as nTrigger
from db
group by permno
;quit;

* B.1 if nTrigger >0, mark as TargetGroup=1;
data dd;
set dc;
if nTrigger>0 then TargetGroup=1;
else TargetGroup=0;
run;

%histo(din=dd,var=nTrigger);
* Ranking on nTrigger;
proc rank data=dc out=rankda group=10 ties=high;
var ntrigger;
ranks ntrigger_rank;
run;
data rankdb;
set rankda;
if ntrigger_rank=0 or ntrigger_rank=9;
if ntrigger_rank=0 then TargetGroup=0;
if ntrigger_rank=9 then TargetGroup=1;
run;
proc sql;
select ntrigger_rank,avg(nTrigger) as avgTrigger, count(*) as N
from rankda
group by ntrigger_rank
;quit;
PROC PRINT DATA=rankda(OBS=10);RUN;
***************;
* B.2 merge TargetGroup back to the DSF data;
proc sql;
create table df as
select a.*, b.TargetGroup, b.nTrigger
from da as a
/* rank switch */
inner join rankdb as b
/*left join dd as b*/
on a.permno=b.permno
;quit;

data dg;
set df;
SCBINTGROUP=TargetGroup*DSSCB;
parkinson=log(ASKHI/BIDLO);
run;
%winsorize(din=dg,dout=win,var=parkinson);
%histo(din=win,var=parkinson);

* date filter to shrink the sample size;
data win;
set win;
if '10May2010'd<=date<='10Jan2011'd;
run;
* run diff-in-diff reg using dummy variables.;
proc reg data=win;
model parkinson=DSSCB TargetGroup SCBINTGROUP;
run;

PROC PRINT DATA=win(OBS=10);RUN;
* fiexed-effect test;
proc glm data=win;
 class permno;
 model decpct = DSSCB TargetGroup SCBINTGROUP / solution; run;
quit;


%MACRO clus2OLS(yvar, xvars, cluster1, cluster2, dset);
	/* do interesection cluster*/
	proc surveyreg data=&dset; cluster &cluster1 &cluster2; model &yvar= &xvars /  covb; ods output CovB = CovI; quit;
	/* Do first cluster */
	proc surveyreg data=&dset; cluster &cluster1; model &yvar= &xvars /  covb; ods output CovB = Cov1; quit;
	/* Do second cluster */
	proc surveyreg data=&dset; cluster &cluster2; model &yvar= &xvars /  covb; ods output CovB = Cov2 ParameterEstimates = params;	quit;

	/*	Now get the covariances numbers created above. Calc coefs, SEs, t-stats, p-vals	using COV = COV1 + COV2 - COVI*/
	proc iml; reset noprint; use params;
		read all var{Parameter} into varnames;
		read all var _all_ into b;
		use Cov1; read all var _num_ into x1;
	 	use Cov2; read all var _num_ into x2;
	 	use CovI; read all var _num_ into x3;

		cov = x1 + x2 - x3;	/* Calculate covariance matrix */
		dfe = b[1,3]; stdb = sqrt(vecdiag(cov)); beta = b[,1]; t = beta/stdb; prob = 1-probf(t#t,1,dfe); /* Calc stats */

		print,"Parameter estimates",,varnames beta[format=8.4] stdb[format=8.4] t[format=8.4] prob[format=8.4];

		  conc =    beta || stdb || t || prob;
  		  cname = {"estimates" "stderror" "tstat" "pvalue"};
  		  create clus2dstats from conc [ colname=cname ];
          append from conc;

		  conc =   varnames;
  		  cname = {"varnames"};
  		  create names from conc [ colname=cname ];
          append from conc;
	quit;

	data clus2dstats; merge names clus2dstats; run;
%MEND clus2OLS;
%clus2OLS(yvar=decpct,xvars=DSSCB TargetGroup SCBINTGROUP,cluster1=permno,cluster2=date,dset=win);
* LEGACY;
*==============================;
* calculate the close-close volatility;
* because the RET is already calculated using closing prices, 
the close-close volatility is simply the square of RET;
data calc;
set my.permnodata;
* Close-to-close volatility;
ccvol=ret*ret; 
* semivariance;
lgret=log(prc/lag(prc));
if lgret<0 then up=0;
	else up=lgret*lgret;
if lgret>0 then down=0;
	else down=lgret*lgret;
* Parkinson volatility;
parkinson=log(ASKHI/BIDLO);
run;
