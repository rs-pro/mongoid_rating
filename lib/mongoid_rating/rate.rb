module Mongoid::Rating
  class Rate
    include Mongoid::Document
    include Mongoid::Timestamps::Short
    
    embedded_in :rateable, polymorphic: true
    belongs_to :rater, polymorphic: true, inverse_of: nil

    # rate can be integer or float so we don't force class here
    field :value
  end
end

