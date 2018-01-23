class App < Sinatra::Base

    before do
        @title="Pollare v1"
    end

    get '/' do
        'Welcome to pollare!'
        slim(:login)
    end

end