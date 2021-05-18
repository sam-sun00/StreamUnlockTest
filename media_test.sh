#!/bin/bash
shell_version="1.0.4";
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36";
UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)";
Font_Black="\033[30m";
Font_Red="\033[31m";
Font_Green="\033[32m";
Font_Yellow="\033[33m";
Font_Blue="\033[34m";
Font_Purple="\033[35m";
Font_SkyBlue="\033[36m";
Font_White="\033[37m";
Font_Suffix="\033[0m";

clear;
echo -e "流解锁测试 SteramUnlockTest";
echo -e "当前版本: v${shell_version}";

export LANG="en_US.UTF-8";
export LANGUAGE="en_US.UTF-8";
export LC_ALL="en_US.UTF-8";

function InstallJQ() {
    if [ -e "/etc/redhat-release" ];then
        echo -e "${Font_Green}正在安装依赖: epel-release${Font_Suffix}";
        yum install epel-release -y -q > /dev/null;
        echo -e "${Font_Green}正在安装依赖: jq${Font_Suffix}";
        yum install jq -y -q > /dev/null;
    elif [[ $(cat /etc/os-release | grep '^ID=') =~ ubuntu ]] || [[ $(cat /etc/os-release | grep '^ID=') =~ debian ]];then
        echo -e "${Font_Green}正在更新软件包列表...${Font_Suffix}";
        apt-get update -y > /dev/null;
        echo -e "${Font_Green}正在安装依赖: jq${Font_Suffix}";
        apt-get install jq > /dev/null;
    else
        echo -e "${Font_Red}请手动安装jq${Font_Suffix}";
        exit;
    fi
}

function PharseJSON() {
    # 使用方法: PharseJSON "要解析的原JSON文本" "要解析的键值"
    # Example: PharseJSON ""Value":"123456"" "Value" [返回结果: 123456]
    echo -n $1 | jq -r .$2;
}

function GameTest_Steam(){
    echo -n -e " Steam:\t\t\t\t\t->\c";
    local result=`curl --user-agent "${UA_Browser}" -${1} -fsSL --max-time 30 https://store.steampowered.com/app/761830 2>&1 | grep priceCurrency | cut -d '"' -f4`;
    
    if [ ! -n "$result" ]; then
        echo -n -e "\r Steam:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
    else
        echo -n -e "\r Steam:\t\t\t\t\t${Font_Green}Yes(Currency: ${result})${Font_Suffix}\n";
    fi
}

function MediaUnlockTest_ABC() {
    echo -n -e " ABC:\t\t\t\t\t->\c";
    # 尝试获取成功的结果
    local result=`curl -${1} --max-time 30 -fsSL -H 'Content-Type: application/x-www-form-urlencoded' -X POST -d 'type=gt&brand=001&device=001' https://prod.gatekeeper.us-abc.symphony.edgedatg.go.com/vp2/ws/utils/2020/geo/video/geolocation.json 2>&1`;
    if [[ "$result" != "curl"* ]]; then
        # 下载页面成功，开始解析跳转
		local isAllowed=`echo ${result} | jq .user.allowed 2>&1`;
        if [ "${isAllowed}" = "true" ]; then
			local Country=`echo ${result} | jq .user.country 2>&1`
            echo -n -e "\r ABC:\t\t\t\t\t${Font_Green}Yes(Country: ${Country})${Font_Suffix}\n";
        else
            echo -n -e "\r ABC:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n";
        fi
    else
        # 下载页面失败，返回错误代码
        echo -e "\r ABC:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
    fi
}

function MediaUnlockTest_DAZN() {
    echo -n -e " DAZN:\t\t\t\t\t->\c";
    # 尝试获取成功的结果
    local result=`curl -${1} --max-time 30 -fsSL -H 'Content-Type: application/json' -X POST -d '{"LandingPageKey": "generic", "Languages": "zh-TW,zh,en-US,en","Platform": "web", "Version": "2"}' https://startup.core.indazn.com/misl/v5/Startup 2>&1`;
    if [[ "$result" != "curl"* ]]; then
        # 下载页面成功，开始解析跳转
		local isAllowed=`echo ${result} | jq .Region.isAllowed 2>&1`;
        if [ "${isAllowed}" = "true" ]; then
			local Country=`echo ${result} | jq .Region.Country 2>&1`
            echo -n -e "\r DAZN:\t\t\t\t\t${Font_Green}Yes(Country: ${Country})${Font_Suffix}\n";
        else
            echo -n -e "\r DAZN:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n";
        fi
    else
        # 下载页面失败，返回错误代码
        echo -e "\r DAZN:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
    fi
}

function MediaUnlockTest_HBONow() {
    echo -n -e " HBO Now:\t\t\t\t->\c";
    # 尝试获取成功的结果
    local result=`curl --user-agent "${UA_Browser}" -${1} -fsSL --max-time 30 --write-out "%{url_effective}\n" --output /dev/null https://play.hbonow.com/ 2>&1`;
    if [[ "$result" != "curl"* ]]; then
        # 下载页面成功，开始解析跳转
        if [ "${result}" = "https://play.hbonow.com" ] || [ "${result}" = "https://play.hbonow.com/" ]; then
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n";
            elif [ "${result}" = "http://hbogeo.cust.footprint.net/hbonow/geo.html" ] || [ "${result}" = "http://geocust.hbonow.com/hbonow/geo.html" ]; then
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Red}No${Font_Suffix}\n";
        else
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Yellow}Failed (Parse Json)${Font_Suffix}\n";
        fi
    else
        # 下载页面失败，返回错误代码
        echo -e "\r HBO Now:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
    fi
}

# 流媒体解锁测试-动画疯
function MediaUnlockTest_BahamutAnime() {
    echo -n -e " Bahamut Anime:\t\t\t\t->\c";
    local tmpresult=`curl -${1} --user-agent "${UA_Browser}" --max-time 30 -fsSL 'https://ani.gamer.com.tw/ajax/token.php?adID=89422&sn=14667' 2>&1`;
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
        return;
    fi
    local result="$(PharseJSON "$tmpresult" "animeSn")";
    if [ "$result" != "null" ]; then
        resultverify="$(echo $result | grep -oE '[0-9]{1,}')";
        if [ "$?" = "0" ]; then
            echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n";
        else
            echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (Parse Json)${Font_Suffix}\n";
        fi
    else
        local result="$(PharseJSON "$tmpresult" "error.code")";
        if [ "$result" != "null" ]; then
            resultverify="$(echo $result | grep -oE '[0-9]{1,}')";
            if [ "$?" = "0" ]; then
                echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}No${Font_Suffix}\n";
            else
                echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (Parse Json)${Font_Suffix}\n";
            fi
        else
            echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (Parse Json)${Font_Suffix}\n";
        fi
    fi
}

# 流媒体解锁测试-哔哩哔哩大陆限定
function MediaUnlockTest_BilibiliChinaMainland() {
    echo -n -e " BiliBili China Mainland Only:\t\t->\c";
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)";
    # 尝试获取成功的结果
    local result=`curl --user-agent "${UA_Browser}" -${1} -fsSL --max-time 30 "https://api.bilibili.com/pgc/player/web/playurl?avid=82846771&qn=0&type=&otype=json&ep_id=307247&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1`;
    if [[ "$result" != "curl"* ]]; then
        local result="$(PharseJSON "${result}" "code")";
        if [ "$?" = "0" ]; then
            if [ "${result}" = "0" ]; then
                echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Green}Yes${Font_Suffix}\n";
                elif [ "${result}" = "-10403" ]; then
                echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Red}No${Font_Suffix}\n";
            else
                echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Red}Failed${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n";
            fi
        else
            echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Red}Failed (Parse Json)${Font_Suffix}\n";
        fi
    else
        echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
    fi
}

# 流媒体解锁测试-哔哩哔哩港澳台限定
function MediaUnlockTest_BilibiliHKMCTW() {
    echo -n -e " BiliBili Hongkong/Macau/Taiwan:\t->\c";
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)";
    # 尝试获取成功的结果
    local result=`curl --user-agent "${UA_Browser}" -${1} -fsSL --max-time 30 "https://api.bilibili.com/pgc/player/web/playurl?avid=18281381&cid=29892777&qn=0&type=&otype=json&ep_id=183799&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1`;
    if [[ "$result" != "curl"* ]]; then
        local result="$(PharseJSON "${result}" "code")";
        if [ "$?" = "0" ]; then
            if [ "${result}" = "0" ]; then
                echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Green}Yes${Font_Suffix}\n";
                elif [ "${result}" = "-10403" ]; then
                echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}No${Font_Suffix}\n";
            else
                echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n";
            fi
        else
            echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed (Parse Json)${Font_Suffix}\n";
        fi
    else
        echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
    fi
}

# 流媒体解锁测试-哔哩哔哩台湾限定
function MediaUnlockTest_BilibiliTW() {
    echo -n -e " Bilibili Taiwan Only:\t\t\t->\c";
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)";
    # 尝试获取成功的结果
    local result=`curl --user-agent "${UA_Browser}" -${1} -fsSL --max-time 30 "https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100279344&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1`;
    if [[ "$result" != "curl"* ]]; then
        local result="$(PharseJSON "${result}" "code")";
        if [ "$?" = "0" ]; then
            if [ "${result}" = "0" ]; then
                echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Green}Yes${Font_Suffix}\n";
                elif [ "${result}" = "-10403" ]; then
                echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}No${Font_Suffix}\n";
            else
                echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n";
            fi
        else
            echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed (Parse Json)${Font_Suffix}\n";
        fi
    else
        echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
    fi
}

# 流媒体解锁测试-Abema.TV
#
function MediaUnlockTest_AbemaTV_IPTest() {
    echo -n -e " Abema.TV:\t\t\t\t->\c";
    #
    local result=`curl --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --max-time 30 "https://api.abema.io/v1/ip/check?device=android"`;
    if [[ "$result" == "000" ]]; then
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
        return;
    fi
    local result=`curl --user-agent "${UA_Dalvik}" -${1} -fsL --max-time 30 "https://api.abema.io/v1/ip/check?device=android"`;
    local result="$(PharseJSON "${result}" "cdnRegionUrl")";
    if [ "$?" = "0" ]; then
        if [ "${result}" = "https://ds-linear-abematv.akamaized.net/region" ] || [ "${result}" = "https://ds-glb-linear-abematv.akamaized.net/region" ]; then
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n";
            elif [ "${result}" = "" ] || [ "${result}" = "null" ]; then
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n";
        else
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n";
        fi
    else
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (Parse Json)${Font_Suffix}\n";
    fi
}

function GameTest_PCRJP() {
    echo -n -e " Princess Connect Re:Dive Japan:\t->\c";
    # 测试，连续请求两次 (单独请求一次可能会返回35, 第二次开始变成0)
    local result=`curl --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 30 https://api-priconne-redive.cygames.jp/`;
    if [ "$result" = "000" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
        elif [ "$result" = "404" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Green}Yes${Font_Suffix}\n";
        elif [ "$result" = "403" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}No${Font_Suffix}\n";
    else
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n";
    fi
}

function MediaUnlockTest_BBC() {
    echo -n -e " BBC:\t\t\t\t\t->\c";
    local result=`curl --user-agent "${UA_Browser}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 30 http://ve-dash-uk.live.cf.md.bbci.co.uk/`;
    if [ "${result}" = "000" ]; then
        echo -n -e "\r BBC:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
        elif [ "${result}" = "403" ]; then
        echo -n -e "\r BBC:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n";
        elif [ "${result}" = "404" ]; then
        echo -n -e "\r BBC:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n";
    else
        echo -n -e "\r BBC:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n";
    fi
}

function MediaUnlockTest_Netflix() {
    echo -n -e " Netflix:\t\t\t\t->\c";
    local result=`curl -${1} --user-agent "${UA_Browser}" -sSL "https://www.netflix.com/" 2>&1`;
    if [ "$result" == "Not Available" ];then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Unsupport${Font_Suffix}\n";
        return;
    fi
    
    if [[ "$result" == "curl"* ]];then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
        return;
    fi
    
    local result=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/80018499" 2>&1`;
    if [[ "$result" == *"page-404"* ]] || [[ "$result" == *"NSEZ-403"* ]];then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}No${Font_Suffix}\n";
        return;
    fi
    
    local result1=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/70143836" 2>&1`;
    local result2=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/80027042" 2>&1`;
    local result3=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/70140425" 2>&1`;
    local result4=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/70283261" 2>&1`;
    local result5=`curl -${1} --user-agent "${UA_Browser}"-sL "https://www.netflix.com/title/70143860" 2>&1`;
    local result6=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/70202589" 2>&1`;
    
    if [[ "$result1" == *"page-404"* ]] && [[ "$result2" == *"page-404"* ]] && [[ "$result3" == *"page-404"* ]] && [[ "$result4" == *"page-404"* ]] && [[ "$result5" == *"page-404"* ]] && [[ "$result6" == *"page-404"* ]];then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Yellow}Only Homemade${Font_Suffix}\n";
        return;
    fi
    
    local region=`tr [:lower:] [:upper:] <<< $(curl -${1} --user-agent "${UA_Browser}" -fs --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | cut -d '-' -f1)` ;
    
    if [[ ! -n "$region" ]];then
        region="US";
    fi
    echo -n -e "\r Netflix:\t\t\t\t${Font_Green}Yes(Region: ${region})${Font_Suffix}\n";
    return;
}

function MediaUnlockTest_YouTube_Region() {
    echo -n -e " YouTube:\t\t\t\t->\c";
    local result=`curl --user-agent "${UA_Browser}" -${1} -sSL "https://www.youtube.com/" 2>&1`;
    
    if [[ "$result" == "curl"* ]];then
        echo -n -e "\r YouTube:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
        return;
    fi
    
    local result=`curl --user-agent "${UA_Browser}" -${1} -sL "https://www.youtube.com/red" | sed 's/,/\n/g' | grep "countryCode" | cut -d '"' -f4`;
    if [ -n "$result" ]; then
        echo -n -e "\r YouTube:\t\t\t\t${Font_Green}Yes(Region: ${result})${Font_Suffix}\n";
        return;
    fi
    
    echo -n -e "\r YouTube:\t\t\t\t${Font_Red}No${Font_Suffix}\n";
    return;
}

function MediaUnlockTest_DisneyPlus() {
    echo -n -e " DisneyPlus:\t\t\t\t->\c";
    local result=`curl -${1} --user-agent "${UA_Browser}" -sSL "https://www.disneyplus.com/movies/drain-the-titanic/5VNZom2KYtlb" 2>&1`;
    
    if [[ "$result" == "curl"* ]];then
        echo -n -e "\r DisneyPlus:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n";
        return;
    fi
    
    if [[ "$result" == *"https://preview.disneyplus.com/unavailable/"* ]];then
        echo -n -e "\r DisneyPlus:\t\t\t\t${Font_Red}Unsupport${Font_Suffix}\n";
        return;
    fi
    
    if [[ "$result" == *"releaseYear"* ]];then
        echo -n -e "\r DisneyPlus:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n";
        return;
    fi
    
    echo -n -e "\r DisneyPlus:\t\t\t\t${Font_Red}No${Font_Suffix}\n";
    return;
}

function MediaUnlockTest() {
	IPInfo ${1};
	echo ""
	echo " -- Media --";
    MediaUnlockTest_HBONow ${1};
    MediaUnlockTest_BahamutAnime ${1};
    MediaUnlockTest_AbemaTV_IPTest ${1};
    MediaUnlockTest_BBC ${1};
    MediaUnlockTest_BilibiliChinaMainland ${1};
    MediaUnlockTest_BilibiliHKMCTW ${1};
    MediaUnlockTest_BilibiliTW ${1};
    MediaUnlockTest_Netflix ${1};
    MediaUnlockTest_YouTube_Region ${1};
    MediaUnlockTest_DisneyPlus ${1};
	MediaUnlockTest_DAZN ${1};
	MediaUnlockTest_ABC ${1};
	
	echo ""
	echo " -- Game --"
    GameTest_Steam ${1};
	GameTest_PCRJP ${1};
}

function IPInfo() {
	echo -e -n " IP:\t\t\t\t\t->\c";
	local result=`curl -${1} -fsSL https://api.ip.sb/geoip 2>&1`;
	local ip=`echo ${result} | jq .ip | sed 's/"//g' 2>&1`;
	local country=`echo ${result} | jq .country_code | sed 's/"//g' 2>&1`;
	echo -e -n "\r IP:\t\t\t\t\t${Font_Green}${ip}(Country: ${country})${Font_Suffix}\n";
}

curl -V > /dev/null 2>&1;
if [ $? -ne 0 ];then
    echo -e "${Font_Red}请先安装curl${Font_Suffix}";
    exit;
fi

jq -V > /dev/null 2>&1;
if [ $? -ne 0 ];then
    InstallJQ;
fi

echo "";

echo "- IPV4 -";
check4=`ping 1.1.1.1 -c 1 2>&1`;
if [[ "$check4" != *"unreachable"* ]] && [[ "$check4" != *"Unreachable"* ]];then
    MediaUnlockTest 4;
else
    echo -e "${Font_SkyBlue}当前主机不支持IPv4,跳过...${Font_Suffix}";
fi

echo ""

echo "- IPV6 -";
check6=`ping6 240c::6666 -c 1 2>&1`;
if [[ "$check6" != *"unreachable"* ]] && [[ "$check6" != *"Unreachable"* ]];then
    MediaUnlockTest 6;
else
    echo -e "${Font_SkyBlue}当前主机不支持IPv6,跳过...${Font_Suffix}";
fi
