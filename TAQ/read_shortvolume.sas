proc import out=shvol datafile="C:\Users\yu_heng\Downloads\NQBXsh20131101.txt" dbms=csv replace;
getnames=yes;
delimiter='|';
run;



PROC PRINT DATA=shvol(OBS=100);RUN;
