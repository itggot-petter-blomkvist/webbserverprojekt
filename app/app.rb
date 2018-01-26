class App < Sinatra::Base
    configure do
        enable :sessions
    end

    before do
        @title="Pollare v1"
        @logged_in = session[:username] != nil
    end

    get '/' do
        if !@logged_in
            redirect '/login'
        else
            redirect '/member'
        end
    end

    get '/member' do
        puts @logged_in
        if !@logged_in
            redirect '/login'
        end
        slim :member
    end

    get '/register' do
        slim :register
    end

    post '/register' do
        if !(@result = User.register(params["username"], params["email"], params["password"], params["password_conf"])).is_a? User
            @username_error = @result.invalid_username        ? "Username should only contain numbers, letters aswell as the special characters _ and -" : 
                              @result.invalid_username_length ? "Username should only be 5-16 letters long" : 
                              @result.username_in_use         ? "Username is already in use" : nil
            @email_error    = @result.invalid_email           ? "Please enter a valid email address" : 
                              @result.email_in_use            ? "Email is already in use" : nil
            @password_error = @result.no_password_match       ? "Passwords do not match" : nil
        else
            session[:username] = @result.name
            redirect '/member'
        end
        slim :register
    end

    get '/login' do
        slim :login
    end

    post '/login' do
        if !(@result = User.login(params['email_or_password'], params['password'])).is_a? User
            @username_error = @result.bad_email_or_username   ? "User does not exist" : nil
            @password_error = @result.bad_password            ? "Wrong password" : nil
        else
            session[:username] = @result.name
            redirect '/member'
        end
        slim :login
    end
end