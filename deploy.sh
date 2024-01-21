#!/bin/bash
# 进入 /opt/src/navstack 目录
cd /opt/src/navstack
# 删除 /opt/src/navstack/public 目录
rm -rf /opt/src/navstack/public
# 更新 git 子模块（这一行被注释掉了，如果需要可以取消注释）
# git submodule update --init --recursive
# 从远程仓库拉取最新的代码
git pull origin main
echo "编译文件..."
# 使用 hugo 生成静态网站，并压缩文件
hugo --minify
# 使用 rsync 同步 /opt/src/navstack/public/ 目录到 /www/nav.archiguru.io 目录
echo "同步文件..."
rsync -a /opt/src/navstack/public/ /www/nav.archiguru.io
# 修改 /www/nav.archiguru.io 目录的所有者为 www 用户和 www 组
echo "修改权限..."
chown -R www:www /www/nav.archiguru.io
# 重启 nginx 服务
systemctl restart nginx.service
# 输出提示信息
echo "脚本执行完毕，网站已更新。"
