riak-tests
==========

Utilities to test Riak

Be sure `allow_mult` is `true`:

```
 %% Riak Core config
 {riak_core, [
              {default_bucket_props, [{allow_mult, true}]},
```

Any non `20X` response will be logged:

```
2014-07-21 14:02:47:[error]:object_checker:-XGET localhost:10028/buckets/bucket-0/keys/478:300:0
```

