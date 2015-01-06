Heroku buildpack for Ember CLI applications
===========================================

This buildpack works with Ember CLI generated applications. It installs Bower packages and generates a production build with Ember CLI. However, unlike [tonycoco/heroku-buildpack-ember-cli](https://github.com/tonycoco/heroku-buildpack-ember-cli) it does not provide any web server to serve your app. You should provide your own Node.js web server.

This buildpack is supposed to be run after the default [Heroku Node.js  buildpack](https://github.com/heroku/heroku-buildpack-nodejs) using Heroku [multi buildpack](https://github.com/heroku/heroku-buildpack-multi) that allows one to run multiple buildpacks in a single deploy process.

## Usage
For new apps:
```
$ heroku create --buildpack https://github.com/heroku/heroku-buildpack-multi.git
```
For existing apps:
```
$ heroku config:add BUILDPACK_URL=https://github.com/heroku/heroku-buildpack-multi.git
```
From here you will need to create a `.buildpacks` file which contains (in order) the Node.js and Ember CLI buildpacks:
```
$ cat .buildpacks
https://github.com/heroku/heroku-buildpack-nodejs.git
https://github.com/szimek/heroku-buildpack-ember-cli-without-webserver.git
```

Now run:
```
$ heroku config:set NPM_CONFIG_PRODUCTION=false
```
This will cause Node.js buildpack to install development dependencies as well, which are needed by Ember CLI buildpack to build your app.

## How it works

Node.js buildpack will install Node.js and npm and then install all Node.js packages (including those specified as development dependencies). Ember CLI buildpack will then install Bower packages and run 
```
ember build --environment=$EMBER_ENV
```
(by default `EMBER_ENV=production`) to generate your app.
