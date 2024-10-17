/*

estrazione dei parametri di configurazione dei pods nel sistema.

es. 
limiti di cpu ram, variabili di environment ecc.

** lanciabile sia da sas studio sia come job execution, si adatta automaticamente:                         **
** se eseguita da job execution web application, scrive anche in webout il contenuto del dataset di output **

*/

/* 
  lista containers su cui limitare estrazione 

  elenco completo in https://sas.service-now.com/now/nav/ui/classic/params/target/kb_view.do%3Fsysparm_article%3DKB0039499

  qui prendo quelli che servono al back end

  rabbit: la KB parla di sas-rabbitmq, jaroslaw di sas-rabbitmq-server

  tralasciati per ora sas studio e parte analitica

  postgres dovrebbe essere così la mappatura (fatta da jaroslaw)
  pgbackrest = sas-crunchy-platform-postgres-repo-host
  opendistro = sas-opendistro-operator
  

*/
%let containersList=[
'sas-authorization','sas-files','sas-folders','sas-identities','sas-launcher','sas-compute','sas-search','sas-logon-app'
,'sas-rabbitmq','sas-rabbitmq-server',
,'sas-crunchy-platform-postgres-repo-host'
];


/* tabella di output con la response riga per riga */
%let outTable=work.response;

/* --------------------------------------------------------------------------- */

%let workpath=%sysfunc(pathname(work));

%let shellFile=&workpath/xcmd.sh;

%let commandOutfile=&workpath/result.txt;

/*
%let commandOutfile=/snm/projects/perf/jobs/kubeget.json;
*/

%let outFile=&workpath/response.csv;

data code;
length codeRow $2000;
infile datalines length=ll;
file "&shellFile";
input codeRow $varying.ll;
put codeRow;
datalines;
APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT=${SERVICEACCOUNT}/ca.crt
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods --silent
;
run;
 
x "chmod ugo+x &shellFile";
x "&shellFile > &commandOutfile";

%put "&sysrc" "&sysmsg"; 

data _null_;
call sleep(6,1);
run;

/*
filename kube "&commandOutfile";
libname kube json;
*/

proc python restart;
submit;

commandOutfile=SAS.symget('commandOutfile')
containersList=SAS.symget('containersList')

outFile=SAS.symget('outFile')
outTable=SAS.symget('outTable')
jobExecutionMode=SAS.symget('jobExecutionMode')
#=SAS.symget('')



# gestione response in file/tabella
import csv
import os
import pandas as pd
fcsvOut=open(outFile, 'w', newline='') 
writer = csv.writer(fcsvOut, delimiter=',')
headRow = ['respText']
writer.writerow(headRow)
fcsvOut.close()

# gestione response in file/tabella
def fPrint(rowContent):
    newRow=[rowContent]
    #print(rowContent)
    fcsvOut=open(outFile, 'a', newline='')
    writer = csv.writer(fcsvOut, delimiter=',')
    writer.writerow(newRow)
    fcsvOut.close()



contList=containersList

import json

# Open and read the JSON file
with open(commandOutfile, 'r') as file:
    kube = json.load(file)
items=kube['items']
i=1
for item in items:
    containers=item['spec']['containers']
    for container in containers:
        name=container['name']
        if name in contList:
            print ('\n','>>> '+name)
            fPrint ('-------------------------------------------------')
            fPrint ('>>> '+name)
            i=i+1
            if 'env' in container:
                env=container['env']
                for envVar in env:
                    print (envVar)
                    fPrint(envVar)
            if 'resources' in container:
                resources=container['resources']
                if 'limits' in resources:
                    limits=resources['limits']
                    print ('> limits: ', limits)   
                    fPrint ('> limits: ' + str(limits))           
                if 'requests' in resources:
                    requests=resources['requests']
                    print ('> requests: ',requests)   
                    fPrint ('> requests: ' + str(requests))
            # volendo ci sono qui anche i volumeMounts

# gestione response in file/tabella
df=pd.read_csv(outFile)  
#print(df)
SAS.df2sd(df, outTable)


endsubmit;
quit;


/* solo se chiamata come job execution */
%macro mng_webout;
 /* <0 significa che esiste filename ma non file fisico. 0 esiste sia fileref sia file fisico. positivo non è assegnata la fileref */
 %if %sysfunc(fileref(_webout))<=0 %then %do;   
     data _null_;
      file _webout;
      set &outTable;
      put respText;
     run;
 %end;
%mend;
%mng_webout;

