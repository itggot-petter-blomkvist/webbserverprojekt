class App < Sinatra::Base
    get '/' do
        redirect '/login'
    end

    get '/login' do
        slim :login
    end

    get '/register' do
        slim :register
    end

    post '/register' do
        result = User.register(params['username'], params['email'], params['password1'], params['password2'])
        if result.is_a? User
            session[:user_id] = result.id
            redirect '/'
        end
        @username_error, @password_error, @email_error = result
        slim :register
    end
end