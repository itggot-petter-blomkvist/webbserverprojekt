class App < Sinatra::Base
    enable :sessions
    register Sinatra::Flash

    before do 
        @user = nil
        if (id = session[:user_id])
            @user = User.get( id )
        end
    end
    
    get '/' do
        if @user
            redirect '/member'
        else
            redirect '/login'
        end
    end

    get '/polls/create' do
        if (@user) || Poll.allow_anonymous?
            slim :"polls/create"
        else
            flash[:request] = "You must be logged in to access this page."
            redirect :login
        end
    end

    post '/polls/create' do
        @options = params.keys.map { |o| (o.start_with? 'option') ? params[o] : nil }.compact
        @name = params['name']
        @security_level = params['security_level'].to_i
        result = Poll.create(@name, @security_level, @options, @user)
        if result.is_a? Poll
            redirect "polls/#{ result.slug }"
        end
        @options_error, @name_error, @security_level_error, @permission_error = result
        if @permission_error == :logged_in
            flash[:request] = "You must be logged in to create a poll."
            redirect :login
        end
        slim :'polls/create'
    end

    get '/polls/:id' do
        @poll = Poll.get( params['id'].to_i )
        slim :'polls/poll'
    end

    get '/login' do
        slim :login
    end

    get '/register' do      
        slim :register
    end
    
    get '/member' do
        if ( !@user )
            redirect '/'
        end
        slim :member
    end

    get '/logout' do
        session.destroy
        redirect '/login'
    end

    post '/login' do
        result = User.login(params['username'], params['password']) 
        if result.is_a? User
            session[:user_id] = result.id
            redirect '/member'
        end
        @username_error, @password_error = result
        slim :login
    end 

    post '/register' do
        result = User.register(params['username'], params['email'], params['password1'], params['password2'])
        if result.is_a? User
            session[:user_id] = result.id
            redirect '/member'
        end
        @username_error, @password_error, @email_error = result
        slim :register
    end
end