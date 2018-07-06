
# Version key/value should be on his own line
PACKAGE_VERSION=$(cat package.json | grep version | awk '{print $2}' | sed 's/[",]//g')
PROJECT_NAME=$(cat package.json | grep name | awk '{print $2}' | sed 's/[",]//g')

serverhost=yifan.moe
deploy_path=/home/deploy/${PROJECT_NAME}
deploy_version_path=$deploy_path/${PACKAGE_VERSION}
deploy_latest_path=$deploy_path/latest
server=root@$serverhost


# 创建临时目录
temp_folder=$RANDOM
mkdir $temp_folder
# 创建部署文件
cat << EOF > $temp_folder/sdl.sh

# 验证项目目录
if [ ! -d $deploy_path ]; then
  mkdir -p $deploy_path
fi

# 1. 移动build目录到相应版本目录
cp -R build/ $deploy_version_path

# 2. 移动build目录到部署目录
cp -R build/ $deploy_latest_path

# 3. 删除临时目录
rm -rf /home/$temp_folder
EOF



# 从latest的package.json里拿到版本号
if [ -d "$deploy_latest_path/.version" ]; then
  last_version=$(cat $deploy_latest_path/.version)
  deploy_last_version_path=$deploy_path/${last_version}
  
# 创建回滚文件
cat <<EOF > build/rollback.sh
# 回滚到上一个版本

# 如果带了版本号参数 直接使用
custom_version=\$1
if [ \$custom_version ] && [ -d $deploy_path/\$custom_version ]; then
  cp -R $deploy_path/\$custom_version/ $deploy_latest_path
  exit
fi

if [ $deploy_last_version_path ]; then
  cp -R $deploy_last_version_path/ $deploy_latest_path
fi
EOF
fi


# 放一个版本文件.version
cat <<EOF > build/.version
PACKAGE_VERSION
EOF

# 把build跟部署文件.sh都传到home下的临时目录
cp -R "build" "$temp_folder"

# 把临时目录传到部署服务器home目录下 这里需要home的权限
scp -o StrictHostKeyChecking=no -r $temp_folder "$server:/home"

# 执行临时目录下的sdl.sh
ssh $server "cd /home/$temp_folder && chmod 777 sdl.sh && ./sdl.sh" -o StrictHostKeyChecking=no



