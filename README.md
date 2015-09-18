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

Calculate similarities for all the linkages in a category in a batch. New calculations will need to
be performed if new linkages are added.

```ruby
HarmonizerRedis.calculate_similarities(my_category_id)
```

To get an Array of similar phrases. The default is to return the top 20 phrases. If new linkages have
been added or if the similarities have not yet been computed for this linkage, it will be computed
automatically with this call.

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

## Contributing

Feel free to fork this repo and change it as you wish. We prefer pull requests on github, but you can send us emails. All attributions need to be tested as well.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

