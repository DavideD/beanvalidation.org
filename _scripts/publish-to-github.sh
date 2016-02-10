#! /bin/bash
# Make sure the staging branch is in sync with its remote
git reset --hard origin/production

git clean -fdx

# Remove all generated files and directories
rake clean[all]

# build site in prod profile
rake --trace  gen[production]

rc=$?
if [[ $rc != 0 ]] ; then
    echo "ERROR: Execution of Rake script failed."
    exit $rc
fi

# clone hibernate.github.io in _tmp if not present
cd _tmp
if [ ! -d "beanvalidation.github.io" ];
then
  git clone --depth 1 git@github.com:beanvalidation/beanvalidation.github.io.git
fi

cd beanvalidation.github.io
git fetch origin
git reset --hard origin/master
git rm -r .

# copy site to git repo, commit and push
# we filter cache as in production we shouldn't need that data
rsync -av \
      --delete \
      --filter "- /cache" --filter "- .git" \
      ../../_site/ .

git add .
if git commit -m "Publish generated site";
then
  git push origin master;
fi

cd ../..
