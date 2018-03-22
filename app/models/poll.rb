class Poll < DataMapper
    table_name  :polls
    primary_key :id
    property    :owner_id
    property    :name
    property    :security_level
    property    :slug
    association :votes, :Vote, :id => :poll_id
    association :options, :Option, :id => :poll_id

    def self.set_allow_anonymous(status)
        @allow_anonymous = status
    end

    def self.allow_anonymous?
        return @allow_anonymous ? true : false
    end

    def get_stats
        stats = {}
        votes.each do |v|
            options.each do |o|
                if o.id == v.option_id
                    stats[o] ||= 0
                    stats[o] += 1
                end
            end
        end
        stats
    end

    def add_option(name)
        Option.create(id, name)
    end

    def self.create(name, security_level, options, user)
        options_error, name_error, security_level_error, permission_error = nil
        if user != nil || @allow_anonymous
            if name == ""
                name_error = :none
            elsif name.length > 100 
                name_error = :length
            end
            options = options.select { |o| o != "" }
            if options.length < 2
                options_error = :short
            elsif options.length > 20
                options_error = :long
            end
            if security_level == 0
                security_level_error = :none
            elsif security_level > 3 || security_level <= 1
                security_level_error = :unrecognized
            end
            if (!options_error && !name_error && !security_level_error)
                slug = Poll.generate_slug
                poll = super(user.id, name, security_level, slug)
                options.each do |o|
                    poll.add_option(o)
                end
                return poll
            end
        else
            permission_error = :logged_in
        end
        return options_error, name_error, security_level_error, permission_error
    end

    def add_vote(ip, user, option_id)
        @vote_error = nil
        @option_error = nil
        case security_level
        when 2
            if votes.any? { |v| v.public_ip == ip }
                @vote_error = :duplicate
            end
        when 3
            if votes.any? { |v| v.user_id == user.id }
                @vote_error = :duplicate
            end
        end
        if !@vote_error
            if options.any? { |o| o.id == option_id }
                return Vote.create(id, security_level == 3 ? user.id : 0, option_id, Time.now.strftime("%d/%m/%Y %H:%M"), ip);
            else
                @option_error = :invalid
            end
        end
        return @vote_error, @option_error
    end

    def self.generate_slug
        slug = ""
        polls = all
        drinks = ['Cola', 'Redbull', 'Monster', 'Coffee', 'Tea', 'Fanta', 'Milk', 'Pepsi', 'RootBeer', 'Sprite', 'Orangina']
        until (!polls.any? { |p| p.slug == slug }) && (slug != "")
            slug = (0...6).map { drinks[rand(drinks.length)] }.join
        end
        return slug
    end

end