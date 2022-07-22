gg_info_status() {
    local gghome=$1
    local ggouput=$(gghome/ggsci << EOFgg
info all
exit
EOFgg
)
}