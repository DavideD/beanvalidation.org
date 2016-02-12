#! /bin/bash
# Make sure the staging branch is in sync with its remote
git reset --hard origin/production

git clean -fdx

# Remove all generated files and directories
rake clean[all]

rake setup

# build site in prod profile
rake --trace  gen[production]

rc=$?
if [[ $rc != 0 ]] ; then
    echo "ERROR: Rake script failed!"
    exit $rc
fi

pushd _tmp
# clone beanvalidation-spec in _tmp if not present
if [ ! -d "beanvalidation-spec" ];
then
  git clone --depth 1 git@github.com:beanvalidation/beanvalidation-spec.git
fi
cd beanvalidation-spec 
git fetch origin
git reset --hard origin/master

ant all.doc
rc=$?
if [[ $rc != 0 ]] ; then
    echo "ERROR: Specification build failed!"
    exit $rc
fi


# Synchronize the content with the latest-draft folder of the site
rsync -av --delete --exclude ".git" build/en/html_single/ ../../_site/latest-draft/spec/ 
rc=$?
popd
if [[ $rc != 0 ]] ; then
    echo "ERROR: Latest-draft sync failed!"
    exit $rc
fi

pushd _tmp
# clone hibernate.github.io in _tmp if not present
if [ ! -d "beanvalidation.github.io" ];
then
  git clone --depth 1 git@github.com:beanvalidation/beanvalidation.github.io.git
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo "ERROR: beanvalidation/beanvalidation.github.io cannot be cloned!"
    exit $rc
  fi
fi

cd beanvalidation.github.io
git fetch origin
git reset --hard origin/master

# copy site to git repo, commit and push
# we filter cache as in production we shouldn't need that data
rsync -av \
      --delete \
      --filter "- /cache" --filter "- .git" \
      ../../_site/ .

rc=$?
if [[ $rc != 0 ]] ; then
    echo "ERROR: Site sync failed!"
    exit $rc
fi

git add -A .
if git commit -m "Publish generated site";
then
 git push origin master;
 rc=$?
fi
popd
if [[ $rc != 0 ]] ; then
  echo "ERROR: Cannot push on site repository!"
  exit $rc
fi

