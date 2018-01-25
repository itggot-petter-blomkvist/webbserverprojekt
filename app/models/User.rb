class User

    attr_reader :id, :name, :email, :password

    def initialize(data)
        @id = data[0]
        @name = data[1]
        @email = data[2]
        @password = data[3]
    end

    def get(name)
        return User.new(App.db.execute("SELECT * FROM users WHERE name IS UPPER(?)", name))
    end

end