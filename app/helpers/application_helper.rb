module ApplicationHelper

  def display_returns(value)
    "<span class=\"#{value.to_f < 0 ? 'red' :'green'}\">#{number_to_percentage value.to_f, precision: 2}</span>"
  end
end
