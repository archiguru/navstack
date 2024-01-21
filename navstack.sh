#!/bin/bash
REPO_NAME="navstack"
DEBUG="true"
# log 文件位置
LOG_FILE="/opt/scripts/webhookd/logs/navstack_$(date '+%Y%m%d_%H%M%S').log"
# 函数
payloadExit() {
	echo "错误: $@" 1>&2
	exit 1
}
isDebug() {
	[ "$debug" = "true" ] && echo -e "Debug:\n $@"
}
# 验证
payload=$1
[ -z "$payload" ] && payloadExit "payload 请求体不存在， 请检查配置。"
# Debug
isDebug "已收到 payload:\n $payload"
############# 这里是真正要执行的脚本 ################
# 删除原有日志文件
cd "/opt/scripts/webhookd/logs" || return
COUNT_LOGS=1 && echo ""
if [ "" ] >0; then
	echo "存在日志，先删除："
	rm -rf "navstack*" || return
fi
# 调用部署脚本
cd "/opt/scripts/webhookd/deploy" || return
nohup "/opt/scripts/webhookd/deploy/deploy_navstack.sh" >"${LOG_FILE}" 2>&1 &

####################################################

echo "已成功调用部署脚本，并后台运行部署；请稍后查看结果。"
echo "#########    navstack hook 已发送完毕!   ########"
exit 0
