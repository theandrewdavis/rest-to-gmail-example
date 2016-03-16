An example web app to demonstrate sending emails from a GMail account. This [Sinatra](http://www.sinatrarb.com/) app accepts a POST request and uses the [gmail](https://github.com/gmailgem/gmail) gem to send an email with the provided subject and body.

This little app provided me an opportunity to explore unit testing and code coverage in Ruby using [minitest](https://github.com/seattlerb/minitest), [rack-test](https://github.com/brynary/rack-test), and [SimpleCov](https://github.com/colszowka/simplecov).

## Installation

Here's how you can install and run this app on Ubuntu 14.04. First, clone the repo.

    git clone https://github.com/theandrewdavis/rest-to-gmail-example.git

To be able to programmatically send emails from a single GMail account, we'll need to create OAuth credentials for that account. Google provides [quick runthrough docs](https://github.com/google/gmail-oauth2-tools/wiki/OAuth2DotPyRunThrough), which I'll follow below.

Log into [Google Developers Console](https://console.developers.google.com) and create a project. Choose "Enable and Manage APIs" and find the GMail API. Enable it, then go to the Credentials tab. In the Credentials wizard, choose GMail as the API, "Other UI" as the API type, and "User data" as the data to access. The wizard will direct you to create a OAuth 2.0 Client ID and set up the user consent screen. Then you can download a credentials file, `client_id.json`. Save this file in the `secret` subdirectory of the cloned repo.

Next, we'll need to authorize a GMail account to send emails programmatically. Find the client id and client secret in the downloaded `client_id.json` file and run the following.

    git clone https://github.com/google/gmail-oauth2-tools.git
    python gmail-oauth2-tools/python/oauth2.py --generate_oauth2_token --client_id=???.apps.googleusercontent.com --client_secret=???

This will direct you to a consent website and will provide a code to paste back into the CLI when done. This will give you a refresh token, which out web app can use to authenticate.

Now we'll configure the web app by giving it the refresh token and telling it where to send its emails. Copy `secret/config.json.example` to `secret/config.json` and fill out `secret/config.json` with the new refresh token, the 'from' email address that you just authenticated, and the 'to' email address where new emails will be sent.

Next, we need to build ruby 2.2 since Ubuntu 14.04 comes with 1.9 by default.

First install some dependencies:

    sudo apt-get install -y libssl-dev libreadline-dev zlib1g-dev    

Then follow the instructions from [gorails.com](https://gorails.com/setup/ubuntu/14.04):

    cd
    git clone git://github.com/sstephenson/rbenv.git .rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    exec $SHELL

    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
    exec $SHELL

    git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash

    rbenv install 2.2.3
    rbenv global 2.2.3
    ruby -v

You can run the app's tests with:

    gem install bundler
    bundle install
    bundle exec ruby test.rb


And finally, run the app on port 80 with:

    sudo bundle exec ruby server.rb -p 80
