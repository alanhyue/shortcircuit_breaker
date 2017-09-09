PROC PRINT DATA=nysetime(OBS=10);RUN;
* the anatomy of datetime;
data nysetime;
set nyseraw(rename=(trigger_date=date trigger_time=time));
year=year(date);
month=month(date);
day=day(date);
hour=hour(time);
minute=minute(time);
second=second(time);
if "9:30"t<=time<="16:00"t;
keep year month day hour minute second date time;
run;

data nastime;
set nasraw;
date=datepart(Trigger_Time);
format date date9.;
time=timepart(Trigger_time);
format time time9.;
year=year(date);
month=month(date);
day=day(date);
hour=hour(time);
minute=minute(time);
second=second(time);
if "9:30"t<=time<="16:00"t;
keep year month day hour minute second date time;
run;

* combine datetime from NYSE and Nasdaq together;
data datetime;
set nastime nysetime;
run;

* Get a feel of the table.;
%histo(din=datetime,var=date);
%histo(din=datetime,var=time);
%freq(din=datetime,var=year);
%freq(din=datetime,var=month);
%freq(din=datetime,var=day);
%freq(din=datetime,var=hour);
%histo(din=datetime,var=minute);
%freq(din=datetime,var=second);


proc freq data=datetime;
   tables month day/ plots=freqplot;
run;

PROC PRINT DATA=datetime(OBS=10);RUN;
