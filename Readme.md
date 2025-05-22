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
=======

To run tests: `$ rake spec`

To run tests with a specific Rails version listed in `./gemfiles`, e.g. Rails 7.0:
```
$ BUNDLE_GEMFILE=gemfiles/rails7.0.gemfile rake spec
```

### Releasing a new version
A new version is published to RubyGems.org every time a change to `version.rb` is pushed to the `main` branch.
In short, follow these steps:
1. Update `version.rb`,
2. update version in all `Gemfile.lock` files,
3. merge this change into `main`, and
4. look at [the action](https://github.com/zendesk/delta_changes/actions/workflows/publish.yml) for output.

To create a pre-release from a non-main branch:
1. change the version in `version.rb` to something like `1.2.0.pre.1` or `2.0.0.beta.2`,
2. push this change to your branch,
3. go to [Actions → “Publish to RubyGems.org” on GitHub](https://github.com/zendesk/delta_changes/actions/workflows/publish.yml),
4. click the “Run workflow” button,
5. pick your branch from a dropdown.

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://github.com/zendesk/delta_changes/workflows/spec/badge.svg)](https://github.com/zendesk/delta_changes/actions)
