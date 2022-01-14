#!/bin/bash
currentTime=$(date +%s)
utilizationCheck=$(qq capacity_history_get --begin-time $((currentTime - 1)) --end-time $currentTime --interval hourly|jq -r '.[]|(((.capacity_used|tonumber) + (.snapshot_used|tonumber)) / (.total_usable|tonumber) * 100 >= 90)')
if [[ "$utilizationCheck" == "false" ]]
then
highUtilizationIDs=$(qq quota_list_quotas --page-size 1000|jq -r '.quotas|.[]|[.id, ((.capacity_usage|tonumber) / (.limit|tonumber) * 100 >= 90)]| @tsv'|grep true|awk '{print $1}')

for fileID in "${highUtilizationIDs[@]}"
do
	quotaLimit=$(qq quota_list_quotas --page-size 1000|jq -r --arg fileID "$fileID" '.quotas|.[]|select (.id == $fileID)|.limit')
	newQuotaLimit=$((quotaLimit*110/100000000000))
	qq quota_update_quota --id $fileID --limit $newQuotaLimit"GB"
	echo $(date)",New quota has been set for "$fileID"."  >> quota.log
done
else
	echo $(date)",Warning - High cluster capacity utilization. You should check the capacity consumptions and set quota according to that" >> quota.log
fi
