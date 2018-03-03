class App < Sinatra::Base
    get '/' do
        u = User.get( 21 ) {{ preload: [:polls] }}
        p u.polls[0]
        p DataMapper.requests_done

        redirect '/login'
    end

    get '/login' do
        slim :login
    end

    get '/register' do
        slim :register
    end
end