class Post
  include Mongoid::Document

  field :name, type: String
  
  embeds_many :comments
  rateable :rate
end
