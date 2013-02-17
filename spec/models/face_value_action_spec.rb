require 'spec_helper'

describe FaceValueAction do

  it 'should calculate conversion ration' do
    FaceValueAction.new(from: 1, to: 10).conversion_ration.should == 10
    FaceValueAction.new(from: 10, to: 2).conversion_ration.should == 0.2
    FaceValueAction.new(from: 10, to: 5).conversion_ration.should == 0.5
    FaceValueAction.new(from: 3, to: 1).conversion_ration.should == 0.33
  end
end