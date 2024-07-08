RESOURCE_GROUP="frontend-cop-demo"
LOCATION="uksouth"
WEBAPP_LOCATION="westeurope"
WEBAPP_NAME="frontend-cop-demo-swa"

echo "Checking if resource group $RESOURCE_GROUP exists"
if [ $(az group exists -n $RESOURCE_GROUP) = false ]; then
    echo "Creating resource group $RESOURCE_GROUP"
    az group create -n $RESOURCE_GROUP -l $LOCATION
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

echo "Creating static web app in resource group $RESOURCE_GROUP"
az staticwebapp create -n $WEBAPP_NAME -g $RESOURCE_GROUP -s https://github.com/MirrorSquire/azure-static-site-hosting-talk.git -l $WEBAPP_LOCATION -b main --login-with-github --output-location ./dist