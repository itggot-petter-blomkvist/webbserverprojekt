class App < Sinatra::Base
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

end