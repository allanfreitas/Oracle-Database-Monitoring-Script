# usage `dummy_func result; echo $result; result2=$(dummy_func); echo $result2`
# reference https://www.linuxjournal.com/content/return-values-bash-functions
function dummy_func()
{
    local  __resultvar=$1
    local  myresult='some value'
    if [[ "$__resultvar" ]]; then
        eval "$__resultvar"="'$myresult'"
    else
        echo "$myresult"
    fi
}
