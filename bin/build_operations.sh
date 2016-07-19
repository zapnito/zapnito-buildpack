install_node() {
  # Look in package.json's engines.node field for a semver range
  local semver_range=$($bp_dir/vendor/jq -r .engines.node $build_dir/package.json)

  # Resolve node version using semver.io
  local node_version=$(curl --silent --get --data-urlencode "range=${semver_range}" https://semver.io/node/resolve)

  info "Detected node version: $node_version"

  # Download node from Heroku's S3 mirror of nodejs.org/dist
  head "Downloading and installing node"
  node_url="http://s3pository.heroku.com/node/v${node_version}/node-v${node_version}-linux-x64.tar.gz"
  curl $node_url -s -o - | tar xzf - -C $build_dir

  # Move node (and npm) into ./vendor and make them executable
  mkdir -p $build_dir/vendor
  mv $build_dir/node-v$node_version-linux-x64 $build_dir/vendor/node
  chmod +x $build_dir/vendor/node/bin/*
  PATH=$build_dir/vendor/node/bin:$PATH
}

restore_node_modules() {
  if test -d $cache_dir/node_modules; then
    info "Restoring node modules"
    cp -r $cache_dir/node_modules $build_dir/node_modules
    info "Pruning stale node modules"
    npm prune # clear out unused packages/versions
  fi
}

prepare_cache() {
  mkdir -p $cache_dir
}

cache_node_modules() {
  if test -d $build_dir/node_modules; then
    info "Caching node modules"
    cp -r $build_dir/node_modules $cache_dir/node_modules
  fi
}

setup_node_modules() {
  head "Setting up node_modules"
  # restore_node_modules
  info "Installing node components"
  npm install
  # cache_node_modules
}

setup_bower_components() {
  head "Setting up bower components"
  # Install bower
  info "Installing bower"
  npm install -g bower

  # Install bower components
  info "Installing bower components"
  bower install | indent
}

build_zapnito_web() {
  head "Building zapnito-web"
  build_env=${EMBER_ENV:-production}
  $build_dir/node_modules/ember-cli/bin/ember build --environment $build_env | indent
}

deploy_zapnito_web() {
  # Deploy ember cli application
  head "Deploying zapnito-web"
  $build_dir/node_modules/ember-cli/bin/ember deploy production | indent
  cp ./ember-cli-deploy-revision "$env_dir/ZAPNITO_WEB_REVISION"
  echo "ZAPNITO_WEB_REVISION=$(cat ember-cli-deploy-revision)" >> ../.env
  echo "dotenv config"
  cat ../.env
}

cleanup() {
  # Cleanup
  info "Clearing zapnito-web from slug"
  cd
  rm -rf $build_dir
}
