#!/bin/ksh

export ver=4.0.2
export releasever="v${ver//.}"
export numrel="${ver//.}"
export strippedenv=${env#*-}
export supportsIAM="false"

case "$env" in
"xct-st" | "xct-sit" | "xct-sit2" | "xct-sit3" | "xct-nft" | "xct-nft2")
  if [[ ${cluster} == "dev01" ]]
  then  
    export context=pks-k8s-dev01-int08  
    export dev=dev01
    export dc=dev01
  else
    export context=pks-k8s-dev02-int08
    export dev=dev02
    export dc=dev02
  fi
;;
"xct-prod")
  if [[ ${cluster} == "prod01" ]]
  then  
    export context=pks-k8s-prod01-int05  
    export dev=prod01
    export dc=prod01
  else
    export context=pks-k8s-prod02-int05
    export dev=prod02
    export dc=prod02
  fi
;;
*)
  exit 1
  ;;
esac

case "$env" in
"xct-sit" | "xct-nft" | "xct-prod")
   supportsIAM="true"
;;
"xct-st" | "xct-nft2" | "xct-sit2" | "xct-sit3")
  supportsIAM="false"
;;
*)
  exit 1
  ;;
esac

# never change the releasename value - otherwise you will not be able to do a rolling update.
#export releasename=nwg
export xctreleasename=xct
export ovareleasename=ova
export logsink=false
# paths
export runpath=$(dirname $(readlink -f $0))
export buildpath="$(dirname $(dirname $(realpath $0)) )"
export generatedpath=${buildpath}/generated/${env}/${cluster}/yaml
export testdir=for-validation-only
export templatepath=${buildpath}/fis/helm/xct
export ovatemplatepath=${buildpath}/fis/helm/ova
export dewarehousingtemplatepath=${buildpath}/fis/helm/dewarehousing
export gpitrackertemplatepath=${buildpath}/fis/helm/gpitracker
export outgoinginitiationtemplatepath=${buildpath}/fis/helm/outgoingInitiation
export accountpostingtemplatepath=${buildpath}/fis/helm/accountPosting
export cleanuptemplatepath=${buildpath}/fis/helm/cleanup
export keycloaktemplatepath=${buildpath}/fis/helm/keycloak
export valuespath=${buildpath}/values/${env}/${cluster}
export commonpath=${buildpath}/common/
export envcommonpath=${commonpath}/${env}
export xctenvcommonpath=${commonpath}/${env}/xct/${dc}
export ovaenvcommonpath=${commonpath}/${env}/ova/${dc}
export keycloakenvcommonpath=${commonpath}/${env}/keycloak/${dc}
export keycloaksslcommonpath=${commonpath}/${env}/ssl
export envcommonpath=${commonpath}/${env}
export commonaccsecretspath=${commonpath}/acc-secrets
export commonkeystorespath=${commonpath}/configmaps
export configmapspath=${commonpath}/${env}/configmaps
export kustomizepath=${buildpath}/kustomize
export kustomizebasepath=${kustomizepath}/base
export kustomizeoverlayspath=${kustomizepath}/overlays
