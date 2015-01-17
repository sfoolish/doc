virsh capabilities|grep model|awk '/<model/{print gensub(/<([^>]+)>([^<]+)<\/.*/,"\\2",1)}'|awk -F " " '{print $1}'|sed -n '1p' > /root/cpu_model
