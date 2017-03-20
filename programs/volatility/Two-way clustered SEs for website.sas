/*July ,2015*/
/*This sas macro code is modified by Mark (Shuai) Ma based on the two-way clustered SE code from Professor John McInnis *******/

/*According to Petersen (2008) and Thompson (2011), there are three steps to estimate two-way clustered SEs: */
/*1. estimate firm-clustered VARIANCE-COVARIANCE matrix V firm,*/
/*2. estimate time-clustered VARIANCE-COVARIANCE matrix V time,*/
/*3. estimate heteroskedasticity robust white VARIANCE-COVARIANCE matrix (V white) when there is only one observations each firm-time intersection,*/
/*or, estimate firm-time intersection clustered VARIANCE-COVARIANCE matrix (V firm-time) when there is more than one observations each firm-time intersection,*/
/*This code allows the user to closely follows the formula given by Petersen (2008) and Thompson (2011).*/

/********************************************************************************************************************************/
/*If you use this code, please add a footnote:*/
/*To obtain unbiased estimates in finite samples,the clustered standard error is adjusted by (N-1)/(N-P)× G/(G-1),where N is the sample size, P is the number of independent variables, and G is the number of clusters. */
/*For details, please see my note on two-way clustered standard errors avaiable on SSRN and my website https://sites.google.com/site/markshuaima/home.*/


/*Lastly, I post this code for the communication purpose without any warranty or guaranty of accuracy or support.*/
/*I tried my best to ensure the accuracy of the codes, but I could not exclude the possibility that there might still be errors. If any error is found, please get me know immediately.*/


/********************************************************************************************************************************/
/*Input explanations */

/* After running the macro code below, you will need to run the following command,
you only need to change the names of datasets and variables and "multi" value in the following command, and results will be in dataset "A.results"*/

/*****************command*******************************************************************************************************/
/*%REG2DSE(y=DV, x=INDV, firm=firmid, time=timeid, multi=0, dataset=A.data, output=A.results);*/


/**************Variable Explanation*********************************************************************************************/
/* 1. A.data: A is your library name, data is your input dataset name,*/
/*A.results : A is your library name, results is the name you want for your output dataset ,*/

/*2. DV: the dependent variable, */
/*INDV: the list of your independent variable(s),*/

/*3.  firmid: the firm identifier (such as gvkey, permno) ,*/
/*timeid: the time identifier (such as fyear, date),*/

/*4. multi=0 or 1 (you need to choose whether you use 0 or 1  )  */
/* if you have one observation per firm-time (intersection of two dimendions), you need to have multi=0*/
/* if you have multiple observations per firm-time (intersection of two dimendions) , you need to have multi=1*/

/********************************************************************************************************************************/
/************************The macro code is as follows*************************************/


%MACRO REG2DSE(y, x, firm_var, time_var, multi, dataset, output);

*covb = Covariance of estimated regression coefficients;

proc surveyreg data=&dataset;
cluster &firm_var;
model &Y = &X /covb ;
ods output covb=firm_clustered_covariance;
ods output FitStatistics=fit;
run;quit;

proc surveyreg data=&dataset;
cluster &time_var;
model &Y = &X /covb ;
ods output covb=time_clustered_covariance;
run;quit;

%if &multi=1  %then %do;

proc surveyreg data=&dataset;
cluster &time_var &firm_var;
model &y = &x /  covb;
ods output covb=both ;
ods output parameterestimates=param;
run;quit;

data param; set param;keep parameter estimate;run;

%end;


%else %if &multi=0  %then %do;

proc reg data=&dataset;
model &y = &x /hcc  acov  covb;
ods output acovest=both ;
ods output parameterestimates=param;
run;quit;

data both; set both; parameter=Variable; run;

data both; set both;drop variable  Dependent  Model;run;

data param; set param;parameter=Variable;Estimates=Estimate;keep parameter estimates;run;

%end;

data param1; set param;
n=_n_;m=1;keep m n;run;

data param1;set param1;
by m;if last.m;keep n;run;
 
data both; set both;
keep intercept &x;
run;
data firm_clustered_covariance; set firm_clustered_covariance;
keep intercept &x;
run;
data time_clustered_covariance; set time_clustered_covariance;
keep intercept &x;
run;

data fit1; set fit;
parameter=Label1;
Estimates=nValue1;
if parameter="R-square" then output;
run;

data fit1; set fit1;
n=1;
keep parameter Estimates n;
run;

* calculate the two-way clustered error;
proc iml;
use both;
read all var _num_ into hcc_error;print hcc_error;
use firm_clustered_covariance;
read all var _num_ into firm_clus_cov;print firm_clus_cov;
use time_clustered_covariance;
read all var _num_ into tm_clus_cov;print tm_clus_cov;
use param1;
read all var _num_ into n;print n;
two_way_clustered_error=firm_clus_cov+tm_clus_cov-hcc_error;
idenM=I(n); * identity matrix;
constM=J(n,1); * constant matrix;
E=idenM#two_way_clustered_error;* multiplication, element-wise. Take only the diagonal elements. ;
F=E*constM; * matrix multiplication. Convert the diagonal elements to a vector;
stderr=F##.5; * power, element-wise. Square root the elements in the vector.;
print two_way_clustered_error;
print stderr;
create b from stderr [colname='stderr'];
append from stderr;
quit;

data results; merge  param two_way_clustered_error ;
tstat=estimates/stderr;n=0;run;

data resultsfit; merge results fit1;by n;
run;

data &output; set resultsfit;
drop n;
run;

PROC PRINT DATA=&output(OBS=10);RUN;

%MEND REG2DSE;



/*****************************************************************/
/*   OLS with two-way cluster-robust SEs, t-stats, and p-values  */
/*****************************************************************/

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

