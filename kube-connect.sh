#!/bin/ksh


. ./config.sh

fn_kubernetes_login(){

#if [[ "${env}" =~ "prod" ]]
#then
    pks-creds > ./tmp.log <<EOF
    ${racfid}
    ${pswd}
    ${env}
    y
EOF
#else
#    pks-creds <<EOF
#    ${pswd}
#    ${env}
#    y
#EOF
#fi
status=`grep INVALID ./tmp.log`
rc=$?
if  [ $rc -eq 0 ]
then
   rm ./tmp.log
   exit 9
fi

rm ./tmp.log

kubectl config use-context ${context}

}

echo "Connect to Kubernetes with context ${context}" 
chmod 700 ~/.kube/config
chmod 700 ~/.kube

#if [[ "${env}" =~ "prod" ]]
#then
    echo; echo -n "Enter RACF ID: "; read racfid
    echo -n "Enter RACF Password: "; stty -echo; read pswd; stty echo; echo
#else
#    echo; echo -n "Enter RACF Password: "; stty -echo; read pswd; stty echo; echo
#fi


fn_kubernetes_login

exit 0
