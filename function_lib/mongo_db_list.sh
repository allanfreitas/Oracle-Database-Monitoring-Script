mongo_db_list() {
    local mongohome=$1
    local __resultvar=$2
    if [ -z "$mongohome" ]; then
        mongohome=$MONGO_HOME
    fi
    local mongoresult=$(${mongohome}/mongo << EOFgg
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