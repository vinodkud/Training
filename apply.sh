#!/bin/ksh

iam="false"


fn_is_iam_env(){
  #decide if keycloak deployment is required
  if [[ $(./is-keycloak.sh $ver $env $dev) != "keycloak" ]] ; then
    iam="true"
  fi
}


fn_deploy_env(){
  echo "creating env...${env}"
  echo "The code version is ${numrel}"

  fn_is_iam_env

  echo
  echo "**************************************************************************"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "*                         Creating Config Maps                           *"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "**************************************************************************"
  echo

  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-jvm-options.yaml
  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-bootstrap.yaml
  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-logging.yaml
  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-ssl.yaml
  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-registry.yaml

  # Vault config
  for yamlfile in `find ${generatedpath}/ -type f -iname "v1_configmap_vault-agent-config*.yaml"`
  do
    kubectl apply -n ${env} --context=${context} --record -f ${yamlfile}
  done

  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_ova-config-jvm-options.yaml
  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_ova-config-bootstrap.yaml
  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_ova-config-logging.yaml
  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_ova-config-ssl.yaml

  echo
  echo "**************************************************************************"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "*                      Creating XCT Services                             *"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "**************************************************************************"
  echo

  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_service_xct.yaml
  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_service_ova.yaml

  echo
  echo "**************************************************************************"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "*                    Applying OVA deployment yaml                        *"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "**************************************************************************"
  echo

  kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_ova.yaml
  
  echo
  echo "**************************************************************************"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "*                    Applying keycloak user auth                         *"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "**************************************************************************"
  echo
  
  #only deploy keycloak if actually required
  if [[ ${iam} == "false" ]] ; then
      echo "generating code for a keycloak build"
      kubectl create -n ${env} --context=${context} configmap keycloak-config-ssl --from-file ${keycloaksslcommonpath}/standalone-ha.xml
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_service_keycloak.yaml
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_ova-keycloak.yaml
  fi
 
  echo
  echo "**************************************************************************"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "*                    Applying FFDC Browser yaml                          *"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "**************************************************************************"
  echo

  if [[ -e ${generatedpath}/apps_v1_deployment_nginx.yaml ]] ; then
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_service_nginx-svc.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_nginx-config.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_nginx.yaml
  fi

  echo
  echo "**************************************************************************"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "*                    Applying XCT Deployment yaml                        *"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "**************************************************************************"
  echo

  #if this is not a multi qm deployment then deploy non qm version
  if ! [ -e ${generatedpath}/apps_v1_deployment_xct-qm1.yaml ] ; then
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-ccdt-config.yaml  
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_xct.yaml
  else
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-bootstrap-overlay-qm1.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-ccdt-config-qm1.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_xct-qm1.yaml

    if [[ -e ${generatedpath}/apps_v1_deployment_xct-qm2.yaml ]] ; then
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-bootstrap-overlay-qm2.yaml
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-ccdt-config-qm2.yaml
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_xct-qm2.yaml
    fi

    if [[ -e ${generatedpath}/apps_v1_deployment_xct-qm3.yaml ]] ; then
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-bootstrap-overlay-qm3.yaml
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-ccdt-config-qm3.yaml
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_xct-qm3.yaml
    fi

    if [[ -e ${generatedpath}/apps_v1_deployment_xct-qm4.yaml ]] ; then
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-config-bootstrap-overlay-qm4.yaml
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_xct-ccdt-config-qm4.yaml
      kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_xct-qm4.yaml
    fi
  fi

  echo
  echo "**************************************************************************"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "*                    Applying XCT Cronjobs yaml                          *"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "**************************************************************************"
  echo

  if [[ -e ${generatedpath}/batch_v1_cronjob_xct-txn-dewarehousing.yaml && ( ${env} == "xct-nft" || ${env} == "xct-nft2" || ${env} == "xct-sit" || ${env} == "xct-sit2" || ${env} == "xct-sit3" || ${env} == "xct-prod" )]]
  then
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-txn-dewarehousing.yaml
  # kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-instr-dewarehousing.yaml
  fi
  

  if [[ -e ${generatedpath}/batch_v1_cronjob_xct-nwg-nwb-outgoing-initiation.yaml && ( ${env} == "xct-nft" || ${env} == "xct-nft2" || ${env} == "xct-sit" || ${env} == "xct-sit2" || ${env} == "xct-sit3" || ${env} == "xct-prod" )]]
  then
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-nwg-nwb-outgoing-initiation.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-nwg-rbos-outgoing-initiation.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-nwg-ubn-outgoing-initiation.yaml
  fi

  if [[ -e ${generatedpath}/batch_v1_cronjob_xct-nwg-account-posting.yaml && ( ${env} == "xct-nft" || ${env} == "xct-nft2" || ${env} == "xct-st" || ${env} == "xct-sit" || ${env} == "xct-sit2" ) ]]
  then
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-nwg-account-posting.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-rbs-account-posting.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-ubn-account-posting.yaml
  fi

  if [[ -e ${generatedpath}/batch_v1_cronjob_xct-gpitracker.yaml && ( ${env} == "xct-sit" || ${env} == "xct-nft" || ${env} == "xct-nft2" || ${env} == "xct-prod" )]] ; then
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-gpitracker.yaml
  fi

  if [[ -e ${generatedpath}/batch_v1_cronjob_xct-cleanup.yaml && ( ${env} == "xct-nft" || ${env} == "xct-nft2" || ${env} == "xct-prod")]] ; then
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/batch_v1_cronjob_xct-cleanup.yaml
  fi


  echo
  echo "**************************************************************************"
  echo "*                                                                        *"
  echo "*                                                                        *"
  echo "*                    Restarting Promethus and Grafana                    *"
  echo "*        because they use vault so everytime vault CM is generated       *"
  echo "*                  we need to deploy prometheus and Grafana              *"
  echo "**************************************************************************"
  echo

  if [[ ${env} == "xct-nft" || ${env} == "xct-nft2" || ${env} == "xct-prod" ]] ; then
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_grafana-datasources.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_configmap_grafana-ldap.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_service_grafana.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/v1_service_prometheus.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_prometheus.yaml
    kubectl apply -n ${env} --context=${context} --record -f ${generatedpath}/apps_v1_deployment_grafana.yaml
  fi

  
  #For XCT to PRS connectivity.Putting baseQueueManagerName as empty for alias queue pointing to cluster queue
  #kubectl create -n ${env} --context=${context} configmap mq-config-qmgr --from-file ${envcommonpath}/mq/queues_white.xml

  #no point calling this as xct pods take 15 + minutes to startup !!!
  # ./is-available.sh ${context} "xct" "pod"
  #if [ $? -ne 0 ]; then
  #   echo "issue checking xct pod"
  #   exit 1
  #fi
}

echo "xct deploy starting $0 $(date)" 

if [[ $fulldelete == true ]]
then
  ./env-delete.sh
fi

fn_deploy_env

exit 0
