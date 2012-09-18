Additional real/virtual attribute change tracking independent of ActiveRecords

This a wrap up of some legacy code so it can be refactored/tested, not recommeneded for use yet :)

Install
=======

    gem install delta_changes

Usage
=====

    class User < ActiveRecord::Base
      include DeltaChanges::Extension
      delta_changes :columns => [:name], :attributes => [:full_name]
    end

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/delta_changes.png)](http://travis-ci.org/grosser/delta_changes)
