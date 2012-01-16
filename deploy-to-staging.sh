git pull
git checkout staging
git merge origin/staging
git merge origin/master
git push
git checkout master
cap deploy staging
