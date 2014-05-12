require 'spec_helper'

describe Refinery::WordPress::Tag, :type => :model do
  let(:tag) { Refinery::WordPress::Tag.new('ruby') }

  describe "#name" do
    specify { expect(tag.name).to eq('ruby') }
  end

  describe "#==" do
    specify { expect(tag).to be_a(Refinery::WordPress::Tag) }
    specify { expect(tag.name).to eq('ruby') }
  end

  describe "#to_refinery" do
    before do
      @tag = tag.to_refinery
    end

    it "creates a ActsAsTaggableOn::Tag" do
      expect(::ActsAsTaggableOn::Tag.count).to eq(1)
    end

    it "creats a tag with the correct name" do
      expect(@tag.name).to eq(tag.name)
    end
  end

end

