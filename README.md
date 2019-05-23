# mrt-tind-harvester

[![Build Status](https://travis-ci.org/CDLUC3/mrt-tind-harvester.svg?branch=master)](https://travis-ci.org/CDLUC3/mrt-tind-harvester)

Utility for harvesting OAI-PMH records from the UC Berkeley library’s
[TIND DA](http://info.tind.io/da) installation to identify full-res TIFF
files for ingest into Merritt. 

## Configuration

Each feed to be harvested requires a YAML configuration file, e.g.

```yaml
stage:
  oai:
    base_url: https://berkeley.tind.io/oai2d
    set: calher130
  merritt:
    collection_ark: ark:/13030/m5vd6wc7
    database: ../database.yml
    ingest_url: http://merritt-stage.cdlib.org:33121/poster/submit/
    ingest_profile: ucb_lib_content
  last_harvest: last-harvest-stage.yml
  stop_file: stop-stage.txt
  log:
    file: stage.log
    # level: debug   # debug is the default level

production:
  oai:
    base_url: https://berkeley.tind.io/oai2d
    set: calher130
  merritt:
    collection_ark: ark:/13030/m5ww7fsr
    database: ../database.yml
    ingest_url: http://merritt.cdlib.org:33121/poster/submit/
    ingest_profile: ucb_lib_cal_heritage
  last_harvest: last-harvest-production.yml
  stop_file: stop-production.txt
  log:
    file: production.log
    level: info
``` 

The file above configures a harvest of the `calher130` feed into both
stage and production environments, using, for stage, the
`ark:/13030/m5vd6wc7` collection and `ucb_lib_content` ingest profile, and
for production, the `ark:/13030/m5ww7fsr` collection and
`ucb_lib_cal_heritage` ingest profile. 

In addition, the configuration above sets the log file and log level for
each environment, the location of the (shared) database configuration file,
and the location of two special files, `last_harvest` and `stop_file`.
Paths specified in the configuration file may be either relative or
absolute; if relative (as in the example above) they are resolved relative
to the configuration file itself.

Note that the environment may be configured as either `$HARVESTER_ENV`,
`$RAILS_ENV`, or `$RACK_ENV`, preferred in that order.

### Database configuration

The harvester assumes a standard MySQL `database.yml` file, as used by
Rails. (For a minimal example, see
[`.config-travis/database.yml`](.config-travis/database.yml).)

### Special files

#### Last harvest

The `last_harvest` file records the result of the most recent harvest, and
is used to determine the start point of the next harvest. By default, the
harvester will not send a stop or start time to the OAI-PMH server, and will
harvest all records. Given a last harvest file, however, the harvester will
prefer, in order:

1. The datestamp of the earliest failure, i.e. the earliest record that could not
   be submitted to Merritt
2. The datestamp of the latest success, i.e. the latest record that was
   submitted to Merritt

(Note that this means subsequent harvests will always overlap at least
slightly with previous harvests.)

Either of these can be overridden by passing an explicit start time to the
harvester.

**⚠️ Note:** As the Merritt ingest process is asynchronous, objects can appear
to submit successfully, and then fail later, e.g. in the event Merritt is 
unable to retrieve content from the URL specified in the feed. If this happens
relatively rarely, we can deal with it by pausing the associated `cron` job
and manually re-harvesting from that timestamp. If it becomes more common, 
we may need to do something fancier.

#### Stop file

If the `stop_file` is present, the harvester will exit without accessing the
OAI-PMH feed or ingesting any objects. This can be used to temporarily pause
the harvesting of a particular feed without modifying any `cron` jobs.

(Note that this is distinct from the `--dry-run` flag described below, which
will harvest the OAI-PMH feed but will not submit the harvested objects.)

## Usage

### Command line

The harvester can be invoked from the command line with the 
[`mrt-tind-harvester`](bin/mrt-tind-harvester) script:

```
$ bin/mrt-tind-harvester -h
Usage: mrt-tind-harvester [options]
    -c, --config=CONFIG              path to configuration file (required)
    -f, --from DATETIME              start date/time (inclusive) for selective harvesting
    -u, --until DATETIME             end date/time (inclusive) for selective harvesting
    -n, --dry-run                    dry run (harvest, but do not submit or update last_harvest)
    -h, --help                       print help and exit
```

For example, a basic invocation, suitable for automated harvesting:

```
$ mrt-tind-harvester -c calher130/config.yml
```

Or to harvest from a specific date/time to the present:

```
$ mrt-tind-harvester -c calher130/config.yml -f 2019-04-23T13:45:23Z
```

Or to harvest a date/time range, specifying both start and end datestamps:

```
$ mrt-tind-harvester -c calher130/config.yml \
  -f 2019-04-23T13:45:23Z \
  -u 2019-05-02T17:17:52Z
```

Or to test a configuration:

```
$ mrt-tind-harvester -c calher130/config.yml -n
```

#### Flags

| Short form | Flag               | Description                                                 |
| ---        | ---                | ---                                                         |
| `-c`       | `--config CONFIG`  | path to configuration file (required)                       |
| `-f`       | `--from DATETIME`  | start date/time (inclusive) for selective harvesting        |
| `-u`       | `--until DATETIME` | end date/time (inclusive) for selective harvesting          |
| `-n`       | `--dry-run`        | dry run (harvest, but do not submit or update last_harvest) |
| `-h`       | `--help`           | print help and exit                                         |

(Dates/times can be in any format suitable for Ruby's
[`Time.parse`](https://ruby-doc.org/stdlib-2.4.4/libdoc/time/rdoc/Time.html#method-c-parse),
and will be converted to UTC time / ISO 8601 format when retrieving the OAI-PMH feed.)

### Ruby gem

The harvester can also be used as a Ruby gem by adding the following to a `Gemfile`:

```ruby
gem 'mrt-tind-harvester', '~> 0.0.1'
```

A basic invocation, suitable for automated harvesting:

```ruby
require 'merritt/tind'

harvester = Merritt::TIND::Harvester.from_file('calher130/config.yml')
harvester.process_feed!
```

Or to harvest from a specific date/time to the present:

```ruby
require 'merritt/tind'

harvester = Merritt::TIND::Harvester.from_file('calher130/config.yml')
harvester.process_feed!(from_time: Time.utc(2019, 4, 23, 13, 45, 23))
```

Or to harvest a date/time range, specifying both start and end datestamps:

```ruby
require 'merritt/tind'

harvester = Merritt::TIND::Harvester.from_file('calher130/config.yml')
harvester.process_feed!(
  from_time: Time.utc(2019, 4, 23, 13, 45, 23), 
  until_time: Time.utc(2019,5,2,17,17,52)
)
```

Or to test a configuration:

```ruby
require 'merritt/tind'

harvester = Merritt::TIND::Harvester.from_file(
  'calher130/config.yml', dry_run: true
)
harvester.process_feed!
```

(Note that the `dry_run` flag is on the harvester itself, not on the
`process_feed!` method. This could probably be refactored, if we end up wanting to
call `process_feed!` many times on the same harvester instance.)


