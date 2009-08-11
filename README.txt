Recurring::Schedule
    by Chris Anderson
    http://recurring.rubyforge.org

== DESCRIPTION:
  
Recurring allows you to define Schedules, which can tell you whether or not a given Time falls in the Schedule, as well as being able to return a list of times which match the Schedule within a given range.

Schedules can be like:
* Every Tuesday at 5pm
* The 1st and 15th of every other month
* Every 2 hours
* The first Friday of every month at 11:15am and 4:45:15pm
  
= See more examples at Recurring::Schedule documentation
  
  # This Schedule will match every Tuesday at 5pm
    @rs = Recurring::Schedule.new :unit => 'weeks', :weekdays => 'tuesday', :times => '5pm'
    @rs.include?(Time.utc(2006,12,12,17)) #=> true
    @rs.include?(Time.utc(2006,12,13,17)) #=> false
  
= Features
  * Fast searching of long ranges for matching times.
  * Ability to define Schedules in a few flexible ways.
  * Extensive RSpec specifications (run "rake spec" to see them)
  * Extensive RSpec specifications (run "rake spec" to see them)

= Problems / Todo
  * Untested timezone support
  * Plans to offer complex Schedule and Masks

== REQUIREMENTS:

* RSpec >= 0.7.4 to run the specs.

== INSTALL:

* just run <tt>gem install recurring</tt>

== LICENSE:

(The MIT License)

Copyright (c) 2006 Chris Anderson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
