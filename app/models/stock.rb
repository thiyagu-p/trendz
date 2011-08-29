class Stock < ActiveRecord::Base

  module Series
    EQUITY = 'e'
    INDEX = 'i'
  end

end
