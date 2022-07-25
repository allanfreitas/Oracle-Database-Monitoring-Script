mongo_db_list() {
    local __resultvar=$1
    local mongoresult=$(/usr/local/bin/mongo << EOFgg
show dbs
exit
EOFgg
)
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$mongoresult'"
    else
        echo "$mongoresult"
    fi
}