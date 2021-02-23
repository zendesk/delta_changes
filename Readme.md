Additional real/virtual attribute change tracking independent of ActiveRecords


Install
=======

```Bash
gem install delta_changes
```

Usage
=====

```Ruby
class User < ActiveRecord::Base
  include DeltaChanges::Extension
  delta_changes columns: [:name], attributes: [:full_name]
end

user.name = "bar"
user.delta_changes # => {"name" => [nil, "bar"]}

user.full_name_will_change!
user.delta_changes # => {"name" => [nil, "bar"], "full_name" => [nil, "Mr. Bar"]}

user.save!
user.delta_changes # => {"name" => [nil, "bar"], "full_name" => [nil, "Mr. Bar"]}

user.reset_delta_changes!
user.delta_changes # => {}
```

Testing
======

To run tests: `$ rake spec`

To run tests with a specific Rails version listed in `./gemfiles`, e.g. Rails 5.0:
```
$ BUNDLE_GEMFILE=gemfiles/rails5.0.gemfile rake spec`
```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://github.com/zendesk/delta_changes/workflows/spec/badge.svg)](https://github.com/zendesk/delta_changes/actions)
