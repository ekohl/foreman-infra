type users::ssh_authorized_key = Struct[{
    type              => String[1],
    key               => String[1],
    Optional[comment] => String[1],
}]
