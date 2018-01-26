class Database
    @@database_file = ""

    def self.set_database_file(file)
        begin
            @@database_file = file
        rescue => error
            puts error.message
            puts "Couldn't set database file, database operations will result in error."
        end
    end

    def self.open_connection
        if @@database_file != ""
            return SQLite3::Database.open @@database_file
        else
            puts "No database file defined!"
        end
    end
end