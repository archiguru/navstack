#!/bin/bash

clear

echo -n "请输入项目[仓库]名称: "
read -r REPO_NAME

if [ -z "${REPO_NAME}" ]; then
    echo "错误：输入的项目名称不正确。"
    exit 1
fi

echo -n "请输入分支名称 (默认: main): "
read -r BRANCH_NAME
BRANCH_NAME="${BRANCH_NAME:-main}"

ROOT_PATH="/opt/scripts/webhookd"
SRC_PATH="/opt/src"

mkdir -p "${ROOT_PATH}/logs/" "${ROOT_PATH}/deploy/" "${SRC_PATH}"

# 创建 ${REPO_NAME}.sh 文件
HOOK_SCRIPT="${ROOT_PATH}/${REPO_NAME}.sh"
touch "$HOOK_SCRIPT"
cat >"$HOOK_SCRIPT" <<EOF
#!/bin/bash
REPO_NAME="${REPO_NAME}"
DEBUG=true
# log 文件位置
LOG_FILE="${ROOT_PATH}/logs/${REPO_NAME}_\$(date '+%Y%m%d_%H%M%S').log"
# 函数
payloadExit() { echo "错误: \$*" 1>&2 ; exit 1; }
isDebug() {
  [ "\$DEBUG" = "true" ] && echo -e "Debug:\n \$*"
}
# 验证
payload=\$1
[ -z "\$payload" ] && payloadExit "payload 请求体不存在， 请检查配置。"
# Debug
isDebug "已收到 payload:\n \$payload"
############# 这里是真正要执行的脚本 ################
# 删除原有日志文件
cd "${ROOT_PATH}/logs" || return
COUNT_LOGS=\$(ls -l | grep -c "${REPO_NAME}*")
echo "\$COUNT_LOGS"
if [ "\$COUNT_LOGS" -gt 0 ]; then
    echo "❌ 存在日志，先删除："
    rm -rf "${REPO_NAME}*" || return
fi

# 调用部署脚本
cd "${ROOT_PATH}/deploy" || return
nohup "${ROOT_PATH}/deploy/deploy_${REPO_NAME}.sh" > "\${LOG_FILE}" 2>&1 &
####################################################
echo "✅ 已成功调用部署脚本，并后台运行部署；请稍后查看结果。"
echo "#########    ${REPO_NAME} hook 已发送完毕!   ########"
exit 0;
EOF

echo "==============================================="
echo "========== 已生成 ${REPO_NAME}.sh 文件。========="
echo "==============================================="

# 创建 deploy_${REPO_NAME}.sh 文件
DEPLOY_SCRIPT="${ROOT_PATH}/deploy/deploy_${REPO_NAME}.sh"
touch "$DEPLOY_SCRIPT"
cat >"$DEPLOY_SCRIPT" <<EOF
#!/bin/bash
REPO_NAME="${REPO_NAME}"
dateTime="\$(date '+%Y%m%d_%H%M%S')"
echo "进入项目目录："
cd "$SRC_PATH/${REPO_NAME}" || return
git pull origin "${BRANCH_NAME}":"${BRANCH_NAME}"
git reset --hard "origin/${BRANCH_NAME}"
git stash clear
git clean -d -fx .
if [ -f ".gitmodules" ]; then
  git submodule update --init
  git submodule foreach git checkout "${BRANCH_NAME}"
  git submodule foreach git pull origin "${BRANCH_NAME}"
fi
echo "✅ 已成功拉取最新代码！"

#***********  这里编写其余逻辑,如编译/部署等操作  **************
echo "***********     开始执行编译/部署操作：    ***************"


#********************  部署逻辑结束  ***************************
echo "****************************************"
echo "        已成功部署 ${REPO_NAME}"
echo "****************************************"
exit 0;

EOF

echo "✅ 已生成部署文件 deploy_${REPO_NAME}.sh"
chmod +x "$HOOK_SCRIPT"
chmod +x "$DEPLOY_SCRIPT"
echo "✅ 已添加执行权限！"
echo -e "#######################    完成！    ######################\n"
echo "✅ 已生成 ${REPO_NAME} 的 hook 脚本:"
ls -g "$HOOK_SCRIPT"
echo "✅ 已生成 ${REPO_NAME} 的部署脚本:"
ls -g "$DEPLOY_SCRIPT"
echo -e "\n⚠️ 请编辑 \"$ROOT_PATH/deploy/deploy_${REPO_NAME}.sh\" 来启用自动化部署。"
exit 0
