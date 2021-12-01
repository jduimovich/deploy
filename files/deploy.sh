
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CONTAINER=$1 
if [ -z "$CONTAINER" ]
then
      echo Missing CONTAINER Image URL to Run
      exit -1 
fi
IMAGE=$(basename $CONTAINER)
# route is just the base image name
ROUTE=$(echo $IMAGE | cut -d ':' -f 1)

echo running image $IMAGE at $ROUTE  

APP=$ROUTE-app
 
yq -M e ".metadata.name=\"$ROUTE-deployment\"" $SCRIPTDIR/deployment.yaml  | \
 yq -M e ".spec.selector.matchLabels.app=\"$APP\"" - |  \
 yq -M e ".spec.template.metadata.labels.app=\"$APP\"" - |  \
 yq -M e ".spec.template.spec.containers[0].image=\"$CONTAINER\"" -  | \
 oc apply -f -
 
yq -M e ".metadata.name=\"$ROUTE-service\"" $SCRIPTDIR/service.yaml  | \
 yq -M e ".spec.selector.app=\"$APP\"" -  |  \
 oc apply -f - 
 
yq -M e ".metadata.name=\"$ROUTE\"" $SCRIPTDIR/route.yaml  | \
 yq -M e ".spec.to.name=\"$ROUTE-service\"" - |  \
 oc apply -f -

RT=$( oc get route $ROUTE  -o yaml | yq e '.spec.host' -)
echo "Find your app at https://$RT"