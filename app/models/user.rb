class User < DataMapper
    table_name  :users
    primary_key :id
    property    :name
    property    :email
    encrypted   :password
end