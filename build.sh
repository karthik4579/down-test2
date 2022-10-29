#!/bin/bash
uploadcache ()
{
cd /tmp
tar --use-compress-program="pigz -k -$2 " -cf $1.tar.gz $1
rclone copy --config=/tmp/rclone.conf --progress --drive-chunk-size=512M ./ccache.tar.gz gdrive:/ccache
}


emptycheck ()
{
unset out
unset check
check=$(rclone size --config=/tmp/rclone.conf gdrive:/ccache) 
echo $check > result.txt
grep -w "(0 Byte)" result.txt >> /dev/null 
out=$? #if 0 then folder is empty or else the folder is not empty
echo $out
rm -rf result.txt
}


downloadccache ()
{
rclone copy --config=/tmp/rclone.conf gdrive:/ccache/ccache.tar.gz /tmp
curl -s --data "text=Downloading of CCACHE has finished" --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
}


uploadrom ()
{
rclone copy --config=/tmp/rclone.conf --progress /out/target/product/onclite/*zip gdrive:/roms
}


setup ()
{
mkdir $2
sudo apt update && sudo apt upgrade -y
echo "$TDRIVE" >> /tmp/rclone.conf
git config --global user.name "karthik4579"
git config --global user.email karthiknair021@gmail.com
git config --global color.ui false
git config --global url."https://github.com/".insteadOf git://github.com/
export PATH=/usr/local/gcc-12.2.0/bin:$PATH >> ~/.bashrc \
export LD_LIBRARY_PATH=/usr/local/gcc-12.2.0/lib64:$LD_LIBRARY_PATH >> ~/.bashrc \
source ~/.bashrc \
export CC=/usr/local/gcc-12.2.0/bin/gcc-12.2 >> ~/.bashrc \
export CXX=/usr/local/gcc-12.2.0/bin/g++-12.2 >> ~/.bashrc \
export FC=/usr/local/gcc-12.2.0/bin/gfortran-12.2 >> ~/.bashrc \
source ~/.bashrc
cd /usr/src
ln -sfn linux-headers-2.6.35-28-generic linux
cd $1
}


clone ()
{
cd $1
repo init -q --no-repo-verify --depth=1 --partial-clone --clone-filter=blob:limit=10M --no-repo-verify --depth=1 -u $2 -b $3 -g default,-mips,-darwin,-notdefault
repo sync -c -j32
git clone https://github.com/karthik4579/local_manifests.git --depth=1 -b 13 .repo/local_manifests
}



# some essentials build variables
pwd=$(pwd)
build_dir=$pwd/Ricedroid
manifest_url=https://github.com/RiceDroid/android
manifest_branch=thirteen
tg_chat_id=$(echo "$TG_CHAT_ID")
tg_api_key=$(echo "$TG_API_KEY")


curl -s --data "text=****************The Script has started here***************" --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
setup $pwd $build_dir

curl -s --data "text=Setup has finished ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
clone $build_dir $manifest_url $manifest_branch

curl -s --data "text=Source Clone has finished ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
result=$(emptycheck)





if [[ $result -eq 0 ]]
then
cd $build_dir
export CCACHE_DIR=/tmp/ccache
export CCACHE_COMPRESS=1
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 20G
ccache -o compression=true
ccache -z
curl -s --data "text=Normal Build has started ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
. build/envsetup.sh && brunch onclite >> /tmp/buildlog.txt &
sleep 85m
kill %1
buildnorm=$?
if [[ $buildnorm -eq 0 ]]
then
curl -s --data "text=First build for ccache has finished ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
else
curl -s --data "text=First build for ccache has failed ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
curl -F document=@"/tmp/buildlog.txt" https://api.telegram.org/bot'$tg_api_key'/sendDocument?chat_id=$tg_chat_id > /dev/null
fi


else
cd $build_dir
downloadccache
tar -xf /tmp/ccache.tar.gz
rm -rf /tmp/ccache.tar.gz
curl -s --data "text=Extraction of CCACHE has finished ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 20G
ccache -o compression=true
ccache -z
curl -s --data "text=Build with CCACHE has started ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
. build/envsetup.sh && brunch onclite >> /tmp/buildlog.txt &
sleep 85m
kill %1
buildcached=$?
if [[ $buildcached -eq 0 ]]
then
curl -s --data "text=Build with CCACHE has finished ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
else
curl -s --data "text=Build with CCACHE has failed ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
curl -F document=@"/tmp/buildlog.txt" https://api.telegram.org/bot'$tg_api_key'/sendDocument?chat_id=$tg_chat_id > /dev/null
fi
fi


romfoldersize=$(du -sh $build_dir/out/target/product/onclite | grep '4.0K')
if [[ $romfoldersize -eq 1 ]]
then
uploadrom
curl -s --data "text=Uploading rom has finished ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
else

if [[ $result -eq 0 ]]
then
time uploadcache ccache 1
else
rclone delete --config=/tmp/rclone.conf gdrive:/ccache/ccache.tar.gz
time uploadcache ccache 1
fi

curl -s --data "text=Re-uploading new CCACHE has finished ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
curl -s --data "text=Sending the build log here ..." --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
curl -F document=@"/tmp/buildlog.txt" https://api.telegram.org/bot'$tg_api_key'/sendDocument?chat_id=$tg_chat_id > /dev/null
curl -s --data "text=****************The Script has ended here***************" --data "chat_id=$tg_chat_id" 'https://api.telegram.org/bot'$tg_api_key'/sendMessage' > /dev/null
history -c
fi

#Dummy section
#1
#2
