class User    
    attr_reader :id, :name, :email, :password

    def initialize(data)
        @id = data[0]
        @name = data[1]
        @email = data[2]
        @password = data[3]
    end

    def self.get(name)
        return User.new(settings.db.execute("SELECT * FROM users WHERE name IS UPPER(?)", name))
    end

    def self.register(username, email, password, password_conf)
        SQLite3::Database.open "./db/database.sqlite"

        errorObj = OpenStruct.new
        errorObj.no_password_match = password != password_conf
        errorObj.invalid_email = !email.match("^[A-Za-z0-9.]+@[A-Za-z0-9.]+$")
        errorObj.invalid_username = !username.match("^[a-zA-Z0-9\\-_]+$")
        errorObj.invalid_username_length = !(username.length >= 5 && username.length <= 16)
        if errorObj.no_password_match || errorObj.invalid_email || errorObj.invalid_username || errorObj.invalid_username_length
            return errorObj 
        end

        if !db.execute("SELECT * FROM users WHERE name LIKE ?", username).first
         db.execute("INSERT INTO users (name, email, password) VALUES (?, ?, ?)", username, email, password);
        end

        return nil
    end

end