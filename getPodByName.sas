/*
 in
 
 parms

*/

%let workpath=%sysfunc(pathname(work));

%let shellFile=&workpath/xcmd.sh;

data code;
length codeRow $2000;
infile datalines length=ll;
file "&shellFile";
input codeRow $varying.ll;
put codeRow;
datalines;
# Point to the internal API server hostname
APISERVER=https://kubernetes.default.svc

# Path to ServiceAccount token
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# Read the ServiceAccount bearer token
TOKEN=$(cat ${SERVICEACCOUNT}/token)

# Reference the internal certificate authority (CA)
CACERT=${SERVICEACCOUNT}/ca.crt

# Explore the API with TOKEN
#curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api 


# (da fare come secondo giro)  
PODNAME=&parms

# get pod 
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods/$PODNAME --silent
;
run;


 
x "chmod ugo+x &shellFile";

x "&shellFile > &workpath/result.txt";

 %put "&sysrc" "&sysmsg"; 


data _null_;
call sleep(10,1);
run;


filename ff "&workpath/result.txt";
libname ff json;


data _null_;
file _webout;
set ff.alldata;
put value;
run;


libname ff clear;
filename ff clear;

