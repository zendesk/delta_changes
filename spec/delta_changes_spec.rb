require 'spec_helper'

describe DeltaChanges do
  it 'has a VERSION' do
    expect(DeltaChanges::VERSION).to match(/^[\.\da-z]+$/)
  end

  it 'should not create methods on unspecified attributes' do
    expect{
      User.new.bar_delta_will_change!
    }.to raise_error(NoMethodError)

    expect{
      User.new.does_not_exist_delta_will_change!
    }.to raise_error(NoMethodError)
  end

  describe '#delta_changes' do
    it 'should be empty on unchanged' do
      changes = User.new.delta_changes
      expect(changes).to eq({})
    end

    it 'should be filled by tracked column changes' do
      changes = User.new(:name => 'Peter').delta_changes
      expect(changes).to eq('name' => [nil, 'Peter'])
    end

    it 'should be filled by tracked number column change' do
      changes = User.new(:score => 5).delta_changes
      expect(changes).to eq('score' => [nil, 5])
    end

    it 'should be filled by tracked number column change that have the wrong type' do
      changes = User.new(:score => '5').delta_changes
      expect(changes).to eq('score' => [nil, 5])
    end

    it 'should not be filled by untracked column changes' do
      changes = User.new(:email => 'Peter').delta_changes
      expect(changes).to eq({})
    end

    it 'should not be filled implicit tracked attribute changes' do
      user = User.new(:foo => 1)
      expect(user.delta_changes).to eq({})
    end

    it 'should not be filled if a nil attribute changes to empty string' do
      user = User.new(:score => '')
      expect(user.delta_changes).to eq({})
    end

    it 'should be filled by explicit tracked attribute changes' do
      user = User.new(:foo => 1)
      user.foo_delta_will_change!
      user.foo = 2
      expect(user.delta_changes).to eq('foo' => [1, 2])
    end

    it 'should not mess with normal changes' do
      changes = User.new(:email => 'EMAIL', :name => 'NAME', :foo => 'FOO').changes
      expect(changes).to eq(
        'email' => [nil, 'EMAIL'],
        'name'  => [nil, 'NAME']
      )
    end

    it 'should not reset columns on save' do
      user = User.create!(:name => 'NAME', :foo => 'FOO', :bar => 'BAR')
      expect(user.delta_changes).to eq('name' => [nil, 'NAME'])
    end

    it 'should not reset columns on update' do
      user = User.create!(:name => 'NAME', :foo => 'FOO', :bar => 'BAR')
      user.update_attributes(:name => 'NAME-2')
      expect(user.delta_changes).to eq('name' => [nil, 'NAME-2'])
    end

    # that might change, I'd consider this a bug ... but just documenting for now
    it 'should not reset columns on reload' do
      user = User.create!(:name => 'NAME', :foo => 'FOO', :bar => 'BAR')
      user.reload
      expect(user.delta_changes).to eq('name' => [nil, 'NAME'])
    end

    it 'should have previous value from db' do
      user = User.create!(:name => 'NAME', :foo => 'FOO', :bar => 'BAR')
      user = User.find(user.id)
      user.name = 'NAME-2'
      expect(user.delta_changes).to eq('name' => ['NAME', 'NAME-2'])
    end

    it 'should not track non-changes on tracked columns' do
      user = User.create!(:score => 5).reload
      user.reset_delta_changes!

      expect(user.delta_changes).to eq({})

      user.score = 5
      expect(user.delta_changes).to eq({})

      user.score = '5'
      expect(user.delta_changes).to eq({})
    end
  end
end
