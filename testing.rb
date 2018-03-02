p :id => {[:books_users, :user_id, :book_id] => :id}

def get(where)
    where_statement = "WHERE "
    where.keys.each do |k|
        if where[k].is_a? Hash #Many to many
            relation_table = where[k].keys[0]
            value = where[k].values[0]

            s = "#{k} IN ( SELECT #{relation_table[1]} FROM #{relation_table[0]} WHERE #{relation_table[2]} IS #{value})" 
            p where_statement + s
        else #Single

        end
    end
end


association :polls, :Poll, :uid => {[:votes, :user_id, :poll_id] => :pid}


get( :id => {[:books_users, :book_id, :user_id] => 5})