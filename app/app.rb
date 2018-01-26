class App < Sinatra::Base
    configure do
    end

    before do
        @title="Pollare v1"
    end

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
        if @error = User.register(params["username"], params["email"], params["password"], params["password_conf"])
            @username_error = @error.invalid_username        ? "Username should only contain numbers, letters aswell as the special characters _ and -" : 
                              @error.invalid_username_length ? "Username should only be 5-16 letters long" : nil
            @email_error    = @error.invalid_email           ? "Please enter a valid email address" : nil
            @password_error = @error.no_password_match       ? "Passwords do not match" : nil
        else
            slim :login
        end
        slim :register
    end
end