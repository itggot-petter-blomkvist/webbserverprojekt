class DataMapper
    # Get the amount of sql-requests executed by the datamapper
    # @return [Integer] the number of sql-requests done
    def self.requests_done
        @@requests_done ||= 0
    end
    # Add 1 requests to the amount of sql-requests done by the datamapper
    # @return [Integer] the number of sql-requests done
    def self.count_request
        @@requests_done ||= 0
        @@requests_done += 1
    end
    # Set the database in use by the datamapper
    # @return [SQLite3::Database] an instance of the database
    def self.database=( database )
        @@database = SQLite3::Database.open database
    end
    # Get the database instance in use by this datamapper
    # @return [SQLite3::Database] an instance of the database in use
    def self.database()
        @@database
    end
    # Set the table of the database object
    # @return [Symbol] The table name
    def self.table_name( n )
        @table_name_attr = n
    end
    # Set the primary key of the database object
    # @param key [Symbol] The primary key column as a symbol
    # @return [Symbol] The primary key column
    def self.primary_key( key )
        @primary_key_attr = key
    end
    # Add a property to a derived database object
    # @param p [Symbol] The property column to add
    # @return [Array] all the properties
    def self.property( p )
        @properties ||= []
        @properties.push( p )
    end
    # Add an encrypted property to a derived database object
    # @param p [Symbol] The encrypted property to add (as a symbol)
    # @return [Array] all the encrypted properties
    def self.encrypted( p )
        self.property(p)
        @encrypted_properties ||= []
        @encrypted_properties.push( p )
    end
    # Set up an association to another database object
    # @param p [Symbol] The name of the association
    # @param clazz [Symbol] The class of the associated database object
    # @param relation [Hash] The relation to use for fetching the associated object
    # @return [Hash] A hash with all associations
    def self.association( p, clazz, relation )
        @associations ||= Hash.new
        @associations[p] = [clazz, relation.keys[0], relation[relation.keys[0]]]
    end
    # Get the amount of columns in use by this database object
    # @return [Integer] The number columns in use by this database object
    def self.column_amount
        return 1 + @properties.length
    end
    # Ask database object if it contains any object with ALL of the passed values
    # @param where [Hash] A hash containing the wanted values
    # @return [Boolean] True if the database object has any object containing all of the passed values
    def self.has( where )
        get(where).length > 0
    end
    # Ask the database object if it contain any objects containing ANY of the passed values
    # @param where [Hash] A hash containing the wanted values
    # @return [Array] The properties that already exist, nil if none of them exists.
    def self.has_look_alike( where )
        look_alikes = get( where ) {{ :where_method => :or }}
        look_alike_properties = nil
        look_alikes.each do |e|
            @properties.each do |p|
                v = e.method_missing(p)
                if v == where[p]
                    look_alike_properties ||= []
                    if !look_alike_properties.include? p
                        look_alike_properties.push(p)
                    end
                end
            end
        end
        look_alike_properties
    end
    # Get all the objects in the table
    # @param block [Block] An optional block containing options for the requests
    # @return [Array] All the objects in the table
    def self.all(&block)
        self.get( nil, &block )
    end
    # Get all the objects in the table with the specified values
    # @param where [Hash] A hash containing all the required values OR an integer representing a primary key OR nil for all
    # @param block [Block] An optional block containing options for the get
    # @return [Array] All the objects that match the criteria
    def self.get( where, &block )
        options = block_given? ? block.call : Hash.new

        if where.is_a? Integer
            return self.get( @primary_key_attr => where, &block ).first
        end

        tests = []
        test_values = []
        where = where ? where : {}
        where.keys.each do |k|
            if where[k].is_a? Hash
                relation_table = where[k].keys[0]
                tests.push("#{k} IN ( SELECT #{relation_table[1]} FROM #{relation_table[0]} WHERE #{relation_table[2]} IS ?)")
                test_values.push(where[k].values[0])
            else
                tests.push("#{k} IS ?")
                test_values.push(where[k])
            end
        end
        from_statement = "FROM #{@table_name_attr}"
        where_statement = ""
        where_method = :and
        if options.has_key? :where_method
            where_method = options[:where_method]
        end
        case where_method
        when :or
            where_statement = tests.length > 0 ? where_statement = "WHERE #{@table_name_attr}.#{tests.join(" OR #{@table_name_attr}.")}" : ""
        when :and
            where_statement = tests.length > 0 ? where_statement = "WHERE #{@table_name_attr}.#{tests.join(" AND #{@table_name_attr}.")}" : ""
        end
        select_statement = "SELECT *"
        join_statement = ""
        if options.has_key? :preload
            select_statement = "SELECT #{@table_name_attr}.* "
            options[:preload].each do |a|
                a_table_name = eval(@associations[a][0].to_s).table_name_attr
                select_statement += ", #{a_table_name}.*"
                join_statement += " LEFT JOIN #{a_table_name} ON #{@table_name_attr}.#{@associations[a][1]} ="
                if (hash = @associations[a][2]).is_a? Hash
                    property = hash.values[0]
                    array = hash.keys[0]
                    join_statement += "( SELECT #{array[1]} FROM #{array[0]} WHERE #{array[2]} IS #{a_table_name}.#{property} )"
                else
                    join_statement += " #{a_table_name}.#{@associations[a][2]}"
                end
            end
        end
        puts "Getting: #{select_statement} #{from_statement} #{join_statement} #{where_statement}"
        puts test_values
        data = database.execute( "#{select_statement} #{from_statement} #{join_statement} #{where_statement}",  test_values)
        count_request
        if options.has_key? :preload
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
    # Create a new object and insert it into a row
    # @param cols [Array] The values of all the columns
    # @return The added object
    def self.create( *cols )
        @encrypted_properties ||= []
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
    # Update a specific row with modifications
    # @param modifications [Hash] The columns to change and the values to change to
    # @param where [Hash] A hash identifying which rows to change
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

    # Initialize a new object from column values and preloaded properties
    # @param cols [Array] The column values
    # @param preloads [Hash] Optional preloaded associations
    # @return The initialized object
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
    # Modify values in the user
    # @param modifications [Hash] A hash containing the modifications
    def modify(modifications)
        self.class.modify(modifications, {self.class.primary_key_attr => @data[self.class.primary_key_attr]})
    end
    # The method handling all of the property access
    # @param method [Symbol] The missing method (usually a property or association)
    # @param args [Array] The method arguments (used when modifying properties)
    def method_missing(method, *args)
        encrypted = self.class.encrypted_properties ? self.class.encrypted_properties : []
        associations = self.class.associations ? self.class.associations : Hash.new
        if @data.has_key?(method)
            if encrypted.include? method
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