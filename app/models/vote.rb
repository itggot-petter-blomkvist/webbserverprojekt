class Vote < DataMapper
    table_name :votes
    primary_key :id
    property :poll_id
    property :user_id
    property :option_id
    property :date
    encrypted :ip
end