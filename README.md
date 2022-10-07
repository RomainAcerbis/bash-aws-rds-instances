# bash-aws-rds-instances

# Notes

```bash-aws-rds-instances``` is a bash script usable in CI to change status of AWS RDS instances (and wait for them to reach target status).


This script assumes that you do have four databases named like this :
```
{project_name}-dev
{project_name}-test
{project_name}-staging
{project_name}-prod
```


# How to use
## Arguments
`k` : Your AWS access `k`ey, usually stored on your remote repository as $AWS_ACCESS_KEY_ID repository variable.

`s` : Your AWS `s`ecret key, usually stored on your remote repository as $AWS_SECRET_ACCESS_KEY repository variable.

`r` : The AWS `r`egion where your resources are stored.

`m` : The `m`ode you want to run the script with. Accepted values are only `start` and `stop`.

`e` : The `e`nvironment where you want to run the script. Accepted values are only `dev`, `test`, `staging`, `prod` and `all` if you want to target all four environments.

## Examples

```bash
bash ./script.sh -k $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY -r $AWS_DEFAULT_REGION -m "start" -e "all"
bash ./script.sh -k $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY -r "eu-west-3" -m "stop" -e "staging"
bash ./script.sh -k "THISISANAWSACCESSKEY" -s "XXXTOTTALLYSECRETKEYHEREXXX" -r $AWS_DEFAULT_REGION -m "start" -e "dev"
```