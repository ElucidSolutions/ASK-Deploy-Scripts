
# ASK user guides and deploys the given version
# in its place.

while getopts "hv" option
do
  case option in
    h) cat <<- EOF
Usage: deploy.sh [options] <package>.tar.bz2

Deploys the given package to the ASK server. This tool is designed
to update https://ask.fas.gsa.gov.

Example

> deploy.sh guides_021418.tar.bz2

Author

Larry Lee <larry_lee@elucidsolutions.com>
EOF
      exit 0;;
    v) verbose=1 ;;
  esac
done
shift $((OPTIND - 1))

timestamp=$(date +%m%d%y)
backup="guides-backup-$timestamp.tar.bz2"

if [[ $# < 1 ]]
then
  echo "Error: Invalid command line. The <package> argument is missing."
  exit 1
else
  package=$1
fi

# Accepts one argument: message, a message
# string; and prints the given message iff the
# verbose flag has been set.
function display () {
  local message=$1

  if [[ $verbose == 1 ]]
  then
    echo $message
  fi
}

# Accepts two arguments: host, a hostname; and
# path, a file path; and deploys the package
# to the given host under the given path.
function deploy () {
  local user=$1
  local host=$2
  local home_path=$3
  local site_path=$4

  display "Backing up the existing user guides $host."
  local command="cd $home_path; tar --exclude '*/data/*' --bzip2 -cf $backup $site_path; sha1sum $backup > $backup.sha1"
  display "command: " $command
  ssh "$user@$host" $command

  display "Retrieving the backup."
  mkdir backups
  scp "$user@$host:$home_path/{$backup,$backup.sha1}" backups
  local command="cd $home_path; rm -v $backup $backup.sha1;"
  display "command: " $command
  ssh "$user@$host" $command

  display "Deploying the user guides to $host."
  scp $package "$user@$host:$home_path"
  ssh "$user@$host" "cd $site_path; make clean; cd $home_path; mv $package $site_path; cd $site_path; tar --strip-components=1 --bzip2 -xf $package; chmod -R 777 ."
}

# deploy 'ptran' 'ask.fas.gsa.gov' '/home/ptran' '/web/ask.fas.gsa.gov/docs'

deploy 'ptran' 'fcoh1m-edweb1.fas.gsa.gov' '/home/ptran' '/web/amsystemssupport.fas.gsa.gov/docs'
