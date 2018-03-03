class User < DataMapper
    table_name  :users
    primary_key :id
    property    :name
    property    :email
    encrypted   :password
    property    :registration_date
    association :follows,     :Poll,  :id => {[:follow, :user_id, :poll_id] => :id}

    def self.register(username, email, password1, password2)
        username_error, password_error, email_error = nil
        if username.length <3 || username.length > 32
            username_error = :length
        elsif !(username =~ /^[A-Za-z0-9]+(?:[_-][A-Za-z0-9]+)*$/)
            username_error = :valid
        end
        if password1.length < 6 || password1.length > 32
            password_error = :length
        elsif password1 != password2
            password_error = :match
        end
        if !(email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
            email_error = :valid
        end
        if !username_error && !password_error && !email_error
            if ( properties = User.has_look_alike( name: username, email: email ) )
                if properties.include? :email
                    email_error = :exists
                end
                if properties.include? :name
                    username_error = :exists
                end
                return username_error, password_error, email_error
            else
                return User.create( username, email, Time.now.strftime("%d/%m/%Y %H:%M"), password1 )
            end
        else
            return username_error, password_error, email_error
        end
    end
end