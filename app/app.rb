class App < Sinatra::Base
    enable :sessions

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