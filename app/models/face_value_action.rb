class FaceValueAction < ActiveRecord::Base
  belongs_to :stock

  def conversion_ration
    (to.to_f/from.to_f).round(2)
  end
end
