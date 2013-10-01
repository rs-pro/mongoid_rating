class Article
  include Mongoid::Document

  field :name

  rateable :overall, range: -5..5, eval: false
end
