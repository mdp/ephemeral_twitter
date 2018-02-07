# Ephemeral Twitter

This was cribbed from [Robin Sloan's "Twitter Delete script"](https://gist.github.com/robinsloan/3688616), and then turned into a docker file for my own personal use.

## Installation

1. `git clone <this>`
1. `cd ephemeral_twtter`
1. `cp config.sample.yml config.yml`
1. Update config.yml with your own values
1. `docker run -it --rm -v $(pwd)/config.yml:/usr/src/app/config.yml mpercival/ephemeral_twitter`

