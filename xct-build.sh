export env=""
export fulldelete="false"
export yaml="false"
export cluster=""
export rundate=`date '+%d-%m-%C%y at %H:%M:%S'`


print_usage() {
  printf '\nUsage: %s: [-c] cluster [-n] env [-d] do full delete [-y] generate yaml files only  \n' $0
}

while getopts 'c:n:dy' flag; do
  case "${flag}" in
    c)
      cluster="${OPTARG}" ;;
    n)
      env="${OPTARG}" ;;
    d)
      fulldelete='true' ;;
    y)
      yaml='true' ;;
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
