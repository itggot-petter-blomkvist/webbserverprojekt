class DataMapper
    # Public: Get the amount of sql-requests executed by the datamapper
    #
    # Examples
    #   
    #   DataMapper.requests_done
    #   # => 5
    #
    # Returns the sql-requests done
    def self.requests_done
        @@requests_done ||= 0
    end
    # Public: Add 1 requests to the amount of sql-requests done by the datamapper
    #
    # Examples
    #
    #   DataMapper.count_request
    #   # => 6
    #
    # Returns the sql-requests done
    def self.count_request
        @@requests_done ||= 0
        @@requests_done += 1
    end
    # Public: Set the database in use by the datamapper
    #
    # database - A path to the database
    #
    # Examples
    #
    #   DataMapper.database = "./databases/database.sqlite"
    #   # => SQLite3::Database
    #
    # Returns an instance of the database
    def self.database=( database )
        @@database = SQLite3::Database.open database
    end
    # Public: Get the database instance in use by this datamapper
    #
    # Examples
    #
    #   DataMapper.database
    #   # => SQLite3::Database
    #
    # Returns an instance of the database in use
    def self.database()
        @@database
    end
    # Public: Set the table of a derived database object
    #
    # n - A symbol representation of the name to use
    #
    # Examples
    #
    #   table_name :users
    #   # => :users
    #
    # Returns the table name
    def self.table_name( n )
        @table_name_attr = n
    end
    # Public: Set the primary key of a derived database object
    #
    # key - The primary key column as a symbol
    #
    # Examples
    #
    #   primary_key :id
    #   # => :id
    #
    # Returns the primary key column
    def self.primary_key( key )
        @primary_key_attr = key
    end
    # Public: Add a property to a derived database object
    #
    # p - The property column to add as a symbol
    #
    # Examples
    #
    #   property :name
    #   # => [:name, :email]
    #
    # Returns all the properties
    def self.property( p )
        @properties ||= []
        @properties.push( p )
    end
    # Public: Add an encrypted property to a derived database object
    #
    # p - The encrypted property to add (as a symbol)
    #
    # Examples
    #
    #   encrypted :password
    #   # => [:password]
    #
    # Returns all the encrypted properties
    def self.encrypted( p )
        self.property(p)
        @encrypted_properties ||= []
        @encrypted_properties.push( p )
    end
    # Public: Set up an association to another database object
    #
    # p - A member name to use for the association
    # clazz - The class of the associated database object !Represented as a symbol!
    # relation - The relation to use for fetching the associated object
    #
    # Examples
    #
    #   associated :posts, :post, :id => :user_id
    #   # => {:posts => [:post, :id, :user_id]}
    #
    # Returns a hash with all associations
    def self.association( p, clazz, relation )
        @associations ||= Hash.new
        @associations[p] = [clazz, relation.keys[0], relation[relation.keys[0]]]
    end
    # Public: Get the amount of columns in use by this database object
    #
    # Examples
    #   User.column_amount
    #   # => 5
    #
    # Returns the number columns in use by this database object
    def self.column_amount
        #The one is the primary key.
        return 1 + @properties.length
    end
    def self.has( where )
        get(where).length > 0
    end
    def self.has_look_alike( where )
        where.keys.each do |k|
            if has( k => where[k] )
                return true
            end
        end
        false
    end
    def self.all()
        self.get( nil )
    end
    def self.get( where )
        options = nil
        if block_given?
            options = yield
        else
            options = Hash.new
        end

        if where.is_a? Integer
            return self.get( @primary_key_attr => where ).first
        end

        tests = []
        test_values = []
        if where
            where.keys.each do |k|
                p where[k].class
                p where[k]
                if where[k].is_a? Hash #Many to many
                    relation_table = where[k].keys[0]
                    value = where[k].values[0]
                    tests.push("#{k} IN ( SELECT #{relation_table[1]} FROM #{relation_table[0]} WHERE #{relation_table[2]} IS ?)")
                    p where[k]
                    test_values.push(where[k].values[0])
                else
                    tests.push("#{k} IS ?")
                    test_values.push(where[k])
                end
            end
        end
        select_statement = "SELECT *"
        from_statement = "FROM #{@table_name_attr}"
        join_statement = ""
        where_statement = ""
        if where
            where_statement = "WHERE #{@table_name_attr}.#{tests.join(" AND #{@table_name_attr}.")}"
        end

        if options.has_key? :preload
            select_statement = "SELECT #{@table_name_attr}.* "
            options[:preload].each do |a|
                a_table_name = eval(@associations[a][0].to_s).table_name_attr

                select_statement += ", #{a_table_name}.*"
                join_statement += " LEFT JOIN #{a_table_name} ON #{@table_name_attr}.#{@associations[a][1]} = #{a_table_name}.#{@associations[a][2]}"
            end
        end
        p "#{select_statement} #{from_statement} #{join_statement} #{where_statement}"
        data = database.execute( "#{select_statement} #{from_statement} #{join_statement} #{where_statement}",  test_values)
        count_request
        if options.has_key? :preload # This is only going to be one object... Thank god. For now.
            object_preloads = Hash.new 
            objects = []

            data.each do |row|
                obj_id = row[0]
                if !object_preloads.has_key? obj_id
                    object_preloads[obj_id] = Hash.new
                    objects.push(row[0..column_amount-1])
                end
                column_offset = column_amount
                options[:preload].each do |a|
                    clazz = eval(@associations[a][0].to_s)
                    object_preloads[obj_id][a] ||= []
                    if(row[column_offset])
                        if !object_preloads[obj_id][a].any? {|c| c.id == row[column_offset]}
                            object_preloads[obj_id][a].push( clazz.new(row[column_offset..column_offset+clazz.column_amount-1]) )
                        end
                    end
                    column_offset += clazz.column_amount
                end
            end
            objects.map { |o| new(o, preloads: object_preloads[o[0]]) }
        else
            data.map { |d| new(d) }
        end
    end



    def self.create( *cols )
        encrypted = []
        @properties.each_with_index do |p, i|
            if @encrypted_properties.include? p
                encrypted.push(i)
            end
        end
        encrypted.each do |i|
            cols[i] = BCrypt::Password.create(cols[i])
        end
        database.execute( "INSERT INTO #{@table_name_attr} (#{ @properties.join(",") }) VALUES (#{ ("?" * cols.length) .split("") .join(",") })", cols )
        count_request
        new(database.execute( "SELECT * FROM #{@table_name_attr} WHERE #{@primary_key_attr} IS last_insert_rowid()" ).first)
    end
    def self.modify( modifications, where )
        update_statement = "UPDATE #{@table_name_attr}"
        set_statement = "SET "
        cols = []
        modifications.keys.each do |k|
            if @encrypted_properties.include? k
                if(!modifications[k].is_a? BCrypt::Password)
                    cols.push(BCrypt::Password.create(modifications[k]))
                else
                    cols.push(modifications[k])
                end
            else
                cols.push(modifications[k])
            end
            set_statement += "#{k} = ?,"
        end
        where_statement = "WHERE "
        where.keys.each do |k|
            where_statement += "#{k} = ?,"
            cols.push(where[k])
        end
        where_statement = where_statement[0..-2]
        set_statement = set_statement[0..-2]
        count_request
        database.execute("#{update_statement} #{set_statement} #{where_statement}", cols)
    end
    class << self
        attr_reader :properties, :primary_key_attr, :table_name_attr, :associations, :encrypted_properties
    end

    def initialize( cols, preloads = Hash.new )
        @data = Hash.new
        @data[self.class.primary_key_attr] = cols [0]
        self.class.properties.each_with_index do |p, i|
            @data[p] = cols [i+1]
        end
        if(preloads.has_key? :preloads)
            if(preloads[:preloads])
                preloads[:preloads].keys.each do |k|
                    @data[k] = preloads[:preloads][k]
                end
            end
        end
    end
    def modify(modifications)
        self.class.modify(modifications, {self.class.primary_key_attr => @data[self.class.primary_key_attr]})
    end
    def method_missing(method, *args)
        encrypted = self.class.encrypted_properties ? self.class.encrypted_properties : []
        associations = self.class.associations ? self.class.associations : Hash.new
        if @data.has_key?(method)
            if self.class.encrypted_properties.include? method
                BCrypt::Password.new(@data[method])
            else
                @data[method]
            end
        elsif @data.has_key?("#{method}".gsub("=", "").to_sym)
            variable = "#{method}".gsub("=", "").to_sym
            value = args[0]
            if encrypted.include? variable
                value = BCrypt::Password.create(args[0])
            end
            @data[variable] = value
            modify({variable => value})
        elsif associations.has_key? method
            association = self.class.associations[method]
            # Note: I use eval because the relationship is defined with a symbol to allow for back and forth relationships. (I don't want to forward declare :P)
            if association[2].is_a? Hash
                association_hash = association[2]
                relationship_array = [association_hash.keys[0][0], association_hash.keys[0][2], association_hash.keys[0][1]]
                association_local_property = association[1]
                association_property = association_hash.values[0]
                #p {association_property => {relationship_array => @data[association_local_property]}}
                @data[method] = eval(association[0].to_s).get( association_property => {relationship_array => @data[association_local_property]} )
            else
                @data[method] = eval(association[0].to_s).get( association[2] => @data[association[1]] )
            end
        end
    end
end