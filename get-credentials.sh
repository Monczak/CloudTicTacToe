#!/bin/bash

# THIS IS EXTREMELY HORRENDOUS AND SHOULD NOT BE DONE EVER
# But it seems to be required here since boto3 on EC2 needs credentials, 
# IamInstanceProfile refuses to work and lab users aren't authorized to perform AssumeRole for some ungodly reason

ACCESS_KEY=`cat ~/.aws/credentials | grep aws_access_key_id | awk '{ p=index($1,"=");print substr($1,p+1) }'`
SECRET_KEY=`cat ~/.aws/credentials | grep aws_secret_access_key | awk '{ p=index($1,"=");print substr($1,p+1) }'`
SESSION_TOKEN=`cat ~/.aws/credentials | grep aws_session_token | awk '{ p=index($1,"=");print substr($1,p+1) }'`

echo "{\"access_key\":\"$ACCESS_KEY\",\"secret_key\":\"$SECRET_KEY\",\"session_token\":\"$SESSION_TOKEN\"}"
