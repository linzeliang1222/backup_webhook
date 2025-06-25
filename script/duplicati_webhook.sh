#!/usr/bin/env bash

EVENT_NAME=$DUPLICATI__EVENTNAME
OPERATION_NAME=$DUPLICATI__OPERATIONNAME
RESULT_FILE=$DUPLICATI__RESULTFILE
BACKUP_NAME=$DUPLICATI__backup_name
PARSED_RESULT=$DUPLICATI__PARSED_RESULT
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
WECHAT_KEY="<YOUR-WECHAT-KEY>"

send_wechat_message() {
  message=$1
  response=$(curl -s "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=$WECHAT_KEY" \
   -H "Content-Type: application/json" \
   -d "{\"msgtype\": \"text\",\"text\": {\"content\": \"$message\"}}")
  if ! echo "$response" | grep -q '"errcode":0'; then
    exit 1
  fi
}

message="⚠️【Duplicati】未知操作 [$EVENT_NAME]: $OPERATION_NAME！\n时间：$DATETIME\n计划：$BACKUP_NAME"
if [ "$EVENT_NAME" == "BEFORE" ]; then
  if [ "$OPERATION_NAME" == "Backup" ]; then
    message="🚀【Duplicati】开始备份......\n时间：$DATETIME\n计划：$BACKUP_NAME"
  fi
elif [ "$EVENT_NAME" == "AFTER" ]; then
  if [ "$OPERATION_NAME" == "Backup" ]; then
    if [ "$PARSED_RESULT" == "Success" ]; then
      message="✅【Duplicati】备份完成～\n时间：$DATETIME\n计划：$BACKUP_NAME"
      if [ -f "$RESULT_FILE" ]; then
        function human_size() {
          local size=$1
          awk 'function human(x) {
                split("B KB MB GB TB PB", units, " ");
                i = 1;
                while (x >= 1024 && i < length(units)) {
                    x /= 1024;
                    i++;
                }
                return sprintf("%.3f %s", x, units[i]);
            }
            {print human($1)}' <<< "$size"
        }
        message="$message\n--------- 概览 ---------"
        message="$message\n操作类型：$(grep -E '^MainOperation: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n备份结果：$(grep -E '^ParsedResult: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n检查文件的大小：$(human_size $(grep -E '^SizeOfExaminedFiles: ' "$RESULT_FILE" | awk '{print $2}'))"
        message="$message\n增量文件的大小：$(human_size $(grep -E '^SizeOfAddedFiles: ' "$RESULT_FILE" | awk '{print $2}'))"
        message="$message\n修改文件的大小：$(human_size $(grep -E '^SizeOfModifiedFiles: ' "$RESULT_FILE" | awk '{print $2}'))"
        message="$message\n打开文件的大小：$(human_size $(grep -E '^SizeOfOpenedFiles: ' "$RESULT_FILE" | awk '{print $2}'))"
        begin_timestamp=$(grep -E '^BeginTime: ' "$RESULT_FILE" | grep -oE '\([0-9]+\)' | tr -d '()')
        end_timestamp=$(grep -E '^EndTime: ' "$RESULT_FILE" | grep -oE '\([0-9]+\)' | tr -d '()')
        begin_datetime=$(date -d @"$begin_timestamp" +"%Y-%m-%d %H:%M:%S")
        end_datetime=$(date -d @"$end_timestamp" +"%Y-%m-%d %H:%M:%S")
        message="$message\n备份开始时间：$begin_datetime"
        message="$message\n备份结束时间：$end_datetime"
        message="$message\n备份持续时间：$(grep -E '^Duration: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n------- 详细信息 -------"
        message="$message\n检查的文件数：$(grep -E '^ExaminedFiles: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n新增的文件数：$(grep -E '^AddedFiles: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n修改的文件数：$(grep -E '^ModifiedFiles: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n删除的文件数：$(grep -E '^DeletedFiles: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n打开的文件数：$(grep -E '^OpenedFiles: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n出错的文件数：$(grep -E '^FilesWithError: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n体积过大未被备份的文件数：$(grep -E '^TooLargeFiles: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n新增的文件夹数：$(grep -E '^AddedFolders: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n修改的文件夹数：$(grep -E '^ModifiedFolders: ' "$RESULT_FILE" | awk '{print $2}')"
        message="$message\n删除的文件夹数：$(grep -E '^DeletedFolders: ' "$RESULT_FILE" | awk '{print $2}')"
      fi
    elif [ "$PARSED_RESULT" == "Warning" ]; then
      message="⚠️【Duplicati】存在警告！\n时间：$DATETIME\n计划：$BACKUP_NAME"
    elif [ "$PARSED_RESULT" == "Error" ]; then
      message="❌【Duplicati】发生错误！\n时间：$DATETIME\n计划：$BACKUP_NAME"
    elif [ "$PARSED_RESULT" == "Fatal" ]; then
      message="💥【Duplicati】发生致命错误！\n时间：$DATETIME\n计划：$BACKUP_NAME"
    else
      message="❓【Duplicati】未知结果！\n时间：$DATETIME\n计划：$BACKUP_NAME"
    fi
  fi
fi
send_wechat_message "$message"

exit 0
