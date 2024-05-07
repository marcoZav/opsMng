

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

# Queries
# TUTTI i pods
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods --silent

# trick - you can add the -v 6 flag to any kubectl command, and the logs will become so verbose that you start seeing the issued HTTP requests to the Kubernetes API server


# (da fare come secondo giro)  
#PODNAME=sas-compute-server-c2bed06a-1964-4980-b4d6-5da0dd7c5baa-35377

# get pod per name 
#curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods/$PODNAME --silent

# delete pod per name -- forbidden
/* 1,message,,1,"pods ""sas-compute-server-c2bed06a-1964-4980-b4d6-5da0dd7c5baa-35377"" is forbidden: User ""system:serviceaccount:snmprod:sas-programming-environment"" cannot delete resource ""pods"" in API group """" in the namespace ""snmprod"""
1,reason,,1,Forbidden */
#curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X DELETE https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods/$PODNAME --silent


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


data compute_servers;
file _webout;
set ff.ITEMS_METADATA;
if index (name, 'compute-server');
put name ' - created: ' creationTimestamp;
call symput ('numPods', _n_);
run;
%put Numero pod attivi: &numPods;


libname ff clear;
filename ff clear;

