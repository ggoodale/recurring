require File.dirname(__FILE__) + "/../lib/recurring"
require 'yaml'

def results_should_be_included results, schedule
  results.each do |t|
    schedule.should include(t)
  end
end

def should_find_in_range schedule, length, *range
  result = schedule.find_in_range(range)
  result.length.should == length
  results_should_be_included result, schedule
  result
end

describe "Initializing a Schedule" do
 
  it "should accept the frequency, unit, and anchor params" do
    rs = Recurring::Schedule.new :unit => 'days', :frequency => 2, :anchor => Time.utc(2006,8,11)
    rs.unit.should == :days
    rs.frequency.should == 2
    rs.anchor.should == Time.utc(2006,8,11)
  end

  it "should check for valid units" do
    lambda{@rs = Recurring::Schedule.new :unit => 'day', :times => '4:29am'}.should raise_error(ArgumentError)
  end

  it "should parse the time param" do
    rs = Recurring::Schedule.new :unit => 'days', :times => '4:30pm 5pm 3:30:30'
    rs.times.should == [{:hour => 16, :minute => 30, :second => 0}, {:hour => 17, :minute => 0, :second => 0}, {:hour => 3, :minute => 30, :second => 30}] 
  end

  it "should not add 12 hours to '12pm'" do
    rs = Recurring::Schedule.new :unit => 'days', :times => '12pm'
    rs.times.should == [{:hour => 12, :minute => 0, :second => 0}] 
  end

  it "should subtract 12 hours from '12am'" do
    rs = Recurring::Schedule.new :unit => 'days', :times => '12am'
    rs.times.should == [{:hour => 0, :minute => 0, :second => 0}] 
  end



   it "should == graceful about a duplicate times string" do
    rs = Recurring::Schedule.new :unit => 'days', :times => '4:30 4:30'
    rs.times.should == [{:hour => 4, :minute => 30, :second => 0}] 
  end

   it "should == graceful about a busted times string" do
    rs = Recurring::Schedule.new :unit => 'days', :times => 'afs4 th'
    rs.times.should == [{:hour => 0, :minute => 0, :second => 0}] 
  end

  it "should == graceful about an empty times string" do
    rs = Recurring::Schedule.new :unit => 'days', :times => ''
    rs.times.should == [{:hour => 0, :minute => 0, :second => 0}] 
  end
 
  it "should provide a sensible default time param" do
    rs = Recurring::Schedule.new :unit => 'days'
    rs.times.should == [{:hour => 0, :minute => 0, :second => 0}]
  end
 
  it "should flip out if the units are not provided" do
    lambda{Recurring::Schedule.new :argument => 'no units, dogg'}.should raise_error(ArgumentError)
  end
 
  it "should accept weeks and days params" do
    rs = Recurring::Schedule.new :unit => 'months', :weeks => [1,2], :weekdays => %w{monday wednesday}
    rs.weeks.should == [1,2]
    rs.weekdays.should == [1,3]
  end

  it "should flip out if weekdays aren't in the white list" do
    lambda{Recurring::Schedule.new :unit => 'months', :weeks => [1,2], :weekdays => %w{garbage_day thanksgiving}}.should raise_error(ArgumentError)
  end

  it "should flip out if months aren't in the white list" do
    lambda{Recurring::Schedule.new :unit => 'years', :months => %w{monsoon ramadan}, :weeks => [1,2], :weekdays => %w{mon}}.should raise_error(ArgumentError)
  end

  it "should accept months params" do
    rs = Recurring::Schedule.new :unit => 'years', :months => 'feb', :monthdays => [4]
    rs.months.should == [2]
  end

  it "should accept monthdays as strings" do
    rs = Recurring::Schedule.new :unit => 'months', :monthdays => ['1','15']
    rs.monthdays.should == [1,15]
  end

  it "should accept monthdays as integers" do
    rs = Recurring::Schedule.new :unit => 'months', :monthdays => [1,15]
    rs.monthdays.should == [1,15]
  end

end

describe "A complex Schedule" do
  before do
    @rs = Recurring::Schedule.new :unit => 'months', :frequency => 2, :anchor => Time.utc(2006,4,15,10,30), :monthdays => [3,7], :times => '5pm 4:45:12am'
  end
  
  it "should == marshallable" do
    rm = Marshal.dump(@rs)
    Marshal.load(rm).should == @rs
  end

  it "should == YAMLable" do
    rm = YAML.dump(@rs)
    YAML.load(rm).should == @rs
  end

  it "should == equal to a schedule with the same params" do
    r2 = Recurring::Schedule.new :unit => 'months', :frequency => 2, :anchor => Time.utc(2006,4,15,10,30), :monthdays => [3,7], :times => '5pm 4:45:12am'
    r2.should == @rs
  end

  it "should not == equal to a slightly different schedule" do
    r2 = Recurring::Schedule.new :unit => 'months', :frequency => 2, :anchor => Time.utc(2006,4,15,10,30), :monthdays => [3,7], :times => '5pm 4:45:11am'
    r2.should_not == @rs
  end

end


#YEARS
describe "A basic yearly schedule" do
  before do
    @rs = Recurring::Schedule.new :unit => 'years', :frequency => 1, :anchor => Time.utc(2008,3,6)
  end

  it "should include next year" do
    @rs.should include(Time.utc(2009,3,6))
    @rs.should include(Time.utc(2010,3,6))
  end
  it "should not include a random wrong time" do
    @rs.should_not include(Time.utc(2008,4,6))
  end
  it "should find the right next" do
    @rs.find_next(Time.utc(2008,3,6)).should == Time.utc(2008,3,6)
    @rs.find_next(Time.utc(2008,3,7)).should == Time.utc(2009,3,6)
    @rs.find_next(Time.utc(2008,3,6,1)).should == Time.utc(2009,3,6)
  end
end

describe "A basic bi-yearly schedule" do
  before do
    @rs = Recurring::Schedule.new :unit => 'years', :frequency => 2, :anchor => Time.utc(2008,3,6)
  end

  it "should include next year" do
    @rs.should_not include(Time.utc(2009,3,6))
    @rs.should include(Time.utc(2010,3,6))
  end
end

describe "A yearly schedule with month and monthdays" do
  before do
    @rs = Recurring::Schedule.new :unit => 'years', :months => 'feb', :monthdays => [4]
  end
  
  it "should include the day of the month in any year" do
    @rs.should include(Time.utc(1980,2,4))
    @rs.should include(Time.utc(1989,2,4))
  end
  it "should not include other days of the month in any year" do
    @rs.should_not include(Time.utc(1989,4,4))
    @rs.should_not include(Time.utc(1980,2,5))
  end
  
  it "should find 20 times in 20 years" do
    should_find_in_range(@rs, 20, Time.utc(2006,12,12,1), Time.utc(2026,12,12,1,45))
  end
end

describe "A yearly schedule with months and weekdays" do
  before do
    @rs = Recurring::Schedule.new :unit => 'years', :months => 'feb', :weekdays => ['tuesday', 'weds']
  end
  it "should match every tuesday and wednesday in febraury" do
    @rs.should include(Time.utc(2007,2,6))
    @rs.should include(Time.utc(2007,2,7))
    @rs.should include(Time.utc(2007,2,20))
    @rs.should include(Time.utc(2007,2,21))
  end
  it "should not include other days of the week in feburary" do
    @rs.should_not include(Time.utc(2007,2,8))
    @rs.should_not include(Time.utc(2007,2,9))
    @rs.should_not include(Time.utc(2007,2,23))
    @rs.should_not include(Time.utc(2007,2,24))
  end
  it "should not include tuesday and wednesday outside of febraury" do
    @rs.should_not include(Time.utc(2007,3,6))
    @rs.should_not include(Time.utc(2007,3,7))
    @rs.should_not include(Time.utc(2007,3,20))
    @rs.should_not include(Time.utc(2007,3,21))
  end
  it "should find 20 times in 20 years" do
    should_find_in_range(@rs, 161, Time.utc(2006,12,12,1), Time.utc(2026,12,12,1,45))
  end
end

describe "A bi-yearly schedule with months, weeks, weekdays, and times" do
  before do
    @rs = Recurring::Schedule.new :unit => 'years', :frequency => 2, :anchor => Time.utc(2006,6), :months => ['feb', 'may'], :weeks => [2], :weekdays => 'fri', :times => '5:15'
  end
  
  it "should include the correct days at the right times" do
    @rs.should include(Time.utc(2006,2,10,5,15))
    @rs.should include(Time.utc(2006,5,12,5,15))
    @rs.should include(Time.utc(2008,2,8,5,15))
    @rs.should include(Time.utc(2008,5,9,5,15))
  end
  
  it "should not include good times in bad years" do
    @rs.should_not include(Time.utc(2007,2,9,5,15))
    @rs.should_not include(Time.utc(2007,5,11,5,15))
  end
end

#MONTHS

describe "A bi-monthly Schedule without more params" do

  before do
    @rs = Recurring::Schedule.new :unit => 'months', :frequency => 2, :anchor => Time.utc(2006,4,15,10,30)
  end

  it "should include the anchor date" do
    @rs.should include(Time.utc(2006,4,15,10,30))
  end

  it "should include dates offset by the frequency" do
    @rs.should include(Time.utc(2006,6,15,10,30))
  end

  it "should not include the beginnings of days for which it includes points in the middle" do
    @rs.should_not include(Time.utc(2006,6,15))
    @rs.should_not include(Time.utc(2006,4,15))
  end

  it "should not include dates with wrong months" do
    @rs.should_not include(Time.utc(2006,5,15,10,30))
  end

  it "should not include dates without matching time parts" do
    @rs.should_not include(Time.utc(2006,4,16))
    @rs.should_not include(Time.utc(2006,6,15,10,15))
  end

  it "should find that the start point is the next included date when the start point matches" do
    included = Time.utc(2006,6,15,10,30)
    @rs.find_next(included).should == included
  end

  it "should find the next date when the start point doesn't match" do
    @rs.find_next(Time.utc(2006,6,15)).should == Time.utc(2006,6,15,10,30)
  end

end

describe "A monthly schedule with monthday params" do
  before do
    @rs = Recurring::Schedule.new :unit => 'months', :monthdays => [1,15]
    #    @rs.anchor = Time.utc(2006,6,18,12,30) #should react appropriately to the presence of a (no longer useless) anchor
  end

  it "should include the start of matching days" do
    @rs.should include(Time.utc(2006,6,15))
    @rs.should include(Time.utc(2006,7,1))
  end

  it "should not include the middle of matching days" do
    @rs.should_not include(Time.utc(2006,6,15,14))
    @rs.should_not include(Time.utc(2006,7,1,11,30))
    @rs.should_not include(Time.utc(2006,7,1,0,0,30))
  end

  it "should not include the start of non-matching days" do
    @rs.should_not include(Time.utc(2006,6,14))
    @rs.should_not include(Time.utc(2006,7,2))
  end

  it "should not include times with no matching component" do
    @rs.should_not include(Time.utc(2006,6,14,11,8))
    @rs.should_not include(Time.utc(2006,7,2,5,30) )
  end

  it "should find the next date" do
    @rs.find_next(Time.utc(2006,3,4)).should == Time.utc(2006,3,15)
    @rs.find_next(Time.utc(2006,3,17)).should == Time.utc(2006,4,1)
  end

end

describe "A bi-monthly Schedule with monthday params" do

  before do
    @rs = Recurring::Schedule.new :unit => 'months', :frequency => 2, :anchor => Time.utc(2006,4,15,10,30), :monthdays => [10,18]
  end

  it "should include the beginnings of matching days" do
    @rs.should include(Time.utc(2006,6,10))
    @rs.should include(Time.utc(2006,8,18))
  end

  it "should not include the beginnings of non_matching days" do
    @rs.should_not include(Time.utc(2006,6,11))
  end

  it "should not include the beginning of the anchor day" do
    @rs.should_not include(Time.utc(2006,4,15))
  end

  it "should not include the anchor time" do
    @rs.should_not include(Time.utc(2006,4,15,10,30))
  end

  it "should find the next date when the start point doesn't match" do
    @rs.find_next(Time.utc(2006,6,15)).should == Time.utc(2006,6,18)
  end

  it "should find the next date" do
    @rs.find_next(Time.utc(2006,5,4)).should == Time.utc(2006,6,10)
    @rs.find_next(Time.utc(2006,6,11)).should == Time.utc(2006,6,18)
  end
end 

describe "A monthly schedule with week params" do
end

describe "A third-monthly schedule with week params" do
  
    before do
      lambda{@rs = Recurring::Schedule.new :unit => 'months', :week => 1, :frequency => 3}.should raise_error(ArgumentError)
    end

    it "should walk up the stairs" do
    end


end

describe "A monthly schedule with week params and weekday params" do

  before do
    @rs = Recurring::Schedule.new :unit => 'months', :weeks => 1, :weekdays => :sunday
  end

  it "should include the beginnings of matching days" do
    @rs.should include(Time.utc(2006,12,3))
  end

  it "should not include the matching days in off weeks" do
    @rs.should_not include(Time.utc(2006,12,24))
    @rs.should_not include(Time.utc(2006,12,10))
  end

  it "should have a next occurrence date no more than 38 days in the future" do
    # August 4, 2009 is a Saturday. So is September 5.  Calling next()
    # in 0.5.2 would return Nov. 7, 2009 as the next occurrence.
    puts @rs.find_next(Time.utc(2009,8,3))
    @rs.find_next(Time.utc(2009,8,3)).should == Time.utc(2009,9,6)
  end
end

describe "A monthly schedule with weekday params but no week params" do
end

describe "A six-monthly schedule with week, weekday, and times params" do
end

describe "A monthly schedule with negative week params and weekday params" do

 before do
   @rs = Recurring::Schedule.new(:unit => 'months', :weeks => -1, :weekdays => :monday)
 end
  it "should include the beginnings of matching days" do
   @rs.should include(Time.utc(2006,12,25))
   @rs.should include(Time.utc(2007,4,30))
 end
  it "should not include the matching days in off weeks" do
   @rs.should_not include(Time.utc(2006,12,18))
   @rs.should_not include(Time.utc(2006,12,11))
   @rs.should_not include(Time.utc(2006,12,4))
 end

end

#WEEKLY

describe "A bi-weekly schedule with weekdays and a midnight time" do
  before do
    @rs = Recurring::Schedule.new :unit => 'weeks', :weekdays => %w{sat sunday}, :times => '12am', :frequency => 2, :anchor => Time.utc(2001)
    @danger = Time.utc(2006,12,17,18)
  end

  it "should include midnights of every other weekend" do
    @rs.should include(Time.utc(2006,12,16))
    @rs.should include(Time.utc(2006,12,10))
  end

  it "should not include other midnights" do 
    @rs.should_not include(Time.utc(2006,12,22))
    @rs.should_not include(Time.utc(2006,12,25))
  end

  it "should find the previous time from a dangerous time" do
    @rs.find_previous(@danger).should == Time.utc(2006,12,16)
  end
  
end

describe "A bi-weekly schedule with weekdays and a noon time" do
  before do
    @rs = Recurring::Schedule.new :unit => 'weeks', :weekdays => %w{sat sunday}, :times => '12pm', :frequency => 2, :anchor => Time.utc(2001)
    @danger = Time.utc(2006,12,17,18)
  end

  it "should include noons of every other weekend" do
    @rs.should include(Time.utc(2006,12,10,12))
    @rs.should include(Time.utc(2006,12,16,12))
  end

  it "should not include other midnights" do 
    @rs.should_not include(Time.utc(2006,12,22,12))
    @rs.should_not include(Time.utc(2006,12,25,12))
  end

  it "should find the previous time from a dangerous time" do
    @rs.find_previous(@danger).should == Time.utc(2006,12,16,12)
  end
end

describe "A weekly schedule with weekday params" do
  
  before do
    @rs = Recurring::Schedule.new :unit => 'weeks', :weekdays => %w{sunday monday weds friday}
  end

  it "should include the beginnings of matching days" do
    @rs.should include(Time.utc(2006,12,3))
    @rs.should include(Time.utc(2006,12,6))
    @rs.should include(Time.utc(2006,11,27))
  end

  it "should not include the middle of matching days" do
    @rs.should_not include(Time.utc(2006,12,6,10,30))
    @rs.should_not include(Time.utc(2006,11,27,0,30))
    @rs.should_not include(Time.utc(2006,12,7))
  end

  it "should find the next date" do
    @rs.find_next(Time.utc(2006,12,2)).should == Time.utc(2006,12,3)
    @rs.find_next(Time.utc(2006,11,30)).should == Time.utc(2006,12,1)
  end

end

describe "A Schedule with uppercase weekdays" do
  before do
    @rs = Recurring::Schedule.new :unit => 'weeks', :weekdays => %w{Friday}, :anchor => Time.now, :times => '12'
  end

  it "should include Friday's at noon" do
    @rs.should include(Time.utc(2006,12,8,12))
  end
end

describe "A weekly schedule with only an anchor" do
  
  before do
    @rs = Recurring::Schedule.new :unit => 'weeks', :anchor => Time.utc(2006,12,6,17,30)
  end

  it "should include times that are offset by one week" do
    @rs.should include(Time.utc(2006,12,20,17,30))
  end

  it "should not include times that are not offset by one week" do
    @rs.should_not include(Time.utc(2006,12,19,17,30))
    @rs.should_not include(Time.utc(2006,12,20))
    @rs.should_not include(Time.utc(2006,5,6,17,30))
  end
  
  it "should find the next date" do
    @rs.find_next(Time.utc(2006,5,4)).should == Time.utc(2006,5,10,17,30)
    @rs.find_next(Time.utc(2006,6,11)).should == Time.utc(2006,6,14,17,30)
  end

  it "should find the previous date" do
    @rs.find_previous(Time.utc(2006,5,14)).should == Time.utc(2006,5,10,17,30)
  end
end

describe "A third-weekly schedule with weekday and times params" do

  before do
    @rs = Recurring::Schedule.new :unit => 'weeks', :frequency => 3, :anchor => Time.utc(2006,12,1), :weekdays => %w{mon fri sat}, :times => '3pm' 
  end

  it "should include the proper times on the right days of matching weeks" do
    @rs.should include(Time.utc(2006,11,27,15))
    @rs.should include(Time.utc(2006,12,1,15))
    @rs.should include(Time.utc(2006,12,2,15))
    @rs.should include(Time.utc(2006,12,18,15))
  end

  it "should not include the beginnings of matching days" do
    @rs.should_not include(Time.utc(2006,12,1))
  end

  it "should not include the proper times on the right days of non-matching weeks" do
    @rs.should_not include(Time.utc(2006,12,4,15))
  end

  it "should find the next date" do
    @rs.find_next(Time.utc(2006,12,4)).should == Time.utc(2006,12,18,15)
    @rs.find_next(Time.utc(2006,12,18)).should == Time.utc(2006,12,18,15)
  end

  it "should find the previous date" do
    @rs.find_previous(Time.utc(2006,12,4)).should == Time.utc(2006,12,2,15)
    @rs.find_previous(Time.utc(2006,12,18,20)).should == Time.utc(2006,12,18,15)
  end
  
end

describe "Recurring.week_of_year" do

  it "should return the same value for days in the same week" do
    [[2006,12,1],
    [2006,12,2],
    [2006,11,28],
    [2006,11,26]].collect do |args| 
        Time.utc *args
    end.each do |t|
      Recurring.week_of_year(t).should == 48
    end
    
    [[2006,12,7], 
    [2006,12,9], 
    [2006,12,3]].collect do |args| 
        Time.utc *args
    end.each do |t|
      Recurring.week_of_year(t).should == 49
    end 
  end

end

describe "A weekly schedule with times params but no days params" do

  it "should flip out hard" do
    lambda{@rs = Recurring::Schedule.new :unit => 'weeks', :times => '4pm'}.should raise_error( ArgumentError)
  end

end

#DAILY

describe "A daily schedule with no other params" do

  before do
    @rs = Recurring::Schedule.new :unit => 'days'
  end

  it "should match the beginning of every day" do
    @rs.should include(Time.utc(2006,11,5))
    @rs.should include(Time.mktime(2006,11,5))
  end

  it "should not match the middle of any day" do
    @rs.should_not include(Time.utc(2006,11,5,5))
    @rs.should_not include(Time.utc(2006,11,5,0,0,22))
  end

  it "should find the next date" do
    @rs.find_next(Time.utc(2006,5,4,2)).should == Time.utc(2006,5,5)
    @rs.find_next(Time.utc(2006,6,13,5)).should == Time.utc(2006,6,14)
  end

end

describe "A daily schedule with an anchor" do
  before do
    @rs = Recurring::Schedule.new :unit => 'days', :anchor => Time.utc(2006,11,1,10,15,22)
  end

  it "should include daily mulitples of the anchor" do
    @rs.should include(Time.utc(2006,11,7,10,15,22))
  end

  it "should not include other times in any day" do
    @rs.should_not include(Time.utc(2006,11,7))
    @rs.should_not include(Time.utc(2006,11,7,10,15,21))
  end

  it "should find the next date" do
    @rs.find_next(Time.utc(2006,5,4,12)).should == Time.utc(2006,5,5,10,15,22)
    @rs.find_next(Time.utc(2006,6,13,5)).should == Time.utc(2006,6,13,10,15,22)
  end
end

describe "A fourth-daily schedule with only the unit and frequency != 1" do
  it "should have an ArgumentError" do
    lambda{@rs = Recurring::Schedule.new :unit => 'days', :frequency => 4}.should raise_error(ArgumentError)
  end
end

describe "A daily schedule with a sub-second precise anchor" do
  before do
    @rs = Recurring::Schedule.new :unit => 'days', :anchor => Time.utc(2006,11,27,0,0,30,45)
  end
  it "should include times equal up to second accuracy" do
    @rs.should include(Time.utc(2006,11,27,0,0,30))
    @rs.should include(Time.utc(2006,11,27,0,0,30,55))
  end
  it "should not include other times" do
    @rs.should_not include(Time.utc(2006,11,27,0,0,31,45))
  end
end

describe "A fourth-daily schedule with no other params" do

  before do
    @rs = Recurring::Schedule.new :unit => 'days', :frequency => 4, :anchor => Time.utc(2006,11,1,9,30)
  end

  it "should check the anchor" do
    @rs.send(:check_anchor?).should == true
  end

  it "should include the anchor" do
    @rs.should include(Time.utc(2006,11,1,9,30))
  end
  
  it "should not include the beginning of the anchor day" do
    @rs.should_not include(Time.utc(2006,11,1))
  end
  
  it "should include the time of the anchor, every four days" do
    @rs.should include(Time.utc(2006,11,5,9,30))
    @rs.should include(Time.utc(2006,10,28,9,30))
  end

  it "should not include the beginnings of matching days" do
    @rs.should_not include(Time.utc(2006,11,5))
  end
end

describe "A daily schedule with times params" do
end

describe "A third-daily schedule with times params" do
end

describe "A daily schedule with monthday params" do
end

#HOURLY

describe "An hourly schedule with no other params" do

  before do
    @rs = Recurring::Schedule.new :unit => 'hours'
  end

  it "should include the top of every hour" do
    @rs.should include(Time.utc(2006,3,4,5))
  end

  it "should not include times with non zero minutes or seconds" do
    @rs.should_not include(Time.utc(2006,3,4,5,6))
    @rs.should_not include(Time.utc(2006,3,4,5,0,6))
  end

end

describe "An hourly schedule with an anchor" do
  before do
    @rs = Recurring::Schedule.new :unit => 'hours', :anchor => Time.utc(2001,5,15,11,17) 
  end

  it "should include any time with the same sub hour parts" do
    @rs.should include(Time.utc(2006,5,15,14,17))
  end
 
  it "should include the anchor time" do
  end

  it "should not include any times with different sub hour parts" do
  end

  it "should find in range" do
    @rs.find_in_range(Time.utc(2006), Time.utc(2007)).length.should == 24*365
  end
	 
end

describe "An bi-hourly schedule with time params" do
  
  before do
    @rs = Recurring::Schedule.new :unit => 'hours', :frequency => 2, :times => '0:22 0:13:14', :anchor => Time.utc(2006)
  end
  
  it "should find 4 times in 4 hours" do
    #should_find_in_range(@rs, 4, Time.utc(2006,12,12), Time.utc(2006,12,12,4) )
  end
  
  it "should include times every other hour with the valid minutes and seconds" do
    @rs.should include(Time.utc(2006,1,1,0,22))
    @rs.should include(Time.utc(2006,1,1,0,13,14))
    @rs.should include(Time.utc(2006,1,1,2,22))
    @rs.should include(Time.utc(2006,1,1,16,13,14))
  end
  
  it "should not include times with mismatched minutes or hours" do
    @rs.should_not include(Time.utc(2006,12,12))
    @rs.should_not include(Time.utc(2006,1,1,1,22))
    @rs.should_not include(Time.utc(2006,1,1,3,13,14))
    @rs.should_not include(Time.utc(2006,1,1,2,23))
    @rs.should_not include(Time.utc(2006,1,1,16,13,24))
  end
  
end

describe "An hourly schedule with times params" do

  before do
    @rs = Recurring::Schedule.new :unit => 'hours', :times => '0:15 4:30 0:45:30'
  end

  it "should include matching times" do
    @rs.should include(Time.utc(2001,11,11,11,15))
    @rs.should include(Time.utc(2001,1,1,1,30))
    @rs.should include(Time.utc(2009,12,14,3,45,30))
  end

  it "should not include non matching times" do
    @rs.should_not include(Time.utc(2001,11,11,11,15,05))
    @rs.should_not include(Time.utc(2001,1,1,1,30,1))
    @rs.should_not include(Time.utc(2001,1,1,1,35))
    @rs.should_not include(Time.utc(2009,12,14,3,45))
  end

  it "should find the next date" do
    @rs.find_next(Time.utc(2006,5,4,12)).should == Time.utc(2006,5,4,12,15)
    @rs.find_next(Time.utc(2006,6,13,5,31)).should == Time.utc(2006,6,13,5,45,30)
  end

  it "should find the previous minute that match" do
    @rs.find_previous(Time.utc(2006,5,5,5,17)).should == Time.utc(2006,5,5,5,15)
  end

end

describe "An eight-hourly schedule with times params" do
end

describe "An hourly schedule with monthday params" do
  
  it "should ignore the monthday params" do
  end

end

#MINUTELY

describe "Every 45 minutes from an anchor" do
  before do
    @rs = Recurring::Schedule.new :unit => 'minutes', :frequency => 45, :anchor => Time.utc(2006, 12, 1, 10, 30)
  end
  it "should include 45 minute multiples of the anchor time" do
    @rs.should include(Time.utc(2006, 12, 1, 11, 15))
    @rs.should include(Time.utc(2006, 12, 1, 12, 00))
    @rs.should include(Time.utc(2006, 12, 1, 9, 45))
  end
end

describe "A 30 minutely schedule" do
  before do
    @rs = Recurring::Schedule.new :unit => 'minutes', :frequency => 30, :anchor => Time.utc(2006,1,1,1,15)
  end
  it "should match the very next time after the start" do
    @rs.find_in_range(Time.utc(2006,1,15,2), Time.utc(2006,1,16)).first.should == Time.utc(2006,1,15,2,15)
  end
end

describe "A 5-minutely schedule with no other params" do
  
  before do
    @rs = Recurring::Schedule.new :unit => 'minutes', :frequency => 5, :anchor => Time.utc(2006,9,1,10,30)
  end

  it "should include a five minute multiples of the anchor time" do
    @rs.should include(Time.utc(2006,9,1,10,30))
    @rs.should include(Time.utc(2006,9,1,10,35))
    @rs.should include(Time.utc(2006,9,1,20,30))
  end

  it "should not include times with different seconds" do
    @rs.should_not include(Time.utc(2006,9,1,10,30,30))
  end

  it "should find the next date" do
    @rs.find_next(Time.utc(2006,5,4,12,1)).should == Time.utc(2006,5,4,12,5)
    @rs.find_next(Time.utc(2006,6,13,5,31)).should == Time.utc(2006,6,13,5,35)
  end

  it "should ignore higher than second precision from the anchor" do
  end
  
  it "should find 7 times in a 30 minute range" do
    should_find_in_range(@rs, 7, Time.utc(2006,12,12,0,45), Time.utc(2006,12,12,1,15))
    @rs.find_in_range( Time.utc(2006,12,12,0,45)..Time.utc(2006,12,12,1,15) ).first.class.should == Time  
  end

  it "should find 3 times in a 30 minute range with a limit of 3" do
    results = @rs.find_in_range(Time.utc(2006,12,12,0,45), Time.utc(2006,12,12,1,15), :limit => 3)
    results.length.should == 3
  end

  it "should find 3 times in a 30 minute range (with range args) with a limit of 3" do
    results = @rs.find_in_range(Time.utc(2006,12,12,0,45)..Time.utc(2006,12,12,1,15), :limit => 3)
    results.length.should == 3
  end

  it "should find in a range given as an object with first and last params" do
    range = mock('range')
    range.should_receive(:first).and_return(Time.utc(2006,12,12,0,45))
    range.should_receive(:last).any_number_of_times.and_return(Time.utc(2006,12,12,1,15))
    @rs.find_in_range(range).first.class.should == Time  
  end

  it "should find in a range given as a Range" do
    range = (Time.utc(2006,12,12,0,45)..Time.utc(2006,12,12,1,15))
    @rs.find_in_range(range).first.class.should == Time  
  end

  it "should find 10 times in a 45 minute range" do
    should_find_in_range(@rs, 10, Time.utc(2006,12,12,1), Time.utc(2006,12,12,1,45))
    @rs.find_in_range( Time.utc(2006,12,12,0,45), Time.utc(2006,12,12,1,15) ).first.class.should == Time  
  end
end

#SECONDLY


#ETC

describe "a daily schedule with a time 4:29am" do
  before do
    @rs = Recurring::Schedule.new :unit => 'days', :times => '4:29am'
  end
  it "should include any day at the time specified" do
    @rs.should include(Time.utc(2001,3,4,4,29))
  end
  it "should not include times other than 4:29am" do
    @rs.should_not include(Time.utc(2004,5,17,1,39))
  end
end
