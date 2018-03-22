class Option < DataMapper
    table_name :options
    primary_key :id
    property :poll_id
    property :name
end