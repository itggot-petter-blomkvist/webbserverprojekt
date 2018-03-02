class Poll < DataMapper
    table_name  :polls
    primary_key :id
    property    :name
    property    :slug
    property    :creation_date
    property    :security_level


end