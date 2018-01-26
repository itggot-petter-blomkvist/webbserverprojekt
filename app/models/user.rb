class User    
    attr_reader :id, :name, :email, :password

    def initialize(data)
        @id = data[0]
        @name = data[1]
        @email = data[2]
        @password = BCrypt::Password.new(data[3])
    end

    def self.get(email_or_username)
        db = Database.open_connection
        data = db.execute("SELECT * FROM users WHERE name LIKE ? OR email LIKE ?", email_or_username, email_or_username).first
        if data
            return User.new(data)
        else
            return nil
        end
    end

    def self.register(username, email, password, password_conf)
        db = Database.open_connection

        errorObj = OpenStruct.new
        errorObj.no_password_match = password != password_conf
        errorObj.invalid_email = !email.match("^[A-Za-z0-9.]+@[A-Za-z0-9.]+$")
        errorObj.invalid_username = !username.match("^[a-zA-Z0-9\\-_]+$")
        errorObj.invalid_username_length = !(username.length >= 5 && username.length <= 16)
        if errorObj.no_password_match || errorObj.invalid_email || errorObj.invalid_username || errorObj.invalid_username_length
            return errorObj 
        end

        errorObj.email_in_use = db.execute("SELECT * FROM users WHERE email LIKE ?", email).first
        errorObj.username_in_use = db.execute("SELECT * FROM users WHERE name LIKE ?", username).first
        if errorObj.email_in_use || errorObj.username_in_use
            return errorObj
        end

        db.execute("INSERT INTO users (name, email, password) VALUES (?, ?, ?)", username, email, BCrypt::Password.create(password));

        return self.get(username)
    end

    def self.login(email_or_username, password)
        user = User.get(email_or_username)
        errorObj = OpenStruct.new
        errorObj.bad_email_or_username = user == nil
        if errorObj.bad_email_or_username
            return errorObj
        end
        errorObj.bad_password = user.password != password
        if errorObj.bad_password 
            return errorObj
        end
        return user
    end

end