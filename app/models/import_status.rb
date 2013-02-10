class ImportStatus < ActiveRecord::Base
  attr_accessible :data_upto, :succeeded, :last_run, :source

  module Source
    BSEBHAV = 'bse_bhav'
  end

end
