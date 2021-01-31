aarone.org
===

Source for [aarone.org](http://www.aarone.org).  Fairly
basic site built with [Jekyll](http://jekyllrb.com/).


Setup
===

1. Install [Acorn](https://flyingmeat.com/acorn/)
2. Install rbenv and a new Ruby, make it your global ruby
3. Install [Jekyll](https://jekyllrb.com/docs/installation/macos/)
4. Be aaron with a local AWS profile named `aarone.org` that can do S3 stuff
5. `rake build` to build the site
6. `bundle exec jekyll serve` to run locally
7. `rake publish` to prepare images and upload everything to S3