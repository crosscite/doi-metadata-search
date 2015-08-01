require 'spec_helper'

describe "helpers" do
  it "activity" do
    str = "abc"
    expect(force_utf8(str)).to eq(2)
  end
end
