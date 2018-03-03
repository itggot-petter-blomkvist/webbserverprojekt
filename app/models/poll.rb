class Poll < DataMapper
    table_name  :polls
    primary_key :id
    property    :name
    property    :slug
    property    :creation_date
    property    :security_level
    association :voters,        :User,    :id => {[:votes, :poll_id, :user_id] => :id}

end