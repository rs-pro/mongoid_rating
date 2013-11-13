class Comment
  include Mongoid::Document

  rateable :rate, float: false

  embedded_in :post

  field :content
end
