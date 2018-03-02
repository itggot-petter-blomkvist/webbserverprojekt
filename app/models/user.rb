class User < DataMapper
    table_name  :users
    primary_key :id
    property    :name
    property    :email
    encrypted   :password

    association :polls, :Poll, :id => {[:votes, :user_id, :poll_id] => :id}

    def self.register(username, email, password1, password2)

    end
end