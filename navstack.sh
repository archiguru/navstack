#!/bin/bash

REPO_NAME="navstack"
ROOT_PATH="/opt/scripts/webhookd"
LOG_FILE="${ROOT_PATH}/logs/navstack_$(date '+%Y%m%d_%H%M%S').log"

payloadExit() {
    echo "错误: $*" 1>&2
    exit 1
}

# 验证
payload=$1
[ -z "${payload}" ] && payloadExit "payload 请求体不存在，请检查配置。"

############# 这里是真正要执行的脚本 ################
# 删除原有日志文件
cd "${ROOT_PATH}/logs" || return
rm -rf "${REPO_NAME}"* || return

# 调用部署脚本
cd "${ROOT_PATH}/deploy" || return
echo "进入项目目录："
cd "/opt/src/${REPO_NAME}" || return
git pull origin "main":"main"
git reset --hard "origin/main"
git stash clear
git clean -d -fx .

if [ -f ".gitmodules" ]; then
    git submodule update --init
    git submodule foreach git checkout "main"
    git submodule foreach git pull origin "main"
fi

echo "✅ 已成功拉取最新代码！"

#***********  这里编写其余逻辑,如编译/部署等操作  **************
echo "***********     开始执行编译/部署操作：    ***************"

echo "编译文件..."
# 使用 hugo 生成静态网站，并压缩文件
rm -rf "/opt/src/${REPO_NAME}/public/"
hugo --minify
# 使用 rsync 同步 /opt/src/navstack/public/ 目录到 /www/nav.archiguru.io 目录
echo "同步文件..."
rsync -a "/opt/src/${REPO_NAME}/public/" "/www/nav.archiguru.io"
# 修改 /www/nav.archiguru.io 目录的所有者为 www 用户和 www 组
echo "修改权限..."
chown -R www:www "/www/nav.archiguru.io"
# 重启 nginx 服务
systemctl restart nginx.service
# 输出提示信息
echo "脚本执行完毕，网站已更新。"

#********************  部署逻辑结束  ***************************
echo "****************************************"
echo "        已成功部署 ${REPO_NAME}"
echo "****************************************"

#echo "✅ 已成功调用部署脚本，并后台运行部署；请稍后查看结果。"
#echo "#########    navstack hook 已发送完毕!   ########"
exit 0
