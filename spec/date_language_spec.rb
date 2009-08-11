require 'rubygems'
require_gem 'rspec'
require File.dirname(__FILE__) + "/../lib/date_language"
#require 'yaml'

context "Every two days from 2006/11/3" do
  setup do
    @rdl = Recurring::DateLanguage.tell do
      every 2, :days, :anchor => Time.utc(2006,11,3)
      times '4:45am 3pm'
    end
  end
  
  specify "should intialize properly" do
    @rdl.frequency.should == 2
  end
  # specify "should return an rdl" do
  #   @rdl.class.should == Recurring::DateLanguage
  # end
  # specify "should include the correct days at the times specified" do
  #   @rdl.should_include Time.utc(2006,11,3,4,45)
  #   @rdl.should_include Time.utc(2006,11,5,4,45)
  #   @rdl.should_include Time.utc(2006,11,19,3)
  # end
  # specify "should not include wrong times" do
  #   @rdl.should_not_include Time.utc(2006,11,3)
  # end
end


context "Converting from RDL to Schedule" do
  specify "should call the right things on mocks and stubs" do
  end
end