* Read in the data.  This data needed to be converted to .xlsx due to bad formatting;
proc import datafile= "/home/lavos840/Bombing_Weather_Data.csv"
dbms = csv replace
out = test(drop= StationIDs VAR1);
getnames= yes;
run;
proc import datafile= "/home/lavos840/Pre_Bombing_Weather_Data.csv"
dbms = csv replace
out = train(drop= StationIDs VAR1);
getnames= yes;
run;

data test2;
set test;
logPrecipHeight = log(PrecipHeight);
logSnowDepth = log(SnowDepth);
run;
data train2;
set train;
logPrecipHeight = log(PrecipHeight);
logSnowDepth = log(SnowDepth);
run;
* glm using all parameters;
proc glm data= train2 plots= all;
model MeanCloudCover = MinTemp MaxTemp MeanTemp MinAirTemp SunDuration
 MeanCloudVapor MeanRelHumid logPrecipHeight MeanPressure logSnowDepth / solution clparm;
run;

* Stepwise feature selection;
proc glmselect data= train2 testdata=test2 plots= all;
model MeanCloudCover = MinTemp MaxTemp MeanTemp MinAirTemp SunDuration MeanCloudVapor 
	MeanRelHumid logPrecipHeight MeanPressure 
logSnowDepth / selection=stepwise(choose= CV stop= CV) CVdetails;
run;

* Probit regression;
proc format;
value successful 1 = 'accept' 0 = 'reject';
run;
proc probit data= test2;
class success;
model success= MinTemp MaxTemp MeanTemp MinAirTemp SunDuration MeanCloudCover MeanCloudVapor 
	MeanRelHumid logPrecipHeight PrecipForm MeanPressure logSnowDepth / d= normal itprint;
format success successful.;
run;

* Probit regression with parameters that are all significant;
proc probit data= test2 plots=(predpplot(level=("Success" "Failure"))
                   cdfplot(level=("Success" "Failure")));
class success;
model success= MeanCloudCover SunDuration MeanCloudVapor 
	MeanRelHumid PrecipForm / d= normal lackfit itprint;
format success successful.;
output out= results xbeta= Estimate std=StdDev prob=Probability;
run;

proc format;
value successful 1 = 'Success' 0 = 'Failure';
run;
data results2;
set results(keep= Success Month Day Year Country DefCity DefCountry Latitude Longitude Probability Estimate StdDev);
Prediction = "Success";
if probability < 0.5 then do Prediction = "Failure"; end;
format success successful.;
run;
proc print data=results2; run;