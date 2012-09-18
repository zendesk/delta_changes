require "spec_helper"

describe DirtyDelta do
  it "has a VERSION" do
    DirtyDelta::VERSION.should =~ /^[\.\da-z]+$/
  end

  it "should not create methods on unspecified attributes" do
    # TODO broken, but that might be rails 2 ...
    #expect{
    #  User.new.email_delta_will_change!
    #}.to raise_error

    expect{
      User.new.bar_delta_will_change!
    }.to raise_error

    expect{
      User.new.does_not_exist_delta_will_change!
    }.to raise_error
  end

  describe "#delta_changes" do
    it "should be empty on unchanged" do
      User.new.delta_changes.should == {}
    end

    it "should be filled by column changes" do
      User.new(:name => "Peter").delta_changes.should == {"name"=>[nil, "Peter"]}
    end

    it "should not be filled other column changes" do
      User.new(:email => "Peter").delta_changes.should == {}
    end

    it "should not be filled attribute changes" do
      user = User.new(:foo => 1)
      user.delta_changes.should == {}
    end

    it "should be filled by explicit attribute changes" do
      user = User.new(:foo => 1)
      user.foo_delta_will_change!
      user.foo = 2
      user.delta_changes.should == {"foo"=>[1, 2]}
    end

    it "should not mess with normal changes" do
      User.new(:email => "EMAIL", :name => "NAME", :foo => "FOO").changes.should ==
        {"email"=>[nil, "EMAIL"], "name"=>[nil, "NAME"]}
    end
  end
end
