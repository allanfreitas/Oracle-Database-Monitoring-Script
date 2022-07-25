gg_info_status() {
    local gghome =$1
    local __resultvar=$2
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