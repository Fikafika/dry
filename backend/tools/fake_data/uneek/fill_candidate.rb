#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

@uneek = Dynamic::Schema.where(name: 'Uneek').first
raise @uneek.errors.inspect if @uneek.errors.any?

@uneek.load

# create 500 candidates:
def candidate_attr(i)

    if i <= 200
      j = 3
    elsif i > 200 and i <= 300
      j = 1
    else
      j = 2
    end

    hash = {
        first_name: "Mr. toto_#{i}",
        last_name: "du lapinou_#{i}",
        level: j
    }
    return hash
end

@candidate = D::Uneek::Candidate

i = 0
max = 500
while i < max  do
    @candidate.create(candidate_attr(i))
    i +=1
end


puts "finished"
