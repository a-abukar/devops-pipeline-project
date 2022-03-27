#!/bin/zsh
#set -e
OPTIND=1
trap
MFA="arn:aws:iam::843361875856:mfa/abdurahmanabukar"
helpFunction()
{
   echo ""
   echo "Usage: source $0 -n  -p "
   echo -e "\t-n Name of AWS account to assume"
   echo -e "\t-p OTP authentication (MFA)"
}

while getopts n:p: flag
do
    case "${flag}" in
        n) account_name=${OPTARG};;
        p) otp=${OPTARG};;
    esac
done

if [[ -z "$account_name" || -z "${otp}" ]]
then
    helpFunction
fi
case "${account_name}" in
    team7) ACCOUNT="175965390220";;
    ?) helpFunction ;;
esac

echo $account_name
unset AWS_PROFILE
unset AWS_SESSION_TOKEN
unset AWS_SECRET_ACCESS_KEY
unset AWS_ACCESS_KEY_ID
unset AWS_REGION
export AWS_REGION="eu-west-2"
export AWS_PROFILE=default
developer_role=$(aws sts assume-role \
                    --role-arn "arn:aws:iam::${ACCOUNT}:role/OrganizationEngineerAccessRole" \
                    --role-session-name "OrganizationEngineerAccessRole" \
                    --serial-number ${MFA} \
                    --token-code ${otp})
export AWS_ACCESS_KEY_ID=$(echo $developer_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $developer_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $developer_role | jq -r .Credentials.SessionToken)
env | grep AWS_
