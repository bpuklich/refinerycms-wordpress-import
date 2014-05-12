require 'spec_helper'

describe Refinery::WordPress::Category, :type => :model do
  let(:category) { Refinery::WordPress::Category.new('Rant') }

  describe "#name" do
    specify { expect(category.name).to eq('Rant') }
  end

  describe "#==" do
    specify { expect(category).to be_a(Refinery::WordPress::Category) }
    specify { expect(category.name).to eq('Rant') }
  end

  describe "#to_refinery" do
    before do
      @category = category.to_refinery
    end

    it "creates a BlogCategory" do
      expect(Refinery::Blog::Category.count).to eq(1)
    end

    it "names the BlogCategory correctly" do
      expect(@category.title).to eq(category.name)
    end
  end

end
