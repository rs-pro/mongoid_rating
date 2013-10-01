# MongoidRating

Star rating for Mongoid
Allows:
  - Multiple rating fields per model
  - Float rating marks (users can give 4.5 stars)
  - Accurate concurrent rating updates with db.eval

## Installation

Add this line to your application's Gemfile:

    gem 'mongoid_rating'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid_rating

## Usage

make model rateable:
  class Post
    include Mongoid::Document
    rateable :rate
  end
  ps = Post.create()
  user = User.create()

rate and unrate:
  
  ps.rate 5, user
  ps.unrate, user

Get current rating

  ps.rate
   => 5.0 
  ps.rate_by(user)
  => 5 
  
Check if user rated:

  ps.rate_by?(user)
  => true 

Scopes: 

  Post.rate_in(2..5)
  Post.rate_in(2..5).first
  => #<Post rate_count: 1, rate_sum: 5.0, rate_average: 5.0> 
  Post.rate_in(2..3).first
  => nil 

Posts rated by user:

  Post.rate_by(user).first
  => #<Post rate_count: 1, rate_sum: 5.0, rate_average: 5.0> 

## Credits

(c) 2013 glebtv, MIT license

Partially based on
(mongoid-rateable)[https://github.com/proton/mongoid_rateable]
which is Copyright (c) 2011 Peter Savichev (proton), MIT license

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

