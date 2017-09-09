%macro winsorize(din=,dout=,vars=,pct=1 99);
%WT(data=&din,out=&dout,byvar=none, vars=&vars, type=W, pctl=&pct, drop= N);
%mend winsorize;
%macro WT(data=_last_, out=, byvar=none, vars=, type = W, pctl = 1 99, drop= N);

	%if &out = %then %let out = &data;
    
	%let varLow=;
	%let varHigh=;
	%let xn=1;

	%do %until (%scan(&vars,&xn)= );
    	%let token = %scan(&vars,&xn);
    	%let varLow = &varLow &token.Low;
    	%let varHigh = &varHigh &token.High;
    	%let xn = %EVAL(&xn + 1);
	%end;

	%let xn = %eval(&xn-1);

	data xtemp;
   	 	set &data;

	%let dropvar = ;
	%if &byvar = none %then %do;
		data xtemp;
        	set xtemp;
        	xbyvar = 1;

    	%let byvar = xbyvar;
    	%let dropvar = xbyvar;
	%end;

	proc sort data = xtemp;
   		by &byvar;

	/*compute percentage cutoff values*/
	proc univariate data = xtemp noprint;
    	by &byvar;
    	var &vars;
    	output out = xtemp_pctl PCTLPTS = &pctl PCTLPRE = &vars PCTLNAME = Low High;

	data &out;
    	merge xtemp xtemp_pctl; /*merge percentage cutoff values into main dataset*/
    	by &byvar;
    	array trimvars{&xn} &vars;
    	array trimvarl{&xn} &varLow;
    	array trimvarh{&xn} &varHigh;

    	do xi = 1 to dim(trimvars);
			/*winsorize variables*/
        	%if &type = W %then %do;
            	if trimvars{xi} ne . then do;
              		if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = trimvarl{xi};
              		if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = trimvarh{xi};
            	end;
        	%end;
			/*truncate variables*/
        	%else %do;
            	if trimvars{xi} ne . then do;
              		if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = .T;
              		if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = .T;
            	end;
        	%end;

			%if &drop = Y %then %do;
			   if trimvars{xi} = .T then delete;
			%end;

		end;
    	drop &varLow &varHigh &dropvar xi;

	/*delete temporary datasets created during macro execution*/
	proc datasets library=work nolist;
		delete xtemp xtemp_pctl; quit; run;

%mend;

%macro corrps(data=,vars=);

%let i=1;
%let j=1;
%do %until (%SCAN(&vars,&i,%STR( ))=);
    %let v&j=%SCAN(&vars,&i,%STR( ));
    %let j=%EVAL(&j+2);
	 %let i=%EVAL(&i+1);
%end;

%let i=1;
%let j=2;
%do %until (%SCAN(&vars,&i,%STR( ))=);
    %let v&j=P%SCAN(&vars,&i,%STR( ));
    %let j=%EVAL(&j+2);
	 %let i=%EVAL(&i+1);
%end;

%let nvars=%eval(&i-1);

    %macro cor_rep(sta,fin);
    %do j=&sta %to &fin;
        , (xp.&&v&j + xs.&&v&j) as &&v&j
    %end;
    %mend;

ods output pearsoncorr=xp spearmancorr=xs;
proc corr data=&data pearson spearman;
    var &vars;
    run;


data xp;
    set xp;
    array vars {*} &vars;
    do i=1 to (_N_ - 1);
        vars(i) = 0;
    end;
	 array vars2 {*} P&vars;
    do j=1 to (_N_ - 1);
        vars2(j) = 0;
    end;
	 drop i j;
    run;

data xs;
    set xs;
    array vars {*} &vars;
    do i=_N_ to &nvars;
        vars(i) = 0;
    end;
	 array vars2 {*} P&vars;
    do j=_N_ to &nvars;
        vars2(j) = 0;
    end;
	 drop i j;
    run;

proc sql;
    create table xps as
    select xp.Variable as VARIABLE %cor_rep(1,&nvars*2)
    from xp, xs where (xp.Variable = xs.variable);
    quit;

proc print data=xps noobs;
    title2 'Pearson (above) / Spearman (below) Correlations';
    run;

title2;

proc datasets lib=work nolist;
   delete xp xs xps;
	run;
	quit;


%mend;
