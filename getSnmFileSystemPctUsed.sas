
%let outfile=%sysfunc(pathname(work))/out.txt;

/* $ per cercare stringa alla fine della riga. cerco il nome del mount, altrimenti ce ne sono altre */
x "df -k | grep -w '/snm$' | awk '{print $5}'> &outfile";

%put &sysrc &sysmsg;

data _null_;
infile "&outfile." length=ll;
file _webout;

length recordPct $40;
input recordPct $varying.ll;
pct=input(   translate(recordPct,'','%') ,best.);

put '{ "snm_pctUsed": ' pct '}';

run;
