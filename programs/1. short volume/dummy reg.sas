* add a dummpy;
data withdummy;
set shvol2014;
if date<="10May2010"d then dsscb=0;
else dsscb=1;
run;

%let tb=withdummy ;
%let Y=shvol ;
%let X=dsscb ;

proc reg data=&tb;
model &Y=&X;
run;
