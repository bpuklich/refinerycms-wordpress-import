require 'spec_helper'

describe Refinery::WordPress::Category, :type => :model do
  let(:category) { Refinery::WordPress::Category.new('Rant') }

  describe "#name" do
    specify { category.name.should == 'Rant' }
  end

  describe "#==" do
    specify { category.should == Refinery::WordPress::Category.new('Rant') }
    specify { category.should_not == Refinery::WordPress::Category.new('Tutorials') }
  end

  describe "#to_refinery" do
    before do
      @category = category.to_refinery
    end

    it "creates a BlogCategory" do
      expect(Refinery::Blog::Category).to have(1).record
    end

    it "gives the BlogCategory object the correct name" do
      expect(@category.title).to eq(category.name)
    end
  end

end
