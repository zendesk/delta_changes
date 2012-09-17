require "spec_helper"

describe DirtyDelta do
  it "has a VERSION" do
    DirtyDelta::VERSION.should =~ /^[\.\da-z]+$/
  end
end
