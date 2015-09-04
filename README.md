# HarmonizerRedis

HarmonizerRedis is a Ruby gem that aids the process of relabeling/grouping free text phrases to
resolve the many ways people spell or describe something. It uses fuzzy string matching along with inverse
term frequencies to score and rank similarities between phrases. The gem uses Redis for performance.

## Usage

### Configuration

The Redis must be configured first. Refer to the [Redis] (https://github.com/redis/redis-rb) for more information.
`Redis.current` should be set to the Redis connection.

```ruby
Redis.current = Redis.new
```

### Adding an entry

`HarmonizerRedis::Linkage` represents the connection between your data structures and the gem. Linkages contain
string content, an `id` (which will be a uniquely generated uuid), and a `category_id` which identifies the collection this entry belongs to.

```ruby
my_category_id = 100
linkage = HarmonizerRedis::Linkage.new(content: 'harmonizer redis',
                                       category_id: my_category_id)
linkage.save
my_linkage_id = linkage.id # "520c488b-e9f8-4a6f-aaea-0d5e37b97644"
```

### Retrieving an entry

```ruby
my_linkage = HarmonizerRedis::Linkage.find(my_linkage_id)
```

### Calculating and Retrieving Similarities

First a call to calculate similarities needs to be made before displaying the scores for any linkages in the category

```ruby
HarmonizerRedis.calculate_similarities(my_category_id)
```

To calculate similarities for a specific linkage (this means you can only get similar phrases for this specific linkage)

```ruby
my_linkage.calculate_similarities
```

To get an Array of similar phrases. The default is to return the top 20 phrases.

```ruby
my_linkage.get_similarities
```

### Merging into groups, labeling groups, and getting recommended labels

Each entry in this array is an array in the following format `[text_label, group_label, similarity_score, phrase_id]`

After deciding which phrase the linkage should be combined with - use the accompanying phrase_id data to merge the phrases into a group

```ruby
my_linkage.merge_with_phrase(phrase_id)
```

To label everything in the same group:

```ruby
my_linkage.set_corrected_label('HarmonizerRedis')
```

To suggest labels for this group (this works better the more HarmonizerRedis is used)

```ruby
my_linkage.recommend_labels
```

Lastly to get the final corrected label of a linkage:

```ruby
my_linkage.corrected
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

