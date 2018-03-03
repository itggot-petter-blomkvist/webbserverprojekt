require 'sqlite3'

@database = {}

def process_line(line)
    if line.start_with? "table"
        table = line[5..-1].gsub(/[()]/, "")
        @database[table] = []
    end
    if line =~ /(?<!:):(?!:)/
        table, column = line.split(" : ")
        @database[table] ||= []
        @database[table].push(column.split(" "))
    end
end

lines = File.readlines('er_diagram2.puml')
lines.each do |line|
    process_line(line.strip)
end

commands = []
@database.keys.each do |k|
    command = "CREATE TABLE '#{k}' ("
    first = true
    @database[k].each do |c|
        type, name = c
        command += (first ? '' : ',' ) + "'#{name}' #{type.gsub("KEY", "INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE")}"
        first = false
    end
    command += ")"
    commands.push(command)
end

File.delete("./database.sqlite") if File.exist?("./database.sqlite")
db = SQLite3::Database.open('./database.sqlite')

commands.each { |c| puts "Executing command: #{c}"; db.execute(c) }