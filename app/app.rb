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
end