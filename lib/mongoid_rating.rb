require "mongoid_rating/version"
require 'mongoid_rating/rate'
require 'mongoid_rating/model'

Mongoid::Document.send :include, Mongoid::Rating::Model

