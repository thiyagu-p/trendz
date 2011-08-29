class FoQuote < ActiveRecord::Base
  belongs_to :stock

  module ExpirySeries
    CURRENT = 'current'
    NEXT = 'next'
    FAR = 'far'
    UNKNOWN = 'unknown'
  end

end
