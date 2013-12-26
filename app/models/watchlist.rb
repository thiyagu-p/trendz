class Watchlist < ActiveRecord::Base
  has_and_belongs_to_many :stocks, autosave: true

  validates_presence_of :name

end
