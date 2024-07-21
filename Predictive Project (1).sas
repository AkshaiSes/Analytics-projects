/* loading in data */ 
DATA coffee;
	INFILE 'H:\coffee_groc_1114_1165' missover firstobs=2;
	INPUT IRI_KEY WEEK SY GE VEND ITEM UNITS DOLLARS F $ D PR;
RUN;

/*checking for missing values*/
proc means data=coffee nmiss;
run;
/* loading in data */
DATA delivery;
	INFILE 'H:\Delivery_Stores' missover firstobs=2;
	INPUT IRI_KEY OU $ EST_ACV  @20 Market_Name $25. Open Clsd MskdName $;
RUN;

/*checking for missing values*/
proc means data=delivery nmiss;
run;

/* loading in data */
PROC import datafile = 'H:\IRI week translation.csv'
	out = IRI
	dbms = csv
	replace;
run;
/*checking for missing values*/
proc means data=IRI nmiss;
run;
/* loading in data */
PROC import datafile = 'H:\prod_coffee.csv'
	out = prod
	dbms = csv
	replace;
run;
/*checking for missing values*/
proc means data=prod nmiss;
run;

/* changing tables (ie adding variables and combining) */

data c1;
set coffee; 
UPC = catx("-", put(SY, z2.), put(GE, z2.), put(VEND, z5.), put(ITEM, z5.));
run;
/*Unit price*/
data c1; set c1;
price = dollars/units ;
run;
/*Merging using UPC*/
proc sort data= c1 out=c1; by UPC; run;
proc sort data= prod out=prod; by UPC; run;

data cof_prod;
	merge 
	c1 prod;
	by UPC; 
run;
proc print data=cof_prod(obs=100);
run; 
/*Checking for missing values after merging*/
proc means data=cof_prod nmiss;
run;
/*Dropping missing rows*/
DATA cof_prod;
set cof_prod;
if cmiss(of _all_) gt 0 then
delete;
run;
proc means data=cof_prod nmiss;
run;

/*Merging cof_prod with delivery data*/
DATA p1; 
MERGE cof_prod (in=IRI_WEEK) delivery (in=IRI_KEY); 
run;

proc means data=p1 nmiss;
run;


data IRI ; set IRI;
	DROP VAR4 Calendar_date VAR6;
RUN;


proc print data=IRI(obs=10);
run; 

proc means data=IRI nmiss;
run;
data p1; set p1; 
size = VOL_EQ*16; 
run;

data p1; set p1;
priceoz = dollars/(units*size);
run;

data p1; set p1;
	if F= "NONE" then f0=1; else f0=0;
	if F= "A" then Fa=1; else Fa=0; 
	if F= "A+" then Faplus=1; else Faplus=0; 
	if F = "B" then Fb=1; else Fb=0;
	if F= "C" then Fc=1; else Fc=0; 
	if D = 0 then D0= 1; else D0=0;
	if D = 1 then D1=1; else D1=0;
	if D = 2 then D2=1; else D2 =0;
	if L2 = "GROUND COFFEE" then ground=1; else ground=0;
	if L2= "GROUND DECAFF" then decaf=1; else decaf=0;
	if L2= "WHOLE COFFEE" then whole=1; else whole=0;
	if form = "BEAN" then F1=1; else F1=0;
	if form = "EXTRA" then F2=1; else F2=0;
	if form = "FINE G" then F3= 1; else F3=0;
	if form = "FLAKE" then F4=1; else F4=0;
	if form = "GROUND" then F5=1; else F5=0;
	if form = "K CUP" then F6=1; else F6=0;
	if form = "MEDIUM" then F7=1; else F7=0;
	if form = "MISSIN" then formmissin=1; else formmissin=0;
	if form = "PACKET" then F8=1; else F8=0;
	if form = "POD" then F9=1; else F9=0;
	if form = "POWDER" then F10=1; else F10=0; 
	if form = "T DISC" then F11=1; else F11=0;
run;

data p2; set p1;
if L5= "MAXWELL HOUSE" then b1=1; else b1=0;
if L5= "PRIVATE LABEL" then b2=1; else b2=0;
if L5= "FOLGERS" then b3=1; else b3=0;
if L5=  "FOLGERS COFFEE" then b4=1; else b4=0;
if L5= "MILLSTONE" then b5=1; else b5=0;
if L5= "STARBUCKS" then b6=1; else b6=0;
if L5= "EIGHT O CLOCK" then b7=1; else b7=0;
if L5= "HILLS BROTHERS" then b8=1; else b8=0;
if L5= "DON FRANCISCO" then b9=1; else b9=0;
if L5= "CHOCK FULL O N" then b10=1; else b10=0;
if 0 = b1+b2+b3+b4+b5+b6+b7+b8+b9+b10 then b0=1; else b0=0;
run;

data p2; set p2;
ldollars = log(dollars);
run;

data p2; set p2; 
pricesq = priceoz*priceoz; 
run;

proc print data=p2 (obs=5);run;

/* descriptive data */

proc means data= p1; run;

proc freq data=p1;
	tables F D PR OU Market_Name MskdName L2 FORM PACKAGE; 
run;

proc freq data =p1; 
tables L1 L5; run;

proc means data =p2; 
var dollars units; run;

proc freq data= p2; 
tables L5*units; run;

proc sql; 
	select L5, sum(dollars) from p2
	group by L5; quit;

proc sql; 
	select Market_Name, sum(dollars) from p2
	group by Market_Name; quit;

proc sql; 
	select  MskdName , sum(dollars) from p2
	group by  MskdName ; quit;

/* trying mulitple logit model */

DATA p3; 
   SET p2;
   KEEP WEEK UPC price unit priceoz f0 Fa Faplus Fb Fc D0 D1 D2 ground decaf whole F1 F2 F3 F4 F5 F6 F7 formmissin F8 F9 F10 F11 ldollars pricesq b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b0 ;
RUN;

/* models */

proc reg data=p1; 
model 
DOLLARS= priceoz 
D1 D2 
decaf whole 
Fa Faplus Fb Fc pricesq
/ vif;
run;

proc reg data=p2; 
model 
DOLLARS= priceoz 
D1 D2 
decaf whole 
Fa Faplus Fb Fc pricesq
b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 
/ vif;
run;

PROC SYSLIN 2SLS SIMPLE;
ENDOGENOUS priceoz dollars;
INSTRUMENTS  D1 D2 decaf whole Fa Faplus Fb Fc ;
MODEL dollars = priceoz D1 D2 decaf whole Fa Faplus Fb Fc;
MODEL priceoz= dollars D1 D2 decaf whole Fa Faplus Fb Fc ;
RUN;

