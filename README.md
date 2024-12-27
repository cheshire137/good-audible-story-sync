# good-audible-story-sync

Script to sync your read books from Audible to Goodreads and StoryGraph.

## How to use

This is intended to be run from macOS.

```sh
bin/good-audible-story-sync
```

You will be prompted to log in to Audible and Storygraph. The tool saves your encrypted login
credentials in a SQLite database and stores the encryption key in the macOS keychain, under the name
'good_audible_story_sync_encryption_key'.

After signing into Audible, it will create a new device that you can see on your Amazon
[Installed on Devices](https://www.amazon.com/hz/mycd/digital-console/devicedetails?deviceFamily=AUDIBLE_APP)
page for Audible. This allows accessing your Audible library information, such as which books
you finished reading and when.

### Options

```sh
Usage: bin/good-audible-story-sync [options]
    -d DATABASE_FILE,                Path to Sqlite database file. Defaults to good_audible_story_sync.db.
        --database-file
    -e EXPIRATION_DAYS,              Max number of days to use cached data, such as Audible library, before refreshing. Defaults to 1.
        --expiration-days
```

### Sample output

```sh
% bin/good-audible-story-sync
🔐 Looking for 'good_audible_story_sync_encryption_key' in cheshire137's keychain...
ℹ️ Using GoodAudibleStorySync encryption key from keychain
⚙️ Parsing options...
ℹ️ Ensuring table audible_books exists...
ℹ️ Ensuring table storygraph_books exists...
ℹ️ Ensuring table credentials exists...
ℹ️ Ensuring table sync_times exists...
a) display Audible library
u) display Audible user profile
s) display Storygraph library
f) mark finished books on Storygraph
q) quit
Choose an option:
```

## How to develop

Built using Ruby version 3.3.6 on macOS.

```sh
bundle install
bin/good-audible-story-sync
```

Run `srb tc` to run the [Sorbet type checker](https://sorbet.org/).

## Thanks

Thank you to [mkb79's Python Audible library](https://github.com/mkb79/Audible) for providing an example of how to authenticate with Audible and use its API, including the [unofficial API docs](https://audible.readthedocs.io/en/master/misc/external_api.html).
