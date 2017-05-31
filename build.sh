#!/bin/sh
PLUGINS=plugins
REGISTRY=$(oc get svc/docker-registry -n default -o yaml | grep clusterIP: | awk '{print $2}')

if [ ! -d $PLUGINS ]; then
  echo "Creatig plugins directory"
  mkdir $PLUGINS
fi

pushd $PLUGINS
echo "Downloading plugins..."
curl -sLO https://sonarsource.bintray.com/Distribution/sonar-ldap-plugin/sonar-ldap-plugin-2.1.0.507.jar
popd

docker build -t default/sonar . ||exit 1
docker tag default/sonar ${REGISTRY}:5000/default/sonar:latest
echo "Tagging image to docker registry..."
docker info |grep Username
if [ $? -ne 0 ]; then
  echo "Logging in..."
  docker login -u docker -p $(oc whoami -t) http://${REGISTRY}:5000 || exit 1
fi

echo "Pushing image to docker registry..."
docker push ${REGISTRY}:5000/default/sonar:latest
if [ $? -ne 0 ]; then
  echo "Not logged. Try to catch token:"
  echo "oc whoami -t"
  echo "Login on Docker"
  echo "docker login -u docker -p <token> http://${REGISTRY}:5000"
  exit 1
fi

echo "Verify persistent volume at OpenShift"
oc get pv sonar 2> /dev/null
if [ $? -ne 0 ]; then
  oc create -f sonar-pv.yaml
fi
