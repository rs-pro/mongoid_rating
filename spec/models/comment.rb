class Comment
  include Mongoid::Document

  rateable :rate, eval: false

  embedded_in :post

  field :content
end
