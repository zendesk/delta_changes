require "spec_helper"

describe DeltaChanges do
  it "has a VERSION" do
    DeltaChanges::VERSION.should =~ /^[\.\da-z]+$/
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

    it "should be filled by tracked column changes" do
      User.new(:name => "Peter").delta_changes.should == {"name"=>[nil, "Peter"]}
    end

    it "should be filled by tracked number column change" do
      User.new(:score => 5).delta_changes.should == {"score"=>[nil, 5]}
    end

    it "should be filled by tracked number column change that have the wrong type" do
      User.new(:score => "5").delta_changes.should == {"score"=>[nil, 5]}
    end

    it "should not be filled by untracked column changes" do
      User.new(:email => "Peter").delta_changes.should == {}
    end

    it "should not be filled implicit tracked attribute changes" do
      user = User.new(:foo => 1)
      user.delta_changes.should == {}
    end

    it "should be filled by explicit tracked attribute changes" do
      user = User.new(:foo => 1)
      user.foo_delta_will_change!
      user.foo = 2
      user.delta_changes.should == {"foo"=>[1, 2]}
    end

    it "should not mess with normal changes" do
      User.new(:email => "EMAIL", :name => "NAME", :foo => "FOO").changes.should ==
        {"email"=>[nil, "EMAIL"], "name"=>[nil, "NAME"]}
    end

    it "should not track non-changes on tracked columns" do
      user = User.create!(:score => 5).reload
      user.reset_delta_changes

      user.delta_changes.should == {}

      user.score = 5
      user.delta_changes.should == {}

      user.score = "5"
      user.delta_changes.should == {}
    end
  end
end
