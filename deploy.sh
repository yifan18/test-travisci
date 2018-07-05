
# Version key/value should be on his own line
PACKAGE_VERSION=$(cat package.json | grep version | awk '{print $2}' | sed 's/[",]//g')
PROJECT_NAME=$(cat package.json | grep name | awk '{print $2}' | sed 's/[",]//g')

serverhost=yifan.moe
deploy_version_path=/home/deploy/${PROJECT_NAME}/${PACKAGE_VERSION}
deploy_latest_path=/home/deploy/${PROJECT_NAME}/latest
server=root@$serverhost


# 创建临时目录
temp_folder=$RANDOM
mkdir $temp_folder
# 创建部署文件
cat << EOF > $temp_folder/sdl.sh
# 1. 移动build目录到相应版本目录
if [ ! -d $deploy_version_path ]; then
  mkdir -p $deploy_version_path
fi
cp -R build $deploy_version_path

# 2. 移动build目录到部署目录
if [ ! -d $deploy_latest_path ]; then
  mkdir -p $deploy_latest_path
fi
cp -R build $deploy_latest_path

# 3. 删除临时目录
rm -rf /home/$temp_folder
EOF

# 把build跟部署文件.sh都传到home下的临时目录
cp -R "build" "$temp_folder"

# 把临时目录传到部署服务器home目录下
scp -o StrictHostKeyChecking=no -r $temp_folder "$server:/home"

# 执行临时目录下的sdl.sh
ssh $server "cd /home/$temp_folder && chmod 777 sdl.sh && ./sdl.sh" -o StrictHostKeyChecking=no



