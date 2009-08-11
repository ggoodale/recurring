module Recurring

  VERSION = '0.5.2'
  
  class << self
    # returns a number starting with 1
    def week_in_month date
      (((date.day - 1).to_f / 7.0) + 1).floor
    end

    def negative_week_in_month date
    	end_of_month = (date.month < 12 ? Time.utc(date.year, date.month+1) : Time.utc(date.year + 1)) - 3600
      
      (((end_of_month.day - date.day).to_f / 7.0) + 1).floor * -1
    end

    # just a wrapper for strftime
    def week_of_year date
    	date.strftime('%U').to_i
    end
  end
  
  
  # Initialize a Schedule object with the proper options to calculate occurances in 
  # that schedule. Schedule#new take a hash of options <tt>:unit, :frequency, :anchor, :weeks, :monthdays, :weekdays, :times</tt>
  #
  # = Yearly
  # [Every two years from an anchor time] <tt>Recurring::Schedule.new :unit => 'years', :frequency => 2, :anchor => Time.utc(2006,4,15,10,30)</tt>
  # [Every year in February and May on the 1st and 15th] <tt>Recurring::Schedule.new :unit => 'years', :months => ['feb', 'may'], :monthdays => [1,15]</tt>
  # [Every year in February and May on the 1st and 15th] <tt>Recurring::Schedule.new :unit => 'years', :months => ['feb', 'may'], :monthdays => [1,15]</tt>
  # = Monthly
  # [Every two months from an anchor time] <tt>Recurring::Schedule.new :unit => 'months', :frequency => 2, :anchor => Time.utc(2006,4,15,10,30)</tt>
  # [The first and fifteenth of every month] <tt>Recurring::Schedule.new :unit => 'months', :monthdays => [1,15]</tt>
  # [The first and eighteenth of every third month] <tt>Recurring::Schedule.new :unit => 'months', :frequency => 3, :anchor => Time.utc(2006,4,15,10,30), :monthdays => [10,18]</tt>
  # [The third Monday of every month at 6:30pm] <tt>Recurring::Schedule.new :unit => 'months', :weeks => 3, :weekdays => :monday, :times => '6:30pm'</tt>
  # =  Weekly
  # [Monday, Wednesday, and Friday of every week] <tt>Recurring::Schedule.new :unit => 'weeks', :weekdays => %w{monday weds friday}</tt>
  # [Every week at the same time on the same day of the week as the anchor (Weds at 5:30pm)] <tt>Recurring::Schedule.new :unit => 'weeks', :anchor => Time.utc(2006,12,6,17,30)</tt>
  # [Equivalently, Every Wednesday at 5:30] <tt>Recurring::Schedule.new :unit => 'weeks', :weekdays => 'weds', :times => '5:30pm'</tt>
  # =  Daily
  # [Everyday at the time of the anchor] <tt>Recurring::Schedule.new :unit => 'days', :anchor => Time.utc(2006,11,1,10,15,22)</tt>
  # [Everyday at 7am and 5:45:20pm] <tt>Recurring::Schedule.new :unit => 'days', :times => '7am 5:45:20pm'</tt>
  # =  Hourly
  # [Every hour at 15 minutes, 30 minutes, and 45 minutes and 30 seconds] <tt>Recurring::Schedule.new :unit => 'hours', :times => '0:15 4:30 0:45:30'</tt>
  # [Offset every 2 hours from the anchor] <tt>Recurring::Schedule.new :unit => 'hours', :anchor => Time.utc(2001,5,15,11,17)</tt>
  # =  Minutely
  # [Every five minutes offset from the anchor] <tt>Recurring::Schedule.new :unit => 'minutes', :frequency => 5, :anchor => Time.utc(2006,9,1,10,30)</tt>
  # [Every minute at second 15] <tt>Recurring::Schedule.new :unit => 'minutes', :times => '0:0:15'</tt>
  # 
  # See the specs using "rake spec" for even more examples.
    class Schedule
    
    attr_reader :unit, :frequency, :anchor, :months, :weeks, :monthdays, :weekdays, :times
    
    # Options hash has keys <tt>:unit, :frequency, :anchor, :weeks, :monthdays, :weekdays, :times</tt>
    # * valid values for :unit are <tt>years, months, weeks, days, hours, minutes</tt>
    # * :frequency defaults to 1
    # * :anchor is required if the frequency is other than one
    # * :weeks alongside :weekdays is used to specify the nth instance of a weekday in a month. 
    # * :weekdays takes an array of strings like <tt>%w{monday weds friday}</tt>
    # * :monthdays takes an array of days of the month, eg. <tt>[1,7,15]</tt>
    # * :times takes a string with a simple format. <tt>"4pm 5:15pm 6:45:30pm"</tt>
    def initialize options
      raise ArgumentError, 'specify a valid unit' unless options[:unit] &&
        %w{years months weeks days hours minutes}.include?(options[:unit])
      raise ArgumentError, 'frequency > 1 requires an anchor Time' if options[:frequency] && options[:frequency] != 1 && !options[:anchor]
      @unit = options[:unit].to_sym
      raise ArgumentError, 'weekdays are required with the weeks param, if there are times params' if @unit == :weeks && 
	options[:times] && 
	!options[:weekdays]
      @frequency = options[:frequency] || 1
      @anchor = options[:anchor]
      @times = parse_times options[:times]
      if options[:months]
      	@month_args = Array(options[:months]).collect{|d|d.to_s.downcase.to_sym}
      	raise ArgumentError, 'provide valid months' unless @month_args.all?{|m|ordinal_month(m)}
      	@months = @month_args.collect{|m|ordinal_month(m)}
      end
      
      @weeks = Array(options[:weeks]).collect{|n|n.to_i} if options[:weeks]
      if options[:weekdays]
      	@weekdays_args = Array(options[:weekdays]).collect{|d|d.to_s.downcase.to_sym}
      	raise ArgumentError, 'provide valid weekdays' unless @weekdays_args.all?{|w|ordinal_weekday(w)}
        @weekdays = @weekdays_args.collect{|w|ordinal_weekday(w)}
      end
      @monthdays = Array(options[:monthdays]).collect{|n|n.to_i} if options[:monthdays]
      
     
      @anchor_multiple = options[:times].nil? && options[:weeks].nil? && options[:weekdays].nil? && options[:monthdays].nil?
    end
    
    def timeout! time
      @timeout = time
    end
    
    # Returns true or false depending on whether or not the time is included in the schedule.
    def include? date
      @resolution = nil	
      return true if check_anchor? && date == @anchor 
      return mismatch(:year) unless year_matches?(date) if @unit == :years
      return mismatch(:month) unless month_matches?(date) if [:months, :years].include?(@unit)
      return mismatch(:week) unless week_matches?(date) if [:years, :months, :weeks].include?(@unit)
      if [:years, :months, :weeks, :days].include?(@unit)
        return mismatch(:day) unless day_matches?(date)
	      return mismatch(:time) unless time_matches?(date)
      end
      if @unit == :hours
	      return mismatch(:hour) unless hour_matches?(date)
	      return mismatch(:sub_hour) unless sub_hour_matches?(date)
      end
      if @unit == :minutes
	      return mismatch(:minute) unless minute_matches?(date)
	      return mismatch(:second) unless second_matches?(date)
      end
      @resolution = nil	
      true
    end

    # Starts from the argument time, and returns the next included time. Returns the argument if it is included in the schedule.
    def find_next date
      loop do
      	return date if include?(date)
      	#puts "#{@resolution} : #{date}"
      	date = beginning_of_next @resolution, date
      end
    end

    # Starts from the argument time, and works backwards until it hits a time that is included
    def find_previous date
      loop do
      	return date if include?(date)
      	#puts "#{@resolution} : #{date}"
      	date = end_of_previous @resolution, date
      end
    end
 
    # Takes a range which responds to <tt>first</tt> and <tt>last</tt>, returning Time objects. The arguments need only to be duck-type compatible with Time#year, #month, #day, #hour, #min, #sec, #wday etc.
    #
    # <tt>rs.find_in_range(Time.now, Time.now+24*60*60)</tt>
    #
    # or
    #
    # <tt>range = (Time.now..Time.now+24*60*60)</tt>
    #
    # <tt>rs.find_in_range(range)</tt>
    def find_in_range *args
      if args[0].respond_to?(:first) && args[0].respond_to?(:last)
	t_start = args[0].first
	t_end = args[0].last
      else
	t_start = args[0]
	t_end = args[1]
      end
      opts = args.last if args.last.respond_to?(:keys)
      if opts
	limit = opts[:limit]
      end
      result = []
      count = 1
      loop do
        rnext = find_next t_start
        break if count > limit if limit
	break if rnext > t_end
        result << rnext
        t_start = rnext + 1
	count += 1
      end
      result
    end

    # Two Schedules are equal if they have the same attributes.
    def == other
      return false unless self.class == other.class
      [:unit, :frequency, :anchor, :weeks, :monthdays, :weekdays, :times].all? do |attribute|
        self.send(attribute) == other.send(attribute)
      end
    end

    private

      def end_of_previous scope, date
      	case scope
      	when :year
      	  Time.utc(date.year) - 1
      	when :month
      	  Time.utc(date.year, date.month) -1
      	when :week
      	  to_sunday = date.wday
      	  previous_week = (date - to_sunday*24*60*60)
      	  Time.utc(previous_week.year, previous_week.month, previous_week.day) - 1
      	when :day
      	  Time.utc(date.year, date.month, date.day) - 1
      	when :time
      	  previous_time date
      	else
      	  date - 1
      	end
      end


      def beginning_of_next scope, date
  	    case scope
  	    when :year
  	      Time.utc(date.year + 1)
      	when :month
      	  date.month < 12 ? Time.utc(date.year, date.month+1) : beginning_of_next(:year, date)
      	when :week
      	  to_sunday = 7 - date.wday
      	  next_week = (date + to_sunday*24*60*60)
      	  Time.utc(next_week.year, next_week.month, next_week.day)
      	when :day
      	  dayp = date + (24*60*60)
      	  Time.utc(dayp.year, dayp.month, dayp.day)
      	when :time
      	  next_time date
      	when :hour
      	  date.hour < 23 ? Time.utc(date.year, date.month, date.day, date.hour+1) : beginning_of_next(:day, date)
      	when :sub_hour
      	  next_sub_hour date
      	else
      	  date + 1
      	end
      end

      def previous_time date
      	me = {:hour => date.hour, :minute => date.min, :second => date.sec, :me => true}      
      	my_times = times + [me]
      	my_times += [{:hour => @anchor.hour, :minute => @anchor.min, :second => @anchor.sec}] if check_anchor?
      	my_times.sort! do |a,b|
      	  v = a[:hour] <=> b[:hour]
      	  v = a[:minute] <=> b[:minute] if v == 0
      	  v = a[:second] <=> b[:second] if v == 0
      	  v
      	end
	      my_times.reverse!
      	ntime = my_times[my_times.index(me)+1]
      	if ntime
      	  Time.utc(date.year, date.month, date.day, ntime[:hour], ntime[:minute], ntime[:second])
      	else
      	  end_of_previous :day, date
      	end
      end

      def next_time date
      	me = {:hour => date.hour, :minute => date.min, :second => date.sec, :me => true}      
      	my_times = times + [me]
      	my_times += [{:hour => @anchor.hour, :minute => @anchor.min, :second => @anchor.sec}] if check_anchor?
      	my_times.sort! do |a,b|
      	  v = a[:hour] <=> b[:hour]
      	  v = a[:minute] <=> b[:minute] if v == 0
      	  v = a[:second] <=> b[:second] if v == 0
      	  v
      	end
      	ntime = my_times[my_times.index(me)+1]
      	if ntime
      	  Time.utc(date.year, date.month, date.day, ntime[:hour], ntime[:minute], ntime[:second])
      	else
      	  beginning_of_next :day, date
      	end
      end

      def next_sub_hour date
      	me = {:minute => date.min, :second => date.sec, :me => true}      
      	my_times = times + [me]
      	my_times += [{:minute => @anchor.min, :second => @anchor.sec}] if check_anchor?
      	my_times.sort! do |a,b|
      	  v = a[:minute] <=> b[:minute]
      	  v = a[:second] <=> b[:second] if v == 0
      	  v
      	end
      	ntime = my_times[my_times.index(me)+1]
      	if ntime
      	  Time.utc(date.year, date.month, date.day, date.hour, ntime[:minute], ntime[:second])
      	else
      	  beginning_of_next :hour, date
      	end      
      end

      def mismatch unit
	      @resolution = unit
	      false
      end

      def year_matches? date
    	  return true if @frequency == 1
      	(date.year - @anchor.year) % @frequency == 0
      end

      def month_matches? date
      	if @unit == :months    	  
      	  return true if @frequency == 1
          years_in_months = (date.year - @anchor.year) * 12
          diff_months = date.month - @anchor.month
          return (years_in_months + diff_months) % @frequency == 0
        elsif @months
          return @months.include?(date.month)
        else
          return false if date.month != @anchor.month
    	  end

	      true
      end

      def week_matches? date
	      if @unit == :weeks 
      	  return true if @frequency == 1
      	  return ((Recurring.week_of_year(date) - Recurring.week_of_year(@anchor)) % @frequency) == 0
      	end
      	if @weeks
      	  @weeks.include?(Recurring.week_in_month(date)) || @weeks.include?(Recurring.negative_week_in_month(date))
      	else
      	  true
      	end
      end

      def day_matches? date
        if @unit == :days 
        	return true if @frequency == 1
        	diff = Time.utc(date.year, date.month, date.day) - Time.utc(@anchor.year, @anchor.month, @anchor.day)
        	return (diff / 86400) % @frequency == 0
    	  end
      	return @monthdays.include?(date.day) if @monthdays
      	return @weekdays.include?(date.wday) if @weekdays
      	if @unit == :weeks && check_anchor?
      	  return @anchor.wday == date.wday    
      	end
      	return true if check_anchor? && date.day == @anchor.day
      end

      def time_matches? date
      	#concerned with groups of hour minute second
      	if check_anchor? 
      	  return @anchor.hour == date.hour && @anchor.min == date.min && @anchor.sec == date.sec
      	end
      	@times.any? do |time|
      	  time[:hour] == date.hour && time[:minute] == date.min && time[:second] == date.sec
      	end
      end

      def hour_matches? date
        return true if @frequency == 1
      	diff = Time.utc(date.year, date.month, date.day, date.hour) - Time.utc(@anchor.year, @anchor.month, @anchor.day, @anchor.hour)
      	(diff / 3600) % @frequency == 0
      end

      def sub_hour_matches? date
      	if check_anchor? 
      	  return @anchor.min == date.min && @anchor.sec == date.sec
      	end
      	times.any? do |time|
      	  time[:minute] == date.min && time[:second] == date.sec
      	end
      end

      def minute_matches? date
        return true if @frequency == 1
      	diff = Time.utc(date.year, date.month, date.day, date.hour, date.min) - Time.utc(@anchor.year, @anchor.month, @anchor.day, @anchor.hour, @anchor.min)
      	(diff / 60) % @frequency == 0
      end

      def second_matches? date
	      if check_anchor? 
	        return @anchor.sec == date.sec
	      end
	      times.any? do |time|
	        time[:second] == date.sec
	      end
      end

      def check_anchor?
	      @anchor && @anchor_multiple
      end

      def ordinal_weekday symbol
	      lookup = {0 => [:sunday, :sun],
                1 => [:monday, :mon],
                2 => [:tuesday, :tues],
                3 => [:wednesday, :weds],
                4 => [:thursday, :thurs],
                5 => [:friday, :fri],
                6 => [:saturday, :sat]}
	      pair = lookup.select{|k,v| v.include?(symbol)}.first
	      pair.first if pair
      end
    
    def ordinal_month symbol
      lookup = {1 => [:january, :jan],
                2 => [:february, :feb],
                3 => [:march, :mar],
                4 => [:april, :apr],
                5 => [:may],
                6 => [:june, :jun],
                7 => [:july, :jul],
                8 => [:august, :aug],
                9 => [:september, :sept],
                10 => [:october, :oct],
                11 => [:november, :nov],
                12 => [:december, :dec]}
	      pair = lookup.select{|k,v| v.include?(symbol)}.first
	      pair.first if pair
    end

      def parse_times string
      	if string.nil? || string.empty?
      	  return [{:hour => 0, :minute => 0, :second => 0}]
      	end
      	times = string.downcase.gsub(',','').split(' ')
      	parsed = times.collect do |st|
    	  st = st.gsub /pm|am/, ''
    	  am_pm = $&
    	  time = {}
	  time[:hour], time[:minute], time[:second] = st.split(':').collect {|n| n.to_i}
    	  time[:minute] ||= 0
    	  time[:second] ||= 0
    	  time[:hour] = time[:hour] + 12 if am_pm == 'pm' && time[:hour] < 12
    	  time[:hour] = 0 if am_pm == 'am' && time[:hour] == 12
    	  time
	    end
	  #this is an implementation of Array#uniq required because Hash#eql? is not a synonym for Hash#==  
	  result = []  
	  parsed.each_with_index do |h,i|
	    result << h unless parsed[(i+1)..parsed.length].include?(h)
	  end
	  result
    end  
  end
end

# RDS does not match ranges as such, just times specified to varying precision
# eg, you can construct a Schedule that matches all of February, by not specifying the 
# week, day, or time. If you want February through August, you'll have to specify all the months
# individually.

# Change of Behaviour in Recurring: Schedules include only points in time. The Mask model handles ranges.

