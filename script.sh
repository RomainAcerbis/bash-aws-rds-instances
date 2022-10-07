export_variables(){
  export AWS_ACCESS_KEY_ID=$1
  export AWS_SECRET_ACCESS_KEY=$2
  export AWS_DEFAULT_REGION=$3
}

check_status_before_pipeline() {
  if aws rds describe-db-instances --db-instance-identifier "$1" | grep -qPo "\"DBInstanceStatus\": \"\K($3)(?=\",)"
  then
    modify_database_status "$1" "$2" "$4"
  elif aws rds describe-db-instances --db-instance-identifier "$1" | grep -qPo "\"DBInstanceStatus\": \"\K($4)(?=\",)"
  then
    echo "Database $1 cannot transition to the $4 state, because it's already $4. You can verify databases status on https://eu-west-3.console.aws.amazon.com/rds (after connexion)"
  elif aws rds describe-db-instances --db-instance-identifier "$1" | grep -qPo "\"DBInstanceStatus\": \"\K(starting)(?=\",)"
  then
    if [ "$2" = "start" ]
    then
      echo "Database $1 is already starting."
    else
      echo "Database $1 is currently starting, please wait a few minutes and try again."
      exit 1
    fi
  elif aws rds describe-db-instances --db-instance-identifier "$1" | grep -qPo "\"DBInstanceStatus\": \"\K(stopping)(?=\",)"
  then
    if [ "$2" = "stop" ]
    then
      echo "Database $1 is already stopping."
    else
      echo "Database $1 is currently stopping, please wait a few minutes and try again."
      exit 1
    fi
  else
    if aws rds describe-db-instances --db-instance-identifier "$1" | grep -qPo "\"DBInstanceStatus\": \"\K(configuring-enhanced-monitoring)(?=\",)"
    then
      echo "The databases are getting configured, please wait a few minutes and try again."
      exit 1
    else
      echo "The databases are neither in the $3 nor in the $4 state. You should verify databases status on https://eu-west-3.console.aws.amazon.com/rds (after connexion)"
      exit 1
    fi
  fi
}

check_database_status() {
  counter=0
  until aws rds describe-db-instances --db-instance-identifier "$1" | grep -qPo "\"DBInstanceStatus\": \"\K($2)(?=\",)"
  do
    full_status=$(aws rds describe-db-instances --db-instance-identifier "$1" | grep DBInstanceStatus)
    tmp_status=${full_status#*\": \"}
    status=${tmp_status%\"*}

    printf "\nDatabase : %s \nTarget status : %s \nCurrent status : %s\nChecking status again in 15 seconds.\n" "$1" "$2" "$status"
    counter=$((counter+1))
    sleep 15
    if [ $counter -eq 60 ]; then
      echo "Timeout. Database $1 could not reach $2 state in , exiting."
      exit 1
    fi
  done
  echo "Database $1 is $2."
}

modify_database_status() {
  aws rds "$2-db-instance" --db-instance-identifier "$1" >> /dev/null
  echo "Database $1 is now changing it status to : $3."
}

execute(){
  if [ "$2" = "start" ]
  then
    expected_status_before="stopped"
    expected_status_after="available"

  elif [ "$2" = "stop" ]
  then
    expected_status_before="available"
    expected_status_after="stopped"
  fi
  databases=('akita' 'inuforms')
  for db in "${databases[@]}"
  do
    if [ "$1" = "all" ]
    then
      check_status_before_pipeline "$db-dev" "$mode" "$expected_status_before" "$expected_status_after"
      check_status_before_pipeline "$db-test" "$mode" "$expected_status_before" "$expected_status_after"
      check_status_before_pipeline "$db-staging" "$mode" "$expected_status_before" "$expected_status_after"
      check_status_before_pipeline "$db-prod" "$mode" "$expected_status_before" "$expected_status_after"
    else
      check_status_before_pipeline "$db-$1" "$mode" "$expected_status_before" "$expected_status_after"
    fi
  done
  for db in "${databases[@]}"
  do
    if [ "$1" = "all" ]
      then
        check_database_status "$db-dev" "$expected_status_after"
        check_database_status "$db-test" "$expected_status_after"
        check_database_status "$db-staging" "$expected_status_after"
        check_database_status "$db-prod" "$expected_status_after"
      else
        check_database_status "$db-$1" "$expected_status_after"
      fi
  done
}

while getopts k:s:r:m:e: flag
do
    case "${flag}" in
        k) key=${OPTARG};;
        s) secret=${OPTARG};;
        r) region=${OPTARG};;
        m) mode=${OPTARG};;
        e) env=${OPTARG};;
        *) echo "Usage: $0 -k <aws_access_key_id> -s <aws_secret_access_key> -r <aws_default_region> -m <mode> -e <environment>"
           exit 1;;
    esac
done

echo "ENV=$env"
echo "MODE=$mode"

export_variables "$key" "$secret" "$region"
execute "$env" "$mode"
