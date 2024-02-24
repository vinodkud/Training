#!/bin/ksh

# to run build 
# example - ./xct-build.sh -c dev01 -n xct-st -d -k


export env=""
export fulldelete="false"
export yaml="false"
export cluster=""
export rundate=`date '+%d-%m-%C%y at %H:%M:%S'`
export authTypeRequired="IAM"
export iamOrKeycloak=""


print_usage() {
  printf '\nUsage: %s: [-c] cluster [-n] env [-d] do full delete [-y] generate yaml files only [-k] keycloak authorization type is required \n' $0
}

while getopts 'c:n:dyk' flag; do
  case "${flag}" in
    c)
      cluster="${OPTARG}" ;;
    n)
      env="${OPTARG}" ;;
    d)
      fulldelete='true' ;;
    y)
      yaml='true' ;;
    k)
     authTypeRequired='keycloak' ;;
    *)
      print_usage
      exit 1 ;;
  esac
done

if [[ $env == "" || $cluster == "" ]]
then
  print_usage
  exit 1
fi

echo "cluster: ${cluster} env: ${env} and fulldelete = ${fulldelete} yamlonly = ${yaml}"

echo "Authorization required : " ${authTypeRequired}

# get all config and establish context
. ./config.sh

iamOrKeycloak=$(./is-keycloak.sh $ver $env $dev)
echo " Existing iamOrKeycloak Value found in values file : "  ${iamOrKeycloak}

if [[ ${authTypeRequired} == "IAM" && ${supportsIAM} == "false" ]]
then
   echo "IAM config on ENV: ${env} not supported." 
   exit 1
fi

#*********** Swaing values files IAM/Keycloak-Start*k******
# if authtyperequired and the value files available in the value folder are same then no need to do the files swap.
if [ ${authTypeRequired} !=  ${iamOrKeycloak} ]
   then
      #swaping value file from IAM to Keycloak as the authtyperequired is keycloak
      if [[  ${authTypeRequired} = "keycloak"  && ${iamOrKeycloak} = "IAM" ]]
      then
         #  will be used
         mv ${valuespath}/ova-nwg-values.yaml ${valuespath}/ova-nwg-values.yaml-IAM
         mv ${valuespath}/ova-nwg-values.yaml-keycloak ${valuespath}/ova-nwg-values.yaml
         mv ${valuespath}/xct-nwg-values.yaml ${valuespath}/xct-nwg-values.yaml-IAM
         mv ${valuespath}/xct-nwg-values.yaml-keycloak ${valuespath}/xct-nwg-values.yaml
	 echo 'changed to keycloak'
      fi

      #swaping value file from Keycloak to IAM as the authtyperequired is IAM
      if [[  ${authTypeRequired} = "IAM"  && ${iamOrKeycloak} = "keycloak" ]]
      then
         # ${valuespath} will be used
         mv ${valuespath}/ova-nwg-values.yaml ${valuespath}/ova-nwg-values.yaml-keycloak
         mv ${valuespath}/ova-nwg-values.yaml-IAM ${valuespath}/ova-nwg-values.yaml
         mv ${valuespath}/xct-nwg-values.yaml ${valuespath}/xct-nwg-values.yaml-keycloak
         mv ${valuespath}/xct-nwg-values.yaml-IAM ${valuespath}/xct-nwg-values.yaml
         echo 'changed to IAM'
      fi
fi
#*********** Swaing values files IAM/Keycloak-end*******

echo "Generating BASE yaml files for build"
./generate-base.sh 

echo "**************************"
echo "kustomize stage 1 starting"
echo "**************************"

if [[ $env == "xct-prod" ]]
then
   echo "base kustomise for prod build using kustomization_prod_env.yaml"
   rm ${kustomizebasepath}/kustomization.yaml 
   cat ${kustomizebasepath}/kustomization_prod_env.yaml >> ${kustomizebasepath}/kustomization.yaml
else 
   echo "base kustomise for dev/test build using kustomization_lower_env.yaml"
   rm ${kustomizebasepath}/kustomization.yaml
   cat ${kustomizebasepath}/kustomization_lower_env.yaml >> ${kustomizebasepath}/kustomization.yaml
fi


if [[ $env == "xct-prod" ]]
then
   echo "using prod vault-cacert.pem"
   cp ${buildpath}/buildfiles/prod/vault-cacert.pem ${kustomizeoverlayspath}/${env}/${context}/conf-files/vault-cacert.pem
else
   echo "using test vault-caert.pem"
   cp ${buildpath}/buildfiles/test/vault-cacert.pem ${kustomizeoverlayspath}/${env}/${context}/conf-files/vault-cacert.pem
fi


echo "Doing first kustomize build to generate base files"
if [[ $env != "xct-st"  ]] then
   echo "replacing overlay kustomization.yaml with kustomization_base.yaml"
   cat ${kustomizeoverlayspath}/${env}/${context}/kustomization_base.yaml > ${kustomizeoverlayspath}/${env}/${context}/kustomization.yaml
fi

kustomize build ${kustomizeoverlayspath}/${env}/${context}/ --output ${generatedpath}/
echo "Adjusting cronjobs schedules based on the current timezone"
for file in "${generatedpath}"/*cronjob*
 do
   filename=$(basename "$file")  
   echo "$filename schedule adjusted"
   clock_change/adjust_cronjob_schedule.sh "$file";
done

if [[ $env != "xct-st" ]] then
   echo "Generating qm specific xct deployment yamls. 2 for SIT's 4 for NFT's and Prod into the kustomize folder for second kustomize operation"
   
   echo "**************************"
   echo "kustomize stage 2 starting"
   echo "**************************"

   #Duplicate the xct deployment files for overlay customization
   sed -z "s/name:\s*xct/&-qm1/" ${generatedpath}/apps_v1_deployment_xct.yaml > ${kustomizeoverlayspath}/${env}/${context}/apps_v1_deployment_xct-qm1.yaml
   sed -z "s/name:\s*xct/&-qm2/" ${generatedpath}/apps_v1_deployment_xct.yaml > ${kustomizeoverlayspath}/${env}/${context}/apps_v1_deployment_xct-qm2.yaml

   if ([ ${env} == "xct-nft" ] || [ ${env} == "xct-nft2" ] || [ ${env} == "xct-prod" ])
   then
      sed -z "s/name:\s*xct/&-qm3/" ${generatedpath}/apps_v1_deployment_xct.yaml > ${kustomizeoverlayspath}/${env}/${context}/apps_v1_deployment_xct-qm3.yaml
      sed -z "s/name:\s*xct/&-qm4/" ${generatedpath}/apps_v1_deployment_xct.yaml > ${kustomizeoverlayspath}/${env}/${context}/apps_v1_deployment_xct-qm4.yaml
   fi

   echo "Generated the following qm specific yamls for ${env}"
   ls -ltr ${kustomizeoverlayspath}/${env}/${context}/apps_v1_deployment*qm*.yaml

   #generate kustomization.yaml
   echo "prepare for kustomisation round 2 - building dynamic kustomization.yaml file for qm files"
   cat ${kustomizeoverlayspath}/${env}/${context}/kustomization_overlay.yaml > ${kustomizeoverlayspath}/${env}/${context}/kustomization.yaml

   kustomize build ${kustomizeoverlayspath}/${env}/${context}/ --output "${generatedpath}"

   # tidy up the kustomise folder
   rm ${kustomizeoverlayspath}/${env}/${context}/apps_v1_deployment*qm*.yaml
   
   echo "*****************************"
   echo "kustomize stages all complete"
   echo "*****************************"
fi

echo "validing yaml syntax for generated manifests"
./validate.sh > build.log

if [ $? -eq 1 ]
then
  echo "Process stopping - Validate detected an error in generated yaml from add customisations script - check build.log"
  exit 1
fi

if [ ${yaml} == true ]
then
  echo "Generating Yaml files only, no deployment."
  exit 0
fi

echo "connect to the kubernetes cluster"
./kube-connect.sh
rc=$?
if [ $rc -ne 0 ]
then
   echo "Invalid Credentials Entered"
   echo
   exit 10
fi

echo "Apply yaml to namespace -> ${env}"
./apply.sh
if [ $? -eq 1 ]
then
  echo "Process stopping - Error in kubectl apply from apply yaml script."
  exit 1
fi

echo "Completed Successfully - see build.log for info"

#chmod 666 build.log

exit 0
