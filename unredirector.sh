#!/bin/bash
  
function unredirector {
    headers=$(curl --fail --connect-timeout 20 --location -sS --head "$url")
    code=$(echo "$headers" | head -1 | awk '{print $2}')
    
    #check for null as well
    if [ -z "$code" ];then
        echo "[info] Web page is gone!" >&2;
    else
        if echo "$code" | grep -q -e "3[0-9][0-9]";then
            echo "[info] HTTP $code redirect" >&2;      
            resulturl=""
            resulturl=$(wget -O- --server-response "$url" 2>&1 | grep "^Location" | tail -1 | awk -F ' ' '{print $2}')
            if [ -z "$resulturl" ]; then
                echo "[info] No new location found" >&2;
                resulturl=$(echo "$url")
            else
                echo "[info] New location found" >&2;
                url=$(echo "$resulturl")
                echo "[info] REprocessing $url" >&2;
                headers=$(curl --connect-timeout 20 --location -sS --head "$url")
                code=$(echo "$headers" | head -1 | awk '{print $2}')
                if echo "$code" | grep -q -e "3[0-9][0-9]";then
                    echo "[info] Second redirect; passing as-is" >&2;
                fi
            fi
        fi
        if echo "$code" | grep -q -e "2[0-9][0-9]";then
            echo "[info] HTTP $code exists" >&2;
        fi
    fi
}
