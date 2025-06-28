# good-audible-story-sync

Script to sync your read books from Audible to Goodreads and StoryGraph.

## How to use

> [!NOTE]
> This is intended to be run from macOS.

Download the [latest release](https://github.com/cheshire137/good-audible-story-sync/releases/latest) of the gem. Install it via:

```sh
gem install good-audible-story-sync.gem
```

There should now be a `good-audible-story-sync` executable in your path. Run it via:

```sh
good-audible-story-sync
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
Usage: good-audible-story-sync [options]
    -d DATABASE_FILE,                Path to Sqlite database file. Defaults to good_audible_story_sync.db.
        --database-file
    -e EXPIRATION_DAYS,              Max number of days to use cached data, such as Audible library, before refreshing. Defaults to 1.
        --expiration-days
```

### Sample output

```sh
% good-audible-story-sync
🔐 Looking for 'good_audible_story_sync_encryption_key' in cheshire137's keychain...
ℹ️ Using GoodAudibleStorySync encryption key from keychain
⚙️ Parsing options...
ℹ️ Ensuring table audible_books exists...
ℹ️ Ensuring table storygraph_books exists...
ℹ️ Ensuring table goodreads_books exists...
ℹ️ Ensuring table credentials exists...
ℹ️ Ensuring table sync_times exists...
a) display Audible library
p) display Audible user profile
g) display Goodreads library
s) display Storygraph library
l) look up book on Storygraph
c) update Storygraph library cache
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

You can also run `irb` to get an interactive Ruby console with some convenient methods available for debugging, including:

- #load_db_client
- #load_options
- #get_audible_auth
- #get_audible_client
- #get_audible_library
- #get_storygraph_auth
- #get_storygraph_client
- #get_goodreads_auth
- #get_goodreads_client

### Creating a tag

Update `VERSION` in [version.rb](./lib/good_audible_story_sync/version.rb).

```sh
git tag v0.0.x main # use the same version string as in `VERSION`
git push origin tag v0.0.x
```

This will trigger a workflow that builds the gem and creates a new release.

### Building the gem

```sh
gem build good_audible_story_sync.gemspec
```

This will create a file like project_pull_mover-0.0.1.gem which you can then install:

```sh
gem install good_audible_story_sync-0.0.1.gem
```

## Thanks

- [mkb79's Python Audible library](https://github.com/mkb79/Audible) for providing an example of how to authenticate with Audible and use its API, including the [unofficial API docs](https://audible.readthedocs.io/en/master/misc/external_api.html).
- [mechanize gem](https://github.com/sparklemotion/mechanize) for letting me automate Storygraph and Goodreads even without an API.
