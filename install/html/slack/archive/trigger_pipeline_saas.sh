#!/bin/bash
#vmeoc

export api_token=dad4da1d-57c3-41b6-85fb-2b67da4136b3
export bearer=`curl -X POST 'https://api.mgmt.cloud.vmware.com/iaas/login' -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{ 'refreshToken': '$api_token' }' | jq -r '.token'`
export PipelineID=c1848382f840e075589d8ce382eba

curl -X POST 'https://api.mgmt.cloud.vmware.com/pipeline/api/pipelines/'$PipelineID'/executions' -H 'Content-Type: application/json' -H 'Authorization: Bearer '$bearer'' -d '{}'
