#!/usr/bin/env bash

WECHAT_KEY="<YOUR_KEY>"

send_wechat_message() {
  message=$1
  response=$(curl "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=$WECHAT_KEY" \
   -H "Content-Type: application/json" \
   -d "{\"msgtype\": \"text\",\"text\": {\"content\": \"$message\"}}")
  if ! echo "$response" | grep -q '"errcode":0'; then
    exit 1
  fi
}

build_and_send_message() {
  event_name_desc=$1
  event_name=$2
  event_oper=$3
  message=""
  case "$event_oper" in
    "start")
      message="🚀【Restic】开始$event_name_desc......"
      ;;
    "success")
      message="✅【Restic】$event_name_desc成功～"
      ;;
    "error")
      message="❌【Restic】$event_name_desc发生异常！"
      ;;
    "warning")
      message="⚠️【Restic】$event_name_desc发生警告！"
      ;;
    "skipped")
      message="⏭️【Restic】跳过$event_name_desc！"
      ;;
    *)
      case "$event_name" in
        "error")
          message="❌【Restic】发生异常！"
          ;;
        "unknown")
          message="❌【Restic】发送未知错误！"
          ;;
        *)
          message="❓【Restic】未知操作"
          ;;
      esac
      ;;
  esac

  current_time=$(date +"%Y-%m-%d %H:%M:%S")
  message="$message\n时间：$current_time"
    {{ if .Repo.Id -}}
    message="$message\n仓库：{{ .Repo.Id }}"
  {{ end }}
  {{ if .Plan.Id -}}
    message="$message\n计划：{{ .Plan.Id }}"
  {{ end }}
  {{ if .SnapshotId -}}
    message="$message\n快照ID：{{ slice .SnapshotId 0 8 }}"
  {{ end }}
  {{ if .Duration }}
    message="$message\n操作耗时：{{ .FormatDuration .Duration }}"
  {{ end }}
  {{ if .Error -}}
    message="$message\n错误消息：$(echo {{ .ShellEscape .Error }} | sed 's/"/\\"/g')"
  {{ else -}}
    {{ if .SnapshotStats -}}
        message="$message\n--------- 概览 ---------"
        message="$message\n增量数据大小：{{ .FormatSizeBytes .SnapshotStats.DataAdded }}"
        message="$message\n处理的总文件数：{{ .SnapshotStats.TotalFilesProcessed }}"
        message="$message\n处理的总字节数：{{ .FormatSizeBytes .SnapshotStats.TotalBytesProcessed }}"
        message="$message\n------- 备份统计 -------"
        message="$message\n新增文件数：{{ .SnapshotStats.FilesNew }}"
        message="$message\n更改文件数：{{ .SnapshotStats.FilesChanged }}"
        #message="$message\n未更改文件数：{{ .SnapshotStats.FilesUnmodified }}"
        message="$message\n新增目录数：{{ .SnapshotStats.DirsNew }}"
        message="$message\n更改目录数：{{ .SnapshotStats.DirsChanged }}"
        #message="$message\n未更改目录数：{{ .SnapshotStats.DirsUnmodified }}"
        message="$message\n备份持续时间：{{ .SnapshotStats.TotalDuration }}s"
    {{ end }}
  {{ end }}
  send_wechat_message "$message"
}

event="{{ .EventName .Event }}"
event_name=$(awk '{print $1}' <<< "$event")
event_oper=$(awk '{print $2}' <<< "$event")
case "$event_name" in
  "snapshot")
    build_and_send_message "创建快照" "$event_name" "$event_oper"
    ;;
  "forget")
    build_and_send_message "删除快照" "$event_name" "$event_oper"
    ;;
  "check")
    build_and_send_message "数据完整性检查" "$event_name" "$event_oper"
    ;;
  "prune")
    build_and_send_message "清理备份仓库" "$event_name" "$event_oper"
    ;;
  *)
    build_and_send_message "" "$event_name" "$event_oper"
    ;;
esac
