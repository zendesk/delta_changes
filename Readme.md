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

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/delta_changes.png)](https://travis-ci.org/grosser/delta_changes)
