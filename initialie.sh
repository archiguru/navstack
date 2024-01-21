#!/bin/bash
if [ "$(uname)" == "Darwin" ]; then
    repo=$(pwd)
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    repo="/opt/src/navstack/"
fi

cd $repo || exit

git remote -v
rm -rf .git
git init
#git branch -m "main"
git remote add origin git@gitee.com:archiguru/navstack.git
git add -A && git commit -m"first commit"
git push -u origin main --force
