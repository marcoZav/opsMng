
%let workpath=%sysfunc(pathname(work));

x "cat /var/run/secrets/kubernetes.io/serviceaccount/namespace  > &workpath/result.txt";

%put "&sysrc" "&sysmsg"; 

data _null_;
infile "&workpath./result.txt" length=ll;
length record $32000;
input record $varying.ll;
put '***' record +(-1) "***";
run;
