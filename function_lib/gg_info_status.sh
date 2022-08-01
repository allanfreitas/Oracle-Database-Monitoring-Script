gg_info_status() {
    local gghome=$1
    local dbhome=$2
    local __resultvar=$3
    if [ -z "$gghome" ]; then
        gghome=$OGG_HOME
    fi
    export LD_LIBRARY_PATH=$dbhome/lib
    local ggouput=$(${gghome}/ggsci << EOFgg
info all
exit
EOFgg
)
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$ggouput'"
    else
        echo "$ggouput"
    fi
}