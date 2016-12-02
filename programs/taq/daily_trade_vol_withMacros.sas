* Step1. Construct query table;
* This query is for testing purpose;
data query;
input date date9. symbol$;
format date date10.;
datalines;
09aug2010 MSFT
09aug2010 AAPL
24feb2011 MSFT
24feb2011 AAXJ
;
run;

* Step2. Append file paths to the query;
%GetFilePath(din=query,dout=withpath);

* Step3. filter unique date;
proc sort data=withpath(keep=date path_TIDX path_TBIN) nodupkey;
by date;
run;
*           For testing purpose;
data withpath;
set withpath(drop=path:);
if date="09aug2010"d then do;
	path_TIDX="c:\Users\yu_heng\Downloads\T201008F.IDX";
	path_TBIN="c:\Users\yu_heng\Downloads\T201008F.BIN";
end;
if date="24feb2011"d then do;
	path_TIDX="c:\Users\yu_heng\Downloads\T201102Q.IDX";
	path_TBIN="c:\Users\yu_heng\Downloads\T201102Q.BIN";
end;
run;
PROC PRINT DATA=withpath(OBS=10);RUN;

*Step4. Loop dates. Step5. Loop symbols.;
%LoopDates(query=query,path_table=withpath,dout=result);

*Step6. drop unnecessary columns.Save the table to local drive.;
data my.trade_vol;
set result;
run;

PROC PRINT DATA=result(OBS=10);RUN;
